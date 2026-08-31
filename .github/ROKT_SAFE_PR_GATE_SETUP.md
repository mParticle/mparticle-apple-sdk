# Rokt Safe PR Gate Setup

The Gate is inert until the administrator setup below is complete. Complete the
proof of concept before making the Gate a required status check on `main`.

## 1. Create and install the Apps

Create two GitHub Apps. Keeping the Apps and private keys separate prevents an
mParticle check-writing credential from also being able to read Rokt membership
data.

| App                    | Installation                            | Required permissions                                                             |
| ---------------------- | --------------------------------------- | -------------------------------------------------------------------------------- |
| `Rokt Safe PR Gate`    | `mParticle`, only `mparticle-apple-sdk` | Actions: read; Checks: write; Contents: read; Members: read; Pull requests: read |
| `Rokt Employee Lookup` | `ROKT`                                  | Members: read                                                                    |

Neither App may receive contents-write, administration, merge, push, or
ruleset-bypass permissions. Neither App submits a pull-request review.

## 2. Configure repository settings

Add these repository variables:

| Variable                                    | Value                                     |
| ------------------------------------------- | ----------------------------------------- |
| `ROKT_SAFE_PR_GATE_ENABLED`                 | `true` only during validation/enforcement |
| `ROKT_SAFE_PR_GATE_MODE`                    | `audit` initially, then `enforce`         |
| `ROKT_SAFE_PR_GATE_MPARTICLE_APP_ID`        | `Rokt Safe PR Gate` App ID                |
| `ROKT_SAFE_PR_GATE_ROKT_APP_ID`             | `Rokt Employee Lookup` App ID             |
| `ROKT_SAFE_PR_GATE_EMPLOYEE_TEAM_SLUG`      | IdP-synchronised Rokt employee team slug  |
| `ROKT_SAFE_PR_GATE_MANUAL_REVIEW_TEAM_SLUG` | `sdk-team`                                |

Add these repository secrets:

| Secret                                        | Value                                  |
| --------------------------------------------- | -------------------------------------- |
| `ROKT_SAFE_PR_GATE_MPARTICLE_APP_PRIVATE_KEY` | `Rokt Safe PR Gate` App private key    |
| `ROKT_SAFE_PR_GATE_ROKT_APP_PRIVATE_KEY`      | `Rokt Employee Lookup` App private key |

There is no machine reviewer, reviewer token, or ruleset bypass actor in this
design.

## 3. Validate before enforcement

First set `ROKT_SAFE_PR_GATE_ENABLED` to `true` and
`ROKT_SAFE_PR_GATE_MODE` to `audit`, without adding the Gate to the ruleset.
Run this for one to two weeks and inspect the neutral check output. Only then
set the mode to `enforce` and test these fixture pull requests:

1. A verified Rokt employee changes one allowlisted Markdown file: CI and the
   Gate should pass without a review.
2. A non-employee changes that same file: CI should pass and the Gate should
   report `action_required` until an SDK-team member approves the current SHA.
3. A Rokt employee changes source code, or mixes source with an allowlisted
   Markdown file: the Gate should pass immediately, but the ruleset must
   require SDK-team approval. Source CI remains advisory, just as it is today.
4. Any change under `.github/workflows`: the Gate must not classify it as safe.
5. Push a new commit after every passing case: the new SHA must receive a new
   Gate decision and cannot inherit a prior approval.
6. Have an SDK-team reviewer request changes on a safe employee PR: the Gate
   must report `action_required` until that reviewer approves or dismisses the
   request.
7. Repeat the first fixture from a fork: the size report must skip its PR
   comment and the Gate must still react to a successful `Pull request` run.
8. Retarget a previously safe pull request: the `edited` event must re-evaluate
   the current base diff before the Gate reports success.
9. Make a safe-path-only pull request exceed a Gate limit, rename a file, or
   mark it as a draft: the Gate must report `action_required`. The author must
   correct it before it can merge without SDK-team review.

For fork PRs, the Gate's trusted scheduled run re-evaluates manual approvals at
most five minutes later. An SDK-team maintainer can instead use **Actions →
Rokt Safe PR Gate → Run workflow** with the pull request number for an immediate
re-evaluation. The workflow never runs a pull-request review event with secrets;
it evaluates only code checked out from the default branch.

## 4. Change the active `main` ruleset atomically

Capture the current ruleset JSON first. In ruleset `6260587`:

1. Retain pull requests, stale-review dismissal, resolved-thread enforcement,
   unattributed-change handling, and allowed merge methods.
2. Set **required approving review count** to `0` and turn off **require Code
   Owner review**. `CODEOWNERS` remains unchanged and continues to request the
   SDK team; it no longer enforces every path.
3. Add a **required reviewer** entry for `@mParticle/sdk-team`, with one
   approval and these ordered file patterns:

   ```text
   **
   !README.md
   !ARCHITECTURE.md
   !CONTRIBUTING.md
   !Kits/README.md
   !IntegrationTests/README.md
   ```

4. Add `Rokt Safe PR Gate` as a required, strict status check and pin its
   expected source to the `Rokt Safe PR Gate` App.

The explicit paths above must exactly match
`.github/rokt-safe-pr-gate-policy.json`. A mixed PR matches `**` through its
non-safe file and therefore still needs an SDK-team approval.

The existing unattributed-change rule remains in force. A successful Gate check
can still require the extra approval that GitHub applies to an unattributed
commit.

## Rollback

Remove `Rokt Safe PR Gate` from required status checks first, then restore the
captured pull-request settings (`required_approving_review_count: 1` and
`require_code_owner_review: true`). Finally set
`ROKT_SAFE_PR_GATE_ENABLED` to `false`.
