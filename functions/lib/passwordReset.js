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

// F6 fix: minimum time between two requestPasswordReset calls for the same
// phone number, regardless of the previous request's status. The existing
// active-request check already collapses repeated calls while a request is
// still pending/approved (returning the same request instead of creating a
// new one) - this cooldown covers the remaining gap, right after a request
// is rejected or its approval expires, when a new one could otherwise be
// created (and a new admin notification sent) as fast as the caller likes.
const PASSWORD_RESET_REQUEST_COOLDOWN_MS = 5 * 60 * 1000;

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

/**
 * Whether a new password-reset request for a phone number should be
 * refused for now because the previous one (of any status) was created too
 * recently. `lastRequestCreatedAtMillis` is undefined/0 when there is no
 * previous request at all, which is never throttled.
 */
function isPasswordResetRequestThrottled(lastRequestCreatedAtMillis, nowMillis) {
  if (!lastRequestCreatedAtMillis) {
    return false;
  }
  return nowMillis - lastRequestCreatedAtMillis < PASSWORD_RESET_REQUEST_COOLDOWN_MS;
}

/**
 * Pure gate for completeApprovedPasswordReset: given the exact reset-request
 * document's own fields, decides whether this specific request is safe to
 * complete right now. Kept separate from Firestore/Auth I/O so every branch
 * (already completed, wrong status, expired, missing account link) can be
 * unit tested without an emulator.
 */
function resetRequestCompletionStatus(status, expiresAtMillis, userId, nowMillis) {
  const normalizedStatus = status || "pending";
  if (normalizedStatus === "completed") {
    return "already_completed";
  }
  if (normalizedStatus !== "approved") {
    return "not_approved";
  }
  if (isApprovalExpired(normalizedStatus, expiresAtMillis, nowMillis)) {
    return "expired";
  }
  if (!userId || !`${userId}`.trim()) {
    return "missing_account";
  }
  return "ready";
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
  PASSWORD_RESET_REQUEST_COOLDOWN_MS,
  isApprovalExpired,
  effectivePasswordResetStatus,
  isActivePasswordResetRequest,
  isPasswordResetRequestThrottled,
  passwordResetApprovalExpiresAtMillis,
  passwordResetStatusMessage,
  resetRequestCompletionStatus,
};
