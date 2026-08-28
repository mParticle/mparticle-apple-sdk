const test = require("node:test");
const assert = require("node:assert/strict");
const {
  classifyFiles,
  evaluateWorkflows,
  getOpenPullRequestNumber,
  getPaginatedItems,
  getPullRequestNumber,
  hasFreshApproval,
  validatePolicy,
} = require("../lib/gate");

const policy = {
  gateCheckName: "Rokt Safe PR Gate",
  maxChangedLines: 500,
  maxFiles: 10,
  requiredWorkflows: [{ event: "pull_request", name: "Pull request" }],
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
    [{ event: "pull_request", name: "Pull request", status: "in_progress" }],
    policy.requiredWorkflows,
  );
  const failed = evaluateWorkflows(
    [
      {
        conclusion: "failure",
        event: "pull_request",
        name: "Pull request",
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
        name: "Pull request",
        status: "completed",
        updated_at: "2026-08-29T00:00:00Z",
      },
      {
        conclusion: "success",
        event: "pull_request",
        name: "Pull request",
        status: "completed",
        updated_at: "2026-08-29T00:01:00Z",
      },
    ],
    policy.requiredWorkflows,
  );

  assert.deepEqual(result, { state: "success" });
});

test("resolves pull request numbers from both supported events", () => {
  assert.equal(getPullRequestNumber({ pull_request: { number: 42 } }), 42);
  assert.equal(
    getPullRequestNumber({ workflow_run: { pull_requests: [{ number: 43 }] } }),
    43,
  );
  assert.equal(getPullRequestNumber({}), null);
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

test("selects the open pull request for a workflow run head SHA", () => {
  assert.equal(
    getOpenPullRequestNumber([
      { number: 7, state: "closed" },
      { number: 8, state: "open" },
    ]),
    8,
  );
  assert.equal(
    getOpenPullRequestNumber([{ number: 9, state: "closed" }]),
    null,
  );
});

test("requires a gate approval on the current head SHA", () => {
  const reviews = [
    {
      commit_id: "old",
      state: "APPROVED",
      user: { login: "app/rokt-safe-pr-gate" },
    },
    {
      commit_id: "current",
      state: "APPROVED",
      user: { login: "APP/ROKT-SAFE-PR-GATE" },
    },
  ];

  assert.equal(
    hasFreshApproval(reviews, "app/rokt-safe-pr-gate", "current"),
    true,
  );
  assert.equal(
    hasFreshApproval(reviews, "app/rokt-safe-pr-gate", "new"),
    false,
  );
});

test("rejects an unsafe policy definition", () => {
  assert.throws(
    () => validatePolicy({ safePaths: ["*.md"] }),
    /required workflow/,
  );
  assert.throws(
    () =>
      validatePolicy({ ...policy, safePaths: [".github/workflows/gate.yml"] }),
    /non-workflow/,
  );
});
