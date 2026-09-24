const test = require("node:test");
const assert = require("node:assert/strict");
const {
  claimedPushTokens,
  tokenRemovalUpdate,
} = require("../lib/pushTokens");

const fakeFieldValue = {
  delete: () => "DELETE",
  arrayRemove: (...items) => ({arrayRemove: items}),
};

test("first login claims the saved token", () => {
  assert.deepEqual(
    claimedPushTokens(
      {role: "user"},
      {fcmToken: "t1", fcmTokens: ["t1"], fcmTokenUpdatedAt: 1},
    ),
    ["t1"],
  );
});

test("re-login with an already stored token claims it again", () => {
  assert.deepEqual(
    claimedPushTokens(
      {fcmToken: "t1", fcmTokens: ["t1"], fcmTokenUpdatedAt: 1},
      {fcmToken: "t1", fcmTokens: ["t1"], fcmTokenUpdatedAt: 2},
    ),
    ["t1"],
  );
});

test("logout cleanup claims nothing", () => {
  assert.deepEqual(
    claimedPushTokens(
      {fcmToken: "t1", fcmTokens: ["t0", "t1"], fcmTokenUpdatedAt: 1},
      {fcmTokens: ["t0"], fcmTokenUpdatedAt: 2},
    ),
    [],
  );
  assert.deepEqual(
    claimedPushTokens(
      {fcmToken: "t1", fcmTokens: ["t0", "t1"], fcmTokenUpdatedAt: 1},
      {fcmToken: "t1", fcmTokens: ["t1"], fcmTokenUpdatedAt: 2},
    ),
    [],
  );
});

test("unrelated profile edits claim nothing", () => {
  assert.deepEqual(
    claimedPushTokens(
      {fullName: "A", fcmToken: "t1", fcmTokens: ["t1"], fcmTokenUpdatedAt: 1},
      {fullName: "B", fcmToken: "t1", fcmTokens: ["t1"], fcmTokenUpdatedAt: 1},
    ),
    [],
  );
});

test("deleted user document claims nothing", () => {
  assert.deepEqual(claimedPushTokens({fcmToken: "t1"}, undefined), []);
});

test("removal update only touches matching tokens", () => {
  assert.deepEqual(
    tokenRemovalUpdate(
      {fcmToken: "t1", fcmTokens: ["t1", "t2"]},
      ["t1"],
      fakeFieldValue,
    ),
    {fcmToken: "DELETE", fcmTokens: {arrayRemove: ["t1"]}},
  );
  assert.equal(
    tokenRemovalUpdate({fcmToken: "t3", fcmTokens: ["t3"]}, ["t1"],
      fakeFieldValue),
    null,
  );
});
