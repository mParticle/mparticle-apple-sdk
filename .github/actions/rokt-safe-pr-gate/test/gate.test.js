const test = require("node:test");
const assert = require("node:assert/strict");
const {
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
} = require("../lib/gate");
const {
  ensureGatePending,
  evaluatePullRequest,
  getInput,
  resolvePullRequestNumbers,
} = require("../index");

const policy = {
  gateCheckName: "Rokt Safe PR Gate",
  maxChangedLines: 500,
  maxFiles: 10,
  requiredWorkflows: [
    { event: "pull_request", path: ".github/workflows/pull-request.yml" },
  ],
  roktOrganization: "ROKT",
  safePaths: ["README.md"],
};

const safeFile = {
  changes: 10,
  filename: "README.md",
  patch: "@@ -1 +1 @@\n-old\n+new",
  status: "modified",
};

const safeTree = [{ mode: "100644", path: "README.md", type: "blob" }];

test("accepts an explicit safe Markdown modification", () => {
  assert.deepEqual(classifyFiles([safeFile], safeTree, policy), {
    eligible: true,
    reasons: [],
  });
});

test("rejects a mixed documentation and source change", () => {
  const sourceFile = {
    changes: 1,
    filename: "mParticle-Apple-SDK/MPBaseController.m",
    patch: "@@ -1 +1 @@\n-old\n+new",
    status: "modified",
  };
  const tree = [
    ...safeTree,
    { mode: "100644", path: sourceFile.filename, type: "blob" },
  ];

  assert.equal(
    classifyFiles([safeFile, sourceFile], tree, policy).eligible,
    false,
  );
  assert.equal(
    getIneligibleFileConclusion([safeFile, sourceFile], policy),
    "success",
  );
  assert.equal(
    getIneligibleFileConclusion([safeFile], policy),
    "action_required",
  );
});

test("rejects a renamed file, executable file, and unavailable diff", () => {
  const unsafeFile = {
    changes: 1,
    filename: "README.md",
    status: "renamed",
  };

  const state = classifyFiles(
    [unsafeFile],
    [{ mode: "100755", path: "README.md", type: "blob" }],
    policy,
  );

  assert.equal(state.eligible, false);
  assert.deepEqual(state.reasons.sort(), [
    "file diff is unavailable",
    "file mode or type is not allowed",
    "file operation is not allowed",
  ]);
});

test("waits for a required workflow and fails on its unsuccessful conclusion", () => {
  const pending = evaluateWorkflows(
    [
      {
        event: "pull_request",
        path: ".github/workflows/pull-request.yml",
        status: "in_progress",
      },
    ],
    policy.requiredWorkflows,
  );
  const failed = evaluateWorkflows(
    [
      {
        conclusion: "failure",
        event: "pull_request",
        path: ".github/workflows/pull-request.yml",
        status: "completed",
        updated_at: "2026-08-29T00:00:00Z",
      },
    ],
    policy.requiredWorkflows,
  );

  assert.equal(pending.state, "pending");
  assert.equal(failed.state, "failed");
});

test("uses only the latest successful matching workflow run", () => {
  const result = evaluateWorkflows(
    [
      {
        conclusion: "failure",
        event: "pull_request",
        path: ".github/workflows/pull-request.yml",
        status: "completed",
        updated_at: "2026-08-29T00:00:00Z",
      },
      {
        conclusion: "success",
        event: "pull_request",
        path: ".github/workflows/pull-request.yml",
        status: "completed",
        updated_at: "2026-08-29T00:01:00Z",
      },
    ],
    policy.requiredWorkflows,
  );

  assert.deepEqual(result, { state: "success" });
});

test("waits for a cancelled workflow to be re-run", () => {
  assert.deepEqual(
    evaluateWorkflows(
      [
        {
          conclusion: "cancelled",
          event: "pull_request",
          path: ".github/workflows/pull-request.yml",
          status: "completed",
          updated_at: "2026-08-29T00:01:00Z",
        },
      ],
      policy.requiredWorkflows,
    ),
    {
      state: "pending",
      reason: "required workflow must be re-run after cancellation",
    },
  );
});

test("resolves pull request numbers from both supported events", () => {
  assert.equal(getPullRequestNumber({ pull_request: { number: 42 } }), 42);
  assert.equal(
    getPullRequestNumber({ workflow_run: { pull_requests: [{ number: 43 }] } }),
    43,
  );
  assert.equal(getPullRequestNumber({}), null);
  assert.deepEqual(
    getPullRequestNumbers({
      workflow_run: { pull_requests: [{ number: 43 }, { number: 44 }] },
    }),
    [43, 44],
  );
});

test("rejects a Gate decision shared by multiple open pull requests", () => {
  const headSha = "shared-head";
  assert.equal(
    hasSharedOpenHead(
      [
        { head: { sha: headSha }, number: 42, state: "open" },
        { head: { sha: headSha }, number: 43, state: "open" },
        { head: { sha: headSha }, number: 44, state: "closed" },
      ],
      42,
      headSha,
    ),
    true,
  );
  assert.equal(
    hasSharedOpenHead(
      [
        { head: { sha: headSha }, number: 42, state: "open" },
        { head: { sha: "nested-head" }, number: 43, state: "open" },
      ],
      42,
      headSha,
    ),
    false,
  );
});

test("reads array and wrapped GitHub API pagination responses", () => {
  assert.deepEqual(getPaginatedItems([{ id: 1 }]), [{ id: 1 }]);
  assert.deepEqual(
    getPaginatedItems({ check_runs: [{ id: 2 }] }, "check_runs"),
    [{ id: 2 }],
  );
  assert.deepEqual(
    getPaginatedItems({ workflow_runs: [{ id: 3 }] }, "workflow_runs"),
    [{ id: 3 }],
  );
  assert.throws(() => getPaginatedItems({ check_runs: [] }), /paginated/);
});

test("polls every open pull request for a scheduled recheck", async () => {
  const calls = [];
  const api = {
    paginate: async (path) => {
      calls.push(path);
      return [{ number: 7 }, { number: 8, state: "open" }];
    },
  };

  assert.deepEqual(
    await resolvePullRequestNumbers(
      { schedule: "*/5 * * * *" },
      api,
      "mParticle",
      "mparticle-apple-sdk",
      null,
    ),
    [7, 8],
  );
  assert.match(calls[0], /state=open/);
});

test("requires a fresh non-author SDK-team approval on the current head SHA", () => {
  const reviews = [
    {
      commit_id: "old",
      id: 1,
      state: "APPROVED",
      user: { login: "app/rokt-safe-pr-gate" },
      submitted_at: "2026-08-29T00:00:00Z",
    },
    {
      commit_id: "current",
      id: 2,
      state: "APPROVED",
      user: { login: "sdk-reviewer" },
      submitted_at: "2026-08-29T00:01:00Z",
    },
  ];

  assert.deepEqual(
    evaluateTeamReviewState(
      reviews,
      new Set(["SDK-REVIEWER"]),
      "author",
      "current",
    ),
    { hasBlockingChangeRequest: false, hasFreshApproval: true },
  );
});

test("uses each reviewer's latest substantive review state", () => {
  const reviews = [
    {
      commit_id: "current",
      id: 1,
      state: "APPROVED",
      submitted_at: "2026-08-29T00:00:00Z",
      user: { login: "sdk-reviewer" },
    },
    {
      commit_id: "current",
      id: 2,
      state: "COMMENTED",
      submitted_at: "2026-08-29T00:01:00Z",
      user: { login: "sdk-reviewer" },
    },
    {
      commit_id: "current",
      id: 3,
      state: "CHANGES_REQUESTED",
      submitted_at: "2026-08-29T00:02:00Z",
      user: { login: "sdk-reviewer" },
    },
    {
      commit_id: "current",
      id: 4,
      state: "APPROVED",
      submitted_at: "2026-08-29T00:03:00Z",
      user: { login: "author" },
    },
  ];

  assert.deepEqual(
    getEffectiveReviews(reviews).map((review) => review.id),
    [3, 4],
  );
  assert.deepEqual(
    evaluateTeamReviewState(
      reviews,
      new Set(["sdk-reviewer", "author"]),
      "AUTHOR",
      "current",
    ),
    { hasBlockingChangeRequest: true, hasFreshApproval: false },
  );
});

test("rejects an unsafe policy definition", () => {
  assert.throws(
    () => validatePolicy({ ...policy, safePaths: ["*.md"] }),
    /explicit Markdown/,
  );
  assert.throws(
    () =>
      validatePolicy({ ...policy, safePaths: [".github/workflows/gate.yml"] }),
    /explicit Markdown/,
  );
  assert.throws(
    () => validatePolicy({ ...policy, maxFiles: undefined }),
    /positive integers/,
  );
  assert.throws(
    () => validatePolicy({ ...policy, gateCheckName: "" }),
    /gate check name/,
  );
  assert.throws(
    () =>
      validatePolicy({
        ...policy,
        requiredWorkflows: [{ event: "pull_request", name: "Pull request" }],
      }),
    /workflow path/,
  );
});

test("reads hyphenated composite-action input names", () => {
  const inputName = "INPUT_EVENT-PATH";
  const previousValue = process.env[inputName];
  process.env[inputName] = "/tmp/event.json";
  assert.equal(getInput("event-path"), "/tmp/event.json");
  if (previousValue === undefined) delete process.env[inputName];
  else process.env[inputName] = previousValue;
});

test("replaces a completed Gate check while required CI is pending", async () => {
  const requests = [];
  const api = {
    paginate: async () => [
      {
        app: { id: 99 },
        id: 42,
        name: "Rokt Safe PR Gate",
        status: "completed",
      },
    ],
    request: async (path, options) => requests.push({ options, path }),
  };
  await ensureGatePending(
    api,
    {
      checkName: "Rokt Safe PR Gate",
      gateAppId: "99",
      owner: "mParticle",
      prNumber: 7,
      repository: "mparticle-apple-sdk",
      sha: "b".repeat(40),
    },
    "Waiting for CI.",
  );

  assert.equal(requests.length, 1);
  assert.match(requests[0].path, /\/check-runs$/);
  assert.equal(requests[0].options.method, "POST");
  assert.equal(requests[0].options.body.status, "in_progress");
});

function gateContext(mparticleApi) {
  return {
    employeeTeamSlug: "employees",
    gateAppId: "99",
    manualReviewTeamSlug: "sdk-team",
    mode: "enforce",
    mparticleApi,
    owner: "mParticle",
    policy,
    repository: "mparticle-apple-sdk",
    roktApi: {},
  };
}

test("blocks a draft pull request instead of recording a passing Gate", async () => {
  const requests = [];
  const sha = "c".repeat(40);
  const api = {
    paginate: async () => [],
    request: async (path, options = {}) => {
      requests.push({ options, path });
      if (path.endsWith("/pulls/9")) {
        return {
          data: {
            draft: true,
            head: { sha },
            state: "open",
            user: { login: "author" },
          },
        };
      }
      return { data: {} };
    },
  };

  assert.equal(await evaluatePullRequest(gateContext(api), 9), true);
  const completedCheck = requests.find(
    ({ options }) => options.body?.conclusion === "action_required",
  );
  assert.ok(completedCheck);
});

test("blocks an oversized safe-path-only pull request", async () => {
  const requests = [];
  const sha = "d".repeat(40);
  const api = {
    paginate: async (path) => {
      if (path.includes("check-runs")) return [];
      if (path.includes(`/commits/${sha}/pulls`)) {
        return [{ head: { sha }, number: 10, state: "open" }];
      }
      if (path.includes("/pulls/10/files")) {
        return [{ ...safeFile, changes: policy.maxChangedLines + 1 }];
      }
      throw new Error(`Unexpected paginated path: ${path}`);
    },
    request: async (path, options = {}) => {
      requests.push({ options, path });
      if (path.endsWith("/pulls/10")) {
        return {
          data: {
            draft: false,
            head: { sha },
            state: "open",
            user: { login: "author" },
          },
        };
      }
      if (path.includes(`/git/trees/${sha}`))
        return { data: { tree: safeTree } };
      return { data: {} };
    },
  };

  assert.equal(await evaluatePullRequest(gateContext(api), 10), true);
  const completedCheck = requests.find(
    ({ options }) => options.body?.conclusion === "action_required",
  );
  assert.ok(completedCheck);
});
