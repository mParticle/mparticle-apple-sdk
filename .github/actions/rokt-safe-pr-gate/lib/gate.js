const ALLOWED_FILE_STATUSES = new Set(["added", "modified"]);

function validatePolicy(policy) {
  if (!policy || typeof policy !== "object") {
    throw new Error("Policy must be an object.");
  }

  if (!Array.isArray(policy.safePaths) || policy.safePaths.length === 0) {
    throw new Error("Policy must define at least one safe path.");
  }

  if (
    !Array.isArray(policy.requiredWorkflows) ||
    policy.requiredWorkflows.length === 0
  ) {
    throw new Error("Policy must define at least one required workflow.");
  }

  for (const path of policy.safePaths) {
    if (
      typeof path !== "string" ||
      path.length === 0 ||
      path.includes("*") ||
      path.startsWith(".github/")
    ) {
      throw new Error(
        "Policy safe paths must be explicit, non-workflow paths.",
      );
    }
  }

  return policy;
}

function classifyFiles(files, treeEntries, policy) {
  const reasons = [];
  const safePaths = new Set(policy.safePaths);
  const treeByPath = new Map(treeEntries.map((entry) => [entry.path, entry]));
  const changedLines = files.reduce(
    (total, file) => total + (file.changes || 0),
    0,
  );

  if (files.length === 0) {
    reasons.push("no changed files");
  }

  if (files.length > policy.maxFiles) {
    reasons.push("too many changed files");
  }

  if (changedLines > policy.maxChangedLines) {
    reasons.push("too many changed lines");
  }

  for (const file of files) {
    const treeEntry = treeByPath.get(file.filename);

    if (!safePaths.has(file.filename)) {
      reasons.push("path is not allowlisted");
    }

    if (!ALLOWED_FILE_STATUSES.has(file.status)) {
      reasons.push("file operation is not allowed");
    }

    if (typeof file.patch !== "string") {
      reasons.push("file diff is unavailable");
    }

    if (
      !treeEntry ||
      treeEntry.type !== "blob" ||
      treeEntry.mode !== "100644"
    ) {
      reasons.push("file mode or type is not allowed");
    }
  }

  return {
    eligible: reasons.length === 0,
    reasons: [...new Set(reasons)],
  };
}

function evaluateWorkflows(runs, requirements) {
  for (const requirement of requirements) {
    const matchingRuns = runs
      .filter(
        (run) =>
          run.name === requirement.name && run.event === requirement.event,
      )
      .sort(
        (left, right) =>
          Date.parse(right.updated_at) - Date.parse(left.updated_at),
      );

    if (matchingRuns.length === 0) {
      return { state: "pending", reason: "required workflow has not started" };
    }

    const latestRun = matchingRuns[0];

    if (latestRun.status !== "completed") {
      return { state: "pending", reason: "required workflow is still running" };
    }

    if (latestRun.conclusion !== "success") {
      return { state: "failed", reason: "required workflow did not succeed" };
    }
  }

  return { state: "success" };
}

function getPullRequestNumber(event) {
  if (Number.isInteger(event?.pull_request?.number)) {
    return event.pull_request.number;
  }

  const pullRequests = event?.workflow_run?.pull_requests;

  if (
    Array.isArray(pullRequests) &&
    Number.isInteger(pullRequests[0]?.number)
  ) {
    return pullRequests[0].number;
  }

  return null;
}

function getPaginatedItems(data, collectionKey) {
  const items = collectionKey ? data?.[collectionKey] : data;

  if (!Array.isArray(items)) {
    throw new Error("Expected a paginated GitHub API response.");
  }

  return items;
}

function getOpenPullRequestNumber(pullRequests) {
  return (
    pullRequests.find((pullRequest) => pullRequest.state === "open")?.number ||
    null
  );
}

function hasFreshApproval(reviews, reviewerLogin, headSha) {
  return reviews.some(
    (review) =>
      review.state === "APPROVED" &&
      review.commit_id === headSha &&
      review.user?.login?.toLowerCase() === reviewerLogin.toLowerCase(),
  );
}

module.exports = {
  classifyFiles,
  evaluateWorkflows,
  getOpenPullRequestNumber,
  getPaginatedItems,
  getPullRequestNumber,
  hasFreshApproval,
  validatePolicy,
};
