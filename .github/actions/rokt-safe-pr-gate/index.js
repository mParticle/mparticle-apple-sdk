const fs = require("node:fs");
const {
  classifyFiles,
  evaluateTeamReviewState,
  evaluateWorkflows,
  getEffectiveReviews,
  getIneligibleFileConclusion,
  getPaginatedItems,
  getPullRequestNumbers,
  hasSharedOpenHead,
  validatePolicy,
} = require("./lib/gate");

const SCHEDULE_MEMBERSHIP_LOOKUP_LIMIT = 50;
const SCHEDULE_PAGINATION_PAGE_LIMIT = 2;
const SCHEDULE_PULL_REQUEST_LIMIT = 10;

function getInput(name) {
  const normalizedName = name.toUpperCase();
  return (
    process.env[`INPUT_${normalizedName}`]?.trim() ||
    process.env[`INPUT_${normalizedName.replace(/-/g, "_")}`]?.trim() ||
    ""
  );
}

function requiredInput(name) {
  const value = getInput(name);

  if (!value) {
    throw new Error(`Missing required input: ${name}`);
  }

  return value;
}

function optionalPullRequestNumber() {
  const value = getInput("pr-number");

  if (!value) {
    return null;
  }

  if (!/^\d+$/.test(value) || Number(value) < 1) {
    throw new Error("pr-number must be a positive integer.");
  }

  return Number(value);
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

function createApi(
  apiUrl,
  token,
  { maxPages = Number.POSITIVE_INFINITY } = {},
) {
  async function request(path, options = {}) {
    const response = await fetch(new URL(path, apiUrl), {
      method: options.method || "GET",
      headers: {
        Accept: "application/vnd.github+json",
        Authorization: `Bearer ${token}`,
        "X-GitHub-Api-Version": "2022-11-28",
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

  async function paginate(
    path,
    collectionKey,
    { truncateAtLimit = false } = {},
  ) {
    const results = [];
    let next = path;
    let pageCount = 0;

    while (next) {
      if (pageCount >= maxPages) {
        if (truncateAtLimit) break;
        throw new Error("GitHub API pagination exceeded the evaluation limit.");
      }

      const response = await request(next);

      results.push(...getPaginatedItems(response.data, collectionKey));
      pageCount += 1;
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
  const checks = await api.paginate(path, "check_runs", {
    truncateAtLimit: true,
  });

  return (
    checks
      .filter((check) => String(check.app?.id) === gateAppId)
      .sort((left, right) => right.id - left.id)[0] || null
  );
}

function isCheckCompletedAfterEvaluation(check, evaluationStartedAt) {
  if (
    !evaluationStartedAt ||
    check.status !== "completed" ||
    !check.completed_at
  ) {
    return false;
  }

  const checkTime = Date.parse(check.completed_at);
  const evaluationTime = Date.parse(evaluationStartedAt);

  return (
    Number.isFinite(checkTime) &&
    Number.isFinite(evaluationTime) &&
    checkTime >= evaluationTime
  );
}

function gateCheckExternalId(details) {
  return `rokt-safe-pr-gate:${details.prNumber}:${details.sha}:${Date.parse(details.evaluationStartedAt)}:${details.evaluationId}`;
}

function ownsGateCheck(check, details) {
  return check.external_id === gateCheckExternalId(details);
}

function isCheckClaimedAfterEvaluation(check, evaluationStartedAt) {
  if (!evaluationStartedAt) return false;

  const match = check.external_id?.match(
    /^rokt-safe-pr-gate:\d+:[a-f0-9]{40}:(\d+):/,
  );
  const claimedAt = Number(match?.[1]);
  const evaluationTime = Date.parse(evaluationStartedAt);

  return (
    Number.isFinite(claimedAt) &&
    Number.isFinite(evaluationTime) &&
    claimedAt >= evaluationTime
  );
}

function gateCheckBody(details, state) {
  const body = {
    external_id: gateCheckExternalId(details),
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

  return body;
}

async function createGateCheck(api, details, state) {
  await api.request(
    `/repos/${details.owner}/${details.repository}/check-runs`,
    {
      method: "POST",
      body: {
        ...gateCheckBody(details, state),
        head_sha: details.sha,
      },
    },
  );
}

async function patchGateCheck(api, check, details, state) {
  await api.request(
    `/repos/${details.owner}/${details.repository}/check-runs/${check.id}`,
    {
      method: "PATCH",
      body: gateCheckBody(details, state),
    },
  );
}

async function claimCompletedGateCheck(api, check, details, summary) {
  await api.request(
    `/repos/${details.owner}/${details.repository}/check-runs/${check.id}`,
    {
      method: "PATCH",
      body: {
        external_id: gateCheckExternalId(details),
        name: details.checkName,
        output: { title: "Rokt Safe PR Gate", summary },
      },
    },
  );
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
  if (check) {
    if (state.status === "in_progress") {
      if (!ownsGateCheck(check, details)) {
        if (
          isCheckClaimedAfterEvaluation(check, details.evaluationStartedAt) ||
          isCheckCompletedAfterEvaluation(check, details.evaluationStartedAt)
        ) {
          return;
        }

        if (check.status === "completed") {
          await claimCompletedGateCheck(api, check, details, state.summary);
          return;
        }

        await patchGateCheck(api, check, details, state);
        return;
      }

      if (check.status !== "completed") {
        await patchGateCheck(api, check, details, state);
      }
      return;
    }

    if (!ownsGateCheck(check, details)) {
      return;
    }

    await patchGateCheck(api, check, details, state);
    return;
  }

  await createGateCheck(api, details, state);
}

async function completeGate(api, details, conclusion, summary) {
  await upsertGateCheck(api, details, {
    conclusion,
    status: "completed",
    summary,
  });
}

async function ensureGatePending(api, details, summary) {
  const check = await getGateCheck(
    api,
    details.owner,
    details.repository,
    details.sha,
    details.gateAppId,
    details.checkName,
  );

  const state = { status: "in_progress", summary };

  if (check && ownsGateCheck(check, details)) {
    if (check.status === "completed") {
      await createGateCheck(api, details, state);
    } else {
      await patchGateCheck(api, check, details, state);
    }
    return;
  }

  if (
    check &&
    (isCheckClaimedAfterEvaluation(check, details.evaluationStartedAt) ||
      isCheckCompletedAfterEvaluation(check, details.evaluationStartedAt))
  ) {
    return;
  }

  if (!check || check.status === "completed") {
    await createGateCheck(api, details, state);
  }
}

async function isActiveTeamMember(api, organization, teamSlug, login) {
  const path = `/orgs/${organization}/teams/${encodeURIComponent(teamSlug)}/memberships/${encodeURIComponent(login)}`;
  const response = await api.request(path, { allowStatuses: [404] });

  return response.status === 200 && response.data?.state === "active";
}

async function getTeamReviewState(
  api,
  organization,
  teamSlug,
  reviews,
  pr,
  membershipLookupBudget,
) {
  const reviewerLogins = [
    ...new Set(
      getEffectiveReviews(reviews)
        .map((review) => review.user?.login)
        .filter(
          (login) =>
            login && login.toLowerCase() !== pr.user.login.toLowerCase(),
        ),
    ),
  ];

  if (reviewerLogins.length > membershipLookupBudget.remaining) {
    throw new Error(
      "Reviewer membership lookups exceeded the evaluation limit.",
    );
  }
  membershipLookupBudget.remaining -= reviewerLogins.length;

  const memberships = await Promise.all(
    reviewerLogins.map(async (login) => ({
      login,
      member: await isActiveTeamMember(api, organization, teamSlug, login),
    })),
  );
  const teamLogins = new Set(
    memberships.filter(({ member }) => member).map(({ login }) => login),
  );

  return evaluateTeamReviewState(
    reviews,
    teamLogins,
    pr.user.login,
    pr.head.sha,
  );
}

async function getCurrentTeamReviewState(context, prNumber, pr) {
  const reviews = await context.mparticleApi.paginate(
    toQueryPath(
      `/repos/${context.owner}/${context.repository}/pulls/${prNumber}/reviews`,
      { per_page: "100" },
    ),
  );

  return getTeamReviewState(
    context.mparticleApi,
    context.owner,
    context.manualReviewTeamSlug,
    reviews,
    pr,
    context.membershipLookupBudget,
  );
}

async function resolvePullRequestNumbers(
  event,
  api,
  owner,
  repository,
  requestedPullRequestNumber,
) {
  if (requestedPullRequestNumber) {
    return [requestedPullRequestNumber];
  }

  const eventPullRequestNumbers = getPullRequestNumbers(event);

  if (eventPullRequestNumbers.length > 0) {
    return eventPullRequestNumbers;
  }

  if (event.workflow_run?.head_sha) {
    const pullRequests = await api.paginate(
      toQueryPath(
        `/repos/${owner}/${repository}/commits/${event.workflow_run.head_sha}/pulls`,
        { per_page: "100" },
      ),
    );
    return [
      ...new Set(
        pullRequests
          .filter((pullRequest) => pullRequest.state === "open")
          .map((pullRequest) => pullRequest.number)
          .filter(Number.isInteger),
      ),
    ];
  }

  if (event.schedule) {
    const response = await api.request(
      toQueryPath(`/repos/${owner}/${repository}/pulls`, {
        direction: "desc",
        per_page: String(SCHEDULE_PULL_REQUEST_LIMIT),
        sort: "updated",
        state: "open",
      }),
    );
    const pullRequests = getPaginatedItems(response.data);

    return pullRequests
      .slice(0, SCHEDULE_PULL_REQUEST_LIMIT)
      .filter((pullRequest) => Number.isInteger(pullRequest.number))
      .map((pullRequest) => pullRequest.number);
  }

  console.log("No open pull request is associated with this event.");
  return [];
}

function requiredMode() {
  const mode = requiredInput("mode");

  if (!["audit", "enforce"].includes(mode)) {
    throw new Error("mode must be either audit or enforce.");
  }

  return mode;
}

async function completeDecision(context, details, conclusion, summary) {
  if (context.mode === "audit") {
    return completeGate(
      context.mparticleApi,
      details,
      "neutral",
      `Audit only: would report ${conclusion}. ${summary}`,
    );
  }

  return completeGate(context.mparticleApi, details, conclusion, summary);
}

async function evaluatePullRequest(context, prNumber) {
  const evaluationStartedAt = new Date().toISOString();
  const { mparticleApi, owner, policy, repository, roktApi } = context;
  const pr = (
    await mparticleApi.request(
      `/repos/${owner}/${repository}/pulls/${prNumber}`,
    )
  ).data;

  if (pr.state !== "open") {
    return true;
  }

  const details = {
    checkName: policy.gateCheckName,
    evaluationId: context.evaluationId,
    evaluationStartedAt,
    gateAppId: context.gateAppId,
    owner,
    prNumber,
    repository,
    sha: pr.head.sha,
  };

  try {
    await upsertGateCheck(mparticleApi, details, {
      status: "in_progress",
      summary: "Evaluating the current pull request head SHA.",
    });

    const pullRequestsAtHead = await mparticleApi.paginate(
      toQueryPath(
        `/repos/${owner}/${repository}/commits/${pr.head.sha}/pulls`,
        { per_page: "100" },
      ),
    );

    if (hasSharedOpenHead(pullRequestsAtHead, prNumber, pr.head.sha)) {
      await completeDecision(
        context,
        details,
        "failure",
        "The head commit is associated with multiple open pull requests, so it cannot receive a PR-specific Gate decision.",
      );
      return true;
    }

    if (pr.draft) {
      await completeDecision(
        context,
        details,
        "action_required",
        "Draft pull request; it cannot receive a passing Gate decision until it is ready for review.",
      );
      return true;
    }

    const [files, tree] = await Promise.all([
      mparticleApi.paginate(
        toQueryPath(`/repos/${owner}/${repository}/pulls/${prNumber}/files`, {
          per_page: "100",
        }),
      ),
      mparticleApi.request(
        `/repos/${owner}/${repository}/git/trees/${pr.head.sha}?recursive=1`,
      ),
    ]);

    if (tree.data.truncated) {
      await completeDecision(
        context,
        details,
        "failure",
        "Unable to safely inspect the full file tree.",
      );
      return true;
    }

    const fileState = classifyFiles(files, tree.data.tree, policy);

    if (!fileState.eligible) {
      const conclusion = getIneligibleFileConclusion(files, policy);

      if (conclusion === "success") {
        await completeDecision(
          context,
          details,
          conclusion,
          "The ruleset requires SDK-team approval for this pull request.",
        );
        return true;
      }

      const teamReviewState = await getCurrentTeamReviewState(
        context,
        prNumber,
        pr,
      );

      if (teamReviewState.hasBlockingChangeRequest) {
        await completeDecision(
          context,
          details,
          "action_required",
          "An SDK-team review requests changes on this pull request.",
        );
        return true;
      }

      if (teamReviewState.hasFreshApproval) {
        await completeDecision(
          context,
          details,
          "success",
          "A fresh SDK-team approval approved this safe-path exception for the current head SHA.",
        );
        return true;
      }

      await completeDecision(
        context,
        details,
        "action_required",
        "This safe-path-only pull request does not meet the Gate's safety requirements and requires a fresh SDK-team approval.",
      );
      return true;
    }

    const workflowRuns = await mparticleApi.paginate(
      toQueryPath(`/repos/${owner}/${repository}/actions/runs`, {
        event: "pull_request",
        head_sha: pr.head.sha,
        per_page: "100",
      }),
      "workflow_runs",
    );
    const workflowState = evaluateWorkflows(
      workflowRuns,
      policy.requiredWorkflows,
    );

    if (workflowState.state === "pending") {
      await ensureGatePending(
        mparticleApi,
        details,
        `Waiting for required workflow completion: ${workflowState.reason}.`,
      );
      console.log(
        `Waiting for required workflow completion on PR #${prNumber}.`,
      );
      return true;
    }

    if (workflowState.state === "failed") {
      await completeDecision(
        context,
        details,
        "failure",
        "A required workflow did not succeed.",
      );
      return true;
    }

    const teamReviewState = await getCurrentTeamReviewState(
      context,
      prNumber,
      pr,
    );

    if (teamReviewState.hasBlockingChangeRequest) {
      await completeDecision(
        context,
        details,
        "action_required",
        "An SDK-team review requests changes on this pull request.",
      );
      return true;
    }

    const employee = await isActiveTeamMember(
      roktApi,
      policy.roktOrganization,
      context.employeeTeamSlug,
      pr.user.login,
    );

    if (employee) {
      await completeDecision(
        context,
        details,
        "success",
        "Eligible Rokt employee pull request passed the Gate for the current head SHA.",
      );
      return true;
    }

    if (teamReviewState.hasFreshApproval) {
      await completeDecision(
        context,
        details,
        "success",
        "A fresh SDK-team approval satisfied the Gate for the current head SHA.",
      );
      return true;
    }

    await completeDecision(
      context,
      details,
      "action_required",
      "Awaiting a fresh SDK-team approval for this safe-path pull request.",
    );
    return true;
  } catch (error) {
    try {
      await completeDecision(
        context,
        details,
        "failure",
        "The Gate could not safely complete its evaluation.",
      );
    } catch {}

    console.error(`Rokt Safe PR Gate failed for PR #${prNumber}.`, error);
    return false;
  }
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

  const scheduled = Boolean(event.schedule);
  const apiOptions = scheduled
    ? { maxPages: SCHEDULE_PAGINATION_PAGE_LIMIT }
    : undefined;
  const mparticleApi = createApi(
    apiUrl,
    requiredInput("mparticle-token"),
    apiOptions,
  );
  const context = {
    employeeTeamSlug: requiredInput("employee-team-slug"),
    evaluationId: requiredInput("evaluation-id"),
    gateAppId: requiredInput("gate-app-id"),
    manualReviewTeamSlug: requiredInput("manual-review-team-slug"),
    membershipLookupBudget: {
      remaining: scheduled
        ? SCHEDULE_MEMBERSHIP_LOOKUP_LIMIT
        : Number.POSITIVE_INFINITY,
    },
    mparticleApi,
    mode: requiredMode(),
    owner,
    policy,
    repository,
    roktApi: createApi(apiUrl, requiredInput("rokt-token"), apiOptions),
  };
  const prNumbers = await resolvePullRequestNumbers(
    event,
    mparticleApi,
    owner,
    repository,
    optionalPullRequestNumber(),
  );
  let succeeded = true;

  for (const prNumber of prNumbers) {
    succeeded = (await evaluatePullRequest(context, prNumber)) && succeeded;
  }

  if (!succeeded) {
    process.exitCode = 1;
  }
}

if (require.main === module) {
  main().catch((error) => {
    console.error("Rokt Safe PR Gate failed.", error);
    process.exitCode = 1;
  });
}

module.exports = {
  createApi,
  ensureGatePending,
  evaluatePullRequest,
  getInput,
  resolvePullRequestNumbers,
  upsertGateCheck,
};
