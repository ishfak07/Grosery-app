// A push token identifies one app install, not one account. When several
// accounts share a phone (admin + customer, logout/login), the same token
// can end up saved on more than one user document, and that phone then
// receives every one of those accounts' notifications - even while logged
// out. These helpers work out which tokens a user write has just claimed so
// the token can be removed from every other account.

function tokenList(data) {
  const raw = data?.fcmTokens;
  const list = Array.isArray(raw) ? raw : raw ? [raw] : [];
  return list
    .map((token) => `${token || ""}`.trim())
    .filter((token) => token.length > 0);
}

function primaryToken(data) {
  return `${data?.fcmToken || ""}`.trim();
}

function timestampKey(value) {
  if (!value) {
    return "";
  }
  if (typeof value.toMillis === "function") {
    return `${value.toMillis()}`;
  }
  if (value instanceof Date) {
    return `${value.getTime()}`;
  }
  return `${value}`;
}

/**
 * Tokens the device behind this write has just registered for the user.
 *
 * - Tokens newly added to `fcmTokens` are always claimed.
 * - The primary `fcmToken` is claimed when it changed, or when the client
 *   re-saved it (fcmTokenUpdatedAt moved) without removing any token -
 *   i.e. a login on a device whose token was already stored. A write that
 *   removes tokens is a logout cleanup and never claims anything.
 */
function claimedPushTokens(before, after) {
  if (!after) {
    return [];
  }

  const beforeTokens = new Set(tokenList(before));
  const afterTokens = tokenList(after);
  const afterTokenSet = new Set(afterTokens);
  const claimed = new Set(
    afterTokens.filter((token) => !beforeTokens.has(token)),
  );

  const beforePrimary = primaryToken(before);
  const afterPrimary = primaryToken(after);
  const removedAnyToken =
    [...beforeTokens].some((token) => !afterTokenSet.has(token)) ||
    (beforePrimary.length > 0 && afterPrimary.length === 0);
  const resaved = timestampKey(before?.fcmTokenUpdatedAt) !==
    timestampKey(after?.fcmTokenUpdatedAt);

  if (
    afterPrimary.length > 0 &&
    (afterPrimary !== beforePrimary || (resaved && !removedAnyToken))
  ) {
    claimed.add(afterPrimary);
  }

  return [...claimed];
}

/** Firestore update removing [tokens] from a user document, or null. */
function tokenRemovalUpdate(data, tokens, FieldValue) {
  const removeSet = new Set(tokens);
  const updates = {};
  if (removeSet.has(primaryToken(data))) {
    updates.fcmToken = FieldValue.delete();
  }
  const stored = tokenList(data).filter((token) => removeSet.has(token));
  if (stored.length > 0) {
    updates.fcmTokens = FieldValue.arrayRemove(...stored);
  }
  return Object.keys(updates).length > 0 ? updates : null;
}

module.exports = {
  claimedPushTokens,
  tokenList,
  tokenRemovalUpdate,
};
