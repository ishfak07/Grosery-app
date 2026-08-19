"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");

const {
  PASSWORD_RESET_APPROVAL_TTL_MS,
  isApprovalExpired,
  effectivePasswordResetStatus,
  isActivePasswordResetRequest,
  passwordResetApprovalExpiresAtMillis,
  passwordResetStatusMessage,
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
