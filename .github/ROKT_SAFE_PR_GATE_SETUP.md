# Rokt Safe PR Gate Setup

The gate is inert until the administrator setup below is complete. Do not add its
status check to the `main` ruleset until the proof of concept passes.

## 1. Create and install the App

Create one GitHub App and install it in both organisations.

| Installation | Required permissions                                              |
| ------------ | ----------------------------------------------------------------- |
| `mParticle`  | Actions: read; Checks: write; Contents: read; Pull requests: read |
| `ROKT`       | Members: read                                                     |

The App must not receive contents-write, administration, merge, push, or ruleset-bypass
permissions.

## 2. Create the code-owner reviewer

Create a dedicated machine user and add it to the existing `@mParticle/sdk-team` team.
This is necessary because the active `main` ruleset requires a Code Owner approval, and
GitHub Apps cannot be listed as Code Owners. Limit its token to this repository and pull
request review access.

## 3. Configure repository settings

Add these repository variables:

| Variable                               | Value                                    |
| -------------------------------------- | ---------------------------------------- |
| `ROKT_SAFE_PR_GATE_ENABLED`            | `true` after validation                  |
| `ROKT_SAFE_PR_GATE_APP_ID`             | Numeric GitHub App ID                    |
| `ROKT_SAFE_PR_GATE_EMPLOYEE_TEAM_SLUG` | IdP-synchronised Rokt employee team slug |
| `ROKT_SAFE_PR_GATE_REVIEWER_LOGIN`     | Machine-user GitHub login                |

Add these repository secrets:

| Secret                              | Value                           |
| ----------------------------------- | ------------------------------- |
| `ROKT_SAFE_PR_GATE_APP_PRIVATE_KEY` | GitHub App private key          |
| `ROKT_SAFE_PR_GATE_REVIEWER_TOKEN`  | Machine-user fine-grained token |

## 4. Validate before enforcement

Test an employee documentation-only PR, a non-employee documentation PR, a mixed
documentation-and-source PR, and a workflow-file change. Confirm that each decision is
made for the newest PR SHA and that a push dismisses the previous automated approval.

## 5. Enable the ruleset check

Edit the active `main` ruleset and add `Rokt Safe PR Gate` as a required, strict status
check. Pin the expected source to the new GitHub App. Retain the existing Code Owner
requirement, one required approval, stale-review dismissal, and resolved-thread rule.

## Rollback

Set `ROKT_SAFE_PR_GATE_ENABLED` to `false`, then remove the Gate status check from the
ruleset. The repository returns to its existing manual Code Owner review behaviour.
