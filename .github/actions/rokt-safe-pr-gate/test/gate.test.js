const test = require("node:test");
const assert = require("node:assert/strict");
const {
  classifyFiles,
  evaluateTeamReviewState,
  evaluateWorkflows,
  getEffectiveReviews,
  getPaginatedItems,
  getPullRequestNumber,
  getPullRequestNumbers,
  hasSharedOpenHead,
  validatePolicy,
} = require("../lib/gate");
const { resolvePullRequestNumbers } = require("../index");

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
  assert.equal(
    hasSharedOpenHead(
      [
        { number: 42, state: "open" },
        { number: 43, state: "open" },
        { number: 44, state: "closed" },
      ],
      42,
    ),
    true,
  );
  assert.equal(hasSharedOpenHead([{ number: 42, state: "open" }], 42), false);
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
