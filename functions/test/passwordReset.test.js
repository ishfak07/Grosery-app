"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");

const {
  PASSWORD_RESET_APPROVAL_TTL_MS,
  PASSWORD_RESET_REQUEST_COOLDOWN_MS,
  isApprovalExpired,
  effectivePasswordResetStatus,
  isActivePasswordResetRequest,
  isPasswordResetRequestThrottled,
  passwordResetApprovalExpiresAtMillis,
  passwordResetStatusMessage,
  resetRequestCompletionStatus,
} = require("../lib/passwordReset");

const NOW = 1_700_000_000_000;

test("isApprovalExpired is false for non-approved statuses regardless of expiresAt", () => {
  for (const status of ["pending", "rejected", "completed", "expired"]) {
    assert.equal(isApprovalExpired(status, NOW - 1, NOW), false, status);
  }
});

test("isApprovalExpired is false for approved with no expiresAt (legacy requests)", () => {
  assert.equal(isApprovalExpired("approved", undefined, NOW), false);
  assert.equal(isApprovalExpired("approved", 0, NOW), false);
});

test("isApprovalExpired is false for approved before the TTL and true after", () => {
  assert.equal(isApprovalExpired("approved", NOW + 1, NOW), false);
  assert.equal(isApprovalExpired("approved", NOW - 1, NOW), true);
});

test("effectivePasswordResetStatus only overrides to expired when truly expired", () => {
  assert.equal(effectivePasswordResetStatus("approved", NOW + 1, NOW), "approved");
  assert.equal(effectivePasswordResetStatus("approved", NOW - 1, NOW), "expired");
  assert.equal(effectivePasswordResetStatus("pending", undefined, NOW), "pending");
  assert.equal(effectivePasswordResetStatus("rejected", NOW - 1, NOW), "rejected");
});

test("isActivePasswordResetRequest treats an expired approval as inactive", () => {
  assert.equal(isActivePasswordResetRequest("pending", undefined, NOW), true);
  assert.equal(isActivePasswordResetRequest("approved", NOW + 1, NOW), true);
  assert.equal(isActivePasswordResetRequest("approved", NOW - 1, NOW), false);
  assert.equal(isActivePasswordResetRequest("rejected", undefined, NOW), false);
  assert.equal(isActivePasswordResetRequest("completed", undefined, NOW), false);
});

test("passwordResetApprovalExpiresAtMillis adds the TTL to now", () => {
  assert.equal(
    passwordResetApprovalExpiresAtMillis(NOW),
    NOW + PASSWORD_RESET_APPROVAL_TTL_MS,
  );
});

test("passwordResetStatusMessage covers every known status plus a pending fallback", () => {
  assert.match(passwordResetStatusMessage("approved"), /Set a new password/);
  assert.match(passwordResetStatusMessage("rejected"), /Contact support/);
  assert.match(passwordResetStatusMessage("completed"), /already updated/);
  assert.match(passwordResetStatusMessage("expired"), /Submit a new reset request/);
  assert.match(passwordResetStatusMessage("pending"), /Waiting for admin approval/);
  assert.match(passwordResetStatusMessage("unknown"), /Waiting for admin approval/);
});

// resetRequestCompletionStatus gates completeApprovedPasswordReset (F1 fix):
// completion must be bound to the exact request document's own status/
// expiry/account fields, never to a phone-number lookup of "the latest
// approved request".
test("resetRequestCompletionStatus: a valid, unexpired, linked approval is ready", () => {
  assert.equal(
    resetRequestCompletionStatus("approved", NOW + 1000, "uid-1", NOW),
    "ready",
  );
});

test("resetRequestCompletionStatus: pending/rejected requests are not approved", () => {
  assert.equal(
    resetRequestCompletionStatus("pending", undefined, "uid-1", NOW),
    "not_approved",
  );
  assert.equal(
    resetRequestCompletionStatus("rejected", undefined, "uid-1", NOW),
    "not_approved",
  );
});

test("resetRequestCompletionStatus: an expired approval is rejected even with a valid account", () => {
  assert.equal(
    resetRequestCompletionStatus("approved", NOW - 1, "uid-1", NOW),
    "expired",
  );
});

test("resetRequestCompletionStatus: an already-completed request cannot be replayed", () => {
  assert.equal(
    resetRequestCompletionStatus("completed", NOW + 1000, "uid-1", NOW),
    "already_completed",
  );
});

test("resetRequestCompletionStatus: an approved request missing its account link is rejected", () => {
  assert.equal(
    resetRequestCompletionStatus("approved", NOW + 1000, "", NOW),
    "missing_account",
  );
  assert.equal(
    resetRequestCompletionStatus("approved", NOW + 1000, undefined, NOW),
    "missing_account",
  );
});

// isPasswordResetRequestThrottled backs the F6 rate-limit fix in
// requestPasswordReset.
test("isPasswordResetRequestThrottled: no previous request is never throttled", () => {
  assert.equal(isPasswordResetRequestThrottled(undefined, NOW), false);
  assert.equal(isPasswordResetRequestThrottled(0, NOW), false);
});

test("isPasswordResetRequestThrottled: a request created just now is throttled", () => {
  assert.equal(isPasswordResetRequestThrottled(NOW, NOW), true);
  assert.equal(
    isPasswordResetRequestThrottled(NOW - 1000, NOW),
    true,
  );
});

test("isPasswordResetRequestThrottled: clears once the cooldown window has fully elapsed", () => {
  assert.equal(
    isPasswordResetRequestThrottled(NOW - PASSWORD_RESET_REQUEST_COOLDOWN_MS + 1, NOW),
    true,
  );
  assert.equal(
    isPasswordResetRequestThrottled(NOW - PASSWORD_RESET_REQUEST_COOLDOWN_MS, NOW),
    false,
  );
  assert.equal(
    isPasswordResetRequestThrottled(NOW - PASSWORD_RESET_REQUEST_COOLDOWN_MS - 1, NOW),
    false,
  );
});

test("resetRequestCompletionStatus: only depends on the request's own fields, not any other request", () => {
  // Two different requests (e.g. two different phone numbers) are
  // evaluated purely from their own status/expiry/account - there is no
  // shared or cross-request state, so a requestId can never "borrow"
  // another request's approval.
  const requestA = resetRequestCompletionStatus("approved", NOW + 1000, "uid-a", NOW);
  const requestB = resetRequestCompletionStatus("pending", undefined, "uid-b", NOW);
  assert.equal(requestA, "ready");
  assert.equal(requestB, "not_approved");
});
