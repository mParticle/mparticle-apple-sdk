const ALLOWED_FILE_STATUSES = new Set(["added", "modified"]);

function validatePolicy(policy) {
  if (!policy || typeof policy !== "object") {
    throw new Error("Policy must be an object.");
  }

  if (!Array.isArray(policy.safePaths) || policy.safePaths.length === 0) {
    throw new Error("Policy must define at least one safe path.");
  }

  if (
    typeof policy.gateCheckName !== "string" ||
    policy.gateCheckName.trim().length === 0
  ) {
    throw new Error("Policy must define a gate check name.");
  }

  if (
    !Number.isSafeInteger(policy.maxFiles) ||
    policy.maxFiles < 1 ||
    !Number.isSafeInteger(policy.maxChangedLines) ||
    policy.maxChangedLines < 1
  ) {
    throw new Error("Policy file and line limits must be positive integers.");
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
      path.startsWith(".github/") ||
      !path.endsWith(".md")
    ) {
      throw new Error(
        "Policy safe paths must be explicit Markdown, non-workflow paths.",
      );
    }
  }

  for (const workflow of policy.requiredWorkflows) {
    if (
      !workflow ||
      workflow.event !== "pull_request" ||
      typeof workflow.path !== "string" ||
      !workflow.path.startsWith(".github/workflows/") ||
      !workflow.path.endsWith(".yml")
    ) {
      throw new Error(
        "Policy required workflows must identify a pull-request workflow path.",
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

function getIneligibleFileConclusion(files, policy) {
  const safePaths = new Set(policy.safePaths);

  return files.every((file) => safePaths.has(file.filename))
    ? "action_required"
    : "success";
}

function evaluateWorkflows(runs, requirements) {
  for (const requirement of requirements) {
    const matchingRuns = runs
      .filter(
        (run) =>
          run.path === requirement.path && run.event === requirement.event,
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

    if (["cancelled", "skipped", "stale"].includes(latestRun.conclusion)) {
      return {
        state: "pending",
        reason: "required workflow must be re-run after cancellation",
      };
    }

    if (latestRun.conclusion !== "success") {
      return { state: "failed", reason: "required workflow did not succeed" };
    }
  }

  return { state: "success" };
}

function getPullRequestNumber(event) {
  return getPullRequestNumbers(event)[0] || null;
}

function getPullRequestNumbers(event) {
  if (Number.isInteger(event?.pull_request?.number)) {
    return [event.pull_request.number];
  }

  const pullRequests = event?.workflow_run?.pull_requests;

  if (Array.isArray(pullRequests)) {
    return [
      ...new Set(
        pullRequests
          .map((pullRequest) => pullRequest.number)
          .filter(Number.isInteger),
      ),
    ];
  }

  return [];
}

function hasSharedOpenHead(pullRequests, pullRequestNumber, headSha) {
  return pullRequests.some(
    (pullRequest) =>
      pullRequest.state === "open" &&
      pullRequest.number !== pullRequestNumber &&
      Number.isInteger(pullRequest.number) &&
      pullRequest.head?.sha === headSha,
  );
}

function getPaginatedItems(data, collectionKey) {
  const items = collectionKey ? data?.[collectionKey] : data;

  if (!Array.isArray(items)) {
    throw new Error("Expected a paginated GitHub API response.");
  }

  return items;
}

function getEffectiveReviews(reviews) {
  const effectiveReviews = new Map();

  for (const review of reviews) {
    const login = review.user?.login?.toLowerCase();

    if (
      !login ||
      !["APPROVED", "CHANGES_REQUESTED", "DISMISSED"].includes(review.state)
    ) {
      continue;
    }

    const currentReview = effectiveReviews.get(login);
    const currentTime = currentReview
      ? Date.parse(currentReview.submitted_at || 0) || 0
      : Number.NEGATIVE_INFINITY;
    const reviewTime = Date.parse(review.submitted_at || 0) || 0;
    const currentId = Number(currentReview?.id) || 0;
    const reviewId = Number(review.id) || 0;

    if (
      !currentReview ||
      reviewTime > currentTime ||
      (reviewTime === currentTime && reviewId > currentId)
    ) {
      effectiveReviews.set(login, review);
    }
  }

  return [...effectiveReviews.values()];
}

function evaluateTeamReviewState(reviews, teamLogins, authorLogin, headSha) {
  const normalizedTeamLogins = new Set(
    [...teamLogins].map((login) => login.toLowerCase()),
  );
  const normalizedAuthorLogin = authorLogin.toLowerCase();
  const teamReviews = getEffectiveReviews(reviews).filter((review) => {
    const login = review.user?.login?.toLowerCase();

    return (
      login &&
      login !== normalizedAuthorLogin &&
      normalizedTeamLogins.has(login)
    );
  });

  return {
    hasBlockingChangeRequest: teamReviews.some(
      (review) => review.state === "CHANGES_REQUESTED",
    ),
    hasFreshApproval: teamReviews.some(
      (review) => review.state === "APPROVED" && review.commit_id === headSha,
    ),
  };
}

module.exports = {
  classifyFiles,
  evaluateTeamReviewState,
  evaluateWorkflows,
  getEffectiveReviews,
  getIneligibleFileConclusion,
  getPaginatedItems,
  getPullRequestNumber,
  getPullRequestNumbers,
  hasSharedOpenHead,
  validatePolicy,
};
