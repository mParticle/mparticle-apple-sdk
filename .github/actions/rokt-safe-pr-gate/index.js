const fs = require("node:fs");
const {
  classifyFiles,
  evaluateWorkflows,
  getOpenPullRequestNumber,
  getPaginatedItems,
  getPullRequestNumber,
  hasFreshApproval,
  validatePolicy,
} = require("./lib/gate");

let activeGate = null;

function getInput(name) {
  return (
    process.env[`INPUT_${name.replace(/-/g, "_").toUpperCase()}`]?.trim() || ""
  );
}

function requiredInput(name) {
  const value = getInput(name);

  if (!value) {
    throw new Error(`Missing required input: ${name}`);
  }

  return value;
}

function toQueryPath(path, query) {
  const url = new URL(path, "https://github.invalid");

  for (const [key, value] of Object.entries(query)) {
    url.searchParams.set(key, value);
  }

  return `${url.pathname}${url.search}`;
}

function nextPage(linkHeader) {
  if (!linkHeader) {
    return null;
  }

  const match = linkHeader.match(/<([^>]+)>; rel="next"/);
  return match?.[1] || null;
}

function createApi(apiUrl, token) {
  async function request(path, options = {}) {
    const response = await fetch(new URL(path, apiUrl), {
      method: options.method || "GET",
      headers: {
        Accept: "application/vnd.github+json",
        Authorization: `Bearer ${token}`,
        "X-GitHub-Api-Version": "2026-03-10",
        ...(options.body ? { "Content-Type": "application/json" } : {}),
      },
      body: options.body ? JSON.stringify(options.body) : undefined,
    });

    const data = response.status === 204 ? null : await response.json();

    if (
      !response.ok &&
      !(options.allowStatuses || []).includes(response.status)
    ) {
      throw new Error(
        `GitHub API request failed with status ${response.status}.`,
      );
    }

    return { data, headers: response.headers, status: response.status };
  }

  async function paginate(path, collectionKey) {
    const results = [];
    let next = path;

    while (next) {
      const response = await request(next);

      results.push(...getPaginatedItems(response.data, collectionKey));
      next = nextPage(response.headers.get("link"));
    }

    return results;
  }

  return { paginate, request };
}

async function getGateCheck(api, owner, repository, sha, gateAppId, checkName) {
  const path = toQueryPath(
    `/repos/${owner}/${repository}/commits/${sha}/check-runs`,
    { check_name: checkName, per_page: "100" },
  );
  const checks = await api.paginate(path, "check_runs");

  return checks.find((check) => String(check.app?.id) === gateAppId) || null;
}

async function upsertGateCheck(api, details, state) {
  const check = await getGateCheck(
    api,
    details.owner,
    details.repository,
    details.sha,
    details.gateAppId,
    details.checkName,
  );
  const body = {
    name: details.checkName,
    status: state.status,
    output: {
      title: "Rokt Safe PR Gate",
      summary: state.summary,
    },
  };

  if (state.status === "completed") {
    body.conclusion = state.conclusion;
    body.completed_at = new Date().toISOString();
  }

  if (check) {
    await api.request(
      `/repos/${details.owner}/${details.repository}/check-runs/${check.id}`,
      {
        method: "PATCH",
        body,
      },
    );
    return;
  }

  await api.request(
    `/repos/${details.owner}/${details.repository}/check-runs`,
    {
      method: "POST",
      body: {
        ...body,
        head_sha: details.sha,
        external_id: `rokt-safe-pr-gate:${details.prNumber}:${details.sha}`,
      },
    },
  );
}

async function completeGate(api, details, conclusion, summary) {
  await upsertGateCheck(api, details, {
    conclusion,
    status: "completed",
    summary,
  });
}

async function isEmployee(roktApi, organization, teamSlug, login) {
  const path = `/orgs/${organization}/teams/${encodeURIComponent(teamSlug)}/memberships/${encodeURIComponent(login)}`;
  const response = await roktApi.request(path, { allowStatuses: [404] });

  return response.status === 200 && response.data?.state === "active";
}

async function main() {
  const apiUrl = requiredInput("api-url");
  const policy = validatePolicy(
    JSON.parse(fs.readFileSync(requiredInput("policy-path"), "utf8")),
  );
  const event = JSON.parse(
    fs.readFileSync(requiredInput("event-path"), "utf8"),
  );

  const owner = event.repository?.owner?.login;
  const repository = event.repository?.name;

  if (!owner || !repository) {
    throw new Error("Event does not identify a repository.");
  }

  const mparticleApi = createApi(apiUrl, requiredInput("mparticle-token"));
  const roktApi = createApi(apiUrl, requiredInput("rokt-token"));
  let prNumber = getPullRequestNumber(event);

  if (!prNumber && event.workflow_run?.head_sha) {
    const pullRequests = await mparticleApi.paginate(
      toQueryPath(
        `/repos/${owner}/${repository}/commits/${event.workflow_run.head_sha}/pulls`,
        { per_page: "100" },
      ),
    );
    prNumber = getOpenPullRequestNumber(pullRequests);
  }

  if (!prNumber) {
    console.log("No open pull request is associated with this event.");
    return;
  }

  const pr = (
    await mparticleApi.request(
      `/repos/${owner}/${repository}/pulls/${prNumber}`,
    )
  ).data;

  if (pr.state !== "open") {
    console.log("Pull request is not open.");
    return;
  }

  const details = {
    checkName: policy.gateCheckName,
    gateAppId: requiredInput("gate-app-id"),
    owner,
    prNumber,
    repository,
    sha: pr.head.sha,
  };

  activeGate = { api: mparticleApi, details };

  await upsertGateCheck(mparticleApi, details, {
    status: "in_progress",
    summary: "Evaluating the current pull request head SHA.",
  });

  if (pr.draft) {
    await completeGate(
      mparticleApi,
      details,
      "success",
      "Draft pull request; no automated approval was posted.",
    );
    return;
  }

  const [files, tree, workflowRuns] = await Promise.all([
    mparticleApi.paginate(
      toQueryPath(`/repos/${owner}/${repository}/pulls/${prNumber}/files`, {
        per_page: "100",
      }),
    ),
    mparticleApi.request(
      `/repos/${owner}/${repository}/git/trees/${pr.head.sha}?recursive=1`,
    ),
    mparticleApi.paginate(
      toQueryPath(`/repos/${owner}/${repository}/actions/runs`, {
        event: "pull_request",
        head_sha: pr.head.sha,
        per_page: "100",
      }),
      "workflow_runs",
    ),
  ]);

  if (tree.data.truncated) {
    await completeGate(
      mparticleApi,
      details,
      "failure",
      "Unable to safely inspect the full file tree.",
    );
    return;
  }

  const workflowState = evaluateWorkflows(
    workflowRuns,
    policy.requiredWorkflows,
  );

  if (workflowState.state === "pending") {
    console.log("Waiting for required workflow completion.");
    return;
  }

  if (workflowState.state === "failed") {
    await completeGate(
      mparticleApi,
      details,
      "failure",
      "A required workflow did not succeed.",
    );
    return;
  }

  const fileState = classifyFiles(files, tree.data.tree, policy);

  if (!fileState.eligible) {
    await completeGate(
      mparticleApi,
      details,
      "success",
      "Manual code owner approval is required for this pull request.",
    );
    return;
  }

  const reviewerLogin = requiredInput("gate-reviewer-login");

  if (pr.user.login.toLowerCase() === reviewerLogin.toLowerCase()) {
    await completeGate(
      mparticleApi,
      details,
      "failure",
      "The gate reviewer cannot approve its own pull request.",
    );
    return;
  }

  const employee = await isEmployee(
    roktApi,
    policy.roktOrganization,
    requiredInput("employee-team-slug"),
    pr.user.login,
  );

  if (!employee) {
    await completeGate(
      mparticleApi,
      details,
      "success",
      "Manual code owner approval is required for this pull request.",
    );
    return;
  }

  const reviews = await mparticleApi.paginate(
    toQueryPath(`/repos/${owner}/${repository}/pulls/${prNumber}/reviews`, {
      per_page: "100",
    }),
  );

  if (!hasFreshApproval(reviews, reviewerLogin, pr.head.sha)) {
    const reviewerApi = createApi(apiUrl, requiredInput("reviewer-token"));

    await reviewerApi.request(
      `/repos/${owner}/${repository}/pulls/${prNumber}/reviews`,
      {
        method: "POST",
        body: {
          body: "Approved by the Rokt Safe PR Gate after the configured identity, diff, and CI checks passed.",
          commit_id: pr.head.sha,
          event: "APPROVE",
        },
      },
    );
  }

  await completeGate(
    mparticleApi,
    details,
    "success",
    "Eligible Rokt employee pull request approved for the current head SHA.",
  );
}

main().catch(async () => {
  if (activeGate) {
    try {
      await completeGate(
        activeGate.api,
        activeGate.details,
        "failure",
        "The Gate could not safely complete its evaluation.",
      );
    } catch {}
  }

  console.error("Rokt Safe PR Gate failed.");
  process.exitCode = 1;
});
