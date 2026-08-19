"use strict";

/**
 * Pure logic for password-reset-request status/expiry. Kept free of any
 * Firestore/admin-sdk dependency so it can be unit tested with the Node
 * built-in test runner (no emulator).
 *
 * An "approved" reset request is a time-limited authorization, not a
 * permanent one. `expiresAtMillis` is written by approvePasswordReset in
 * index.js at approval time; everything here is a pure function of
 * (status, expiresAtMillis, nowMillis) so the same rule protects the
 * completion gate, the customer-facing status lookups, and the admin badge
 * without any of them needing to agree on a background job.
 */

const PASSWORD_RESET_APPROVAL_TTL_MS = 24 * 60 * 60 * 1000;

const ACTIVE_STATUSES = ["pending", "approved"];

function isApprovalExpired(status, expiresAtMillis, nowMillis) {
  if (status !== "approved") {
    return false;
  }
  if (!expiresAtMillis) {
    return false;
  }
  return expiresAtMillis < nowMillis;
}

function effectivePasswordResetStatus(status, expiresAtMillis, nowMillis) {
  return isApprovalExpired(status, expiresAtMillis, nowMillis) ?
    "expired" :
    status;
}

function isActivePasswordResetRequest(status, expiresAtMillis, nowMillis) {
  if (!ACTIVE_STATUSES.includes(status)) {
    return false;
  }
  return !isApprovalExpired(status, expiresAtMillis, nowMillis);
}

function passwordResetApprovalExpiresAtMillis(nowMillis) {
  return nowMillis + PASSWORD_RESET_APPROVAL_TTL_MS;
}

function passwordResetStatusMessage(status) {
  switch (status) {
    case "approved":
      return "Admin approved your reset. Set a new password.";
    case "rejected":
      return "Admin rejected this reset request. Contact support.";
    case "completed":
      return "Password already updated. Login with the new password.";
    case "expired":
      return "This approval has expired. Submit a new reset request.";
    default:
      return "Waiting for admin approval.";
  }
}

module.exports = {
  PASSWORD_RESET_APPROVAL_TTL_MS,
  isApprovalExpired,
  effectivePasswordResetStatus,
  isActivePasswordResetRequest,
  passwordResetApprovalExpiresAtMillis,
  passwordResetStatusMessage,
};
