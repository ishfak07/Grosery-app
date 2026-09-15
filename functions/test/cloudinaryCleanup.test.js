"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");

const {
  CLOUDINARY_MAX_CLEANUP_ATTEMPTS,
  extractCloudinaryReferences,
  isMediaCleanupEligible,
  interpretCloudinaryDestroyResult,
} = require("../lib/cloudinaryCleanup");

test("extractCloudinaryReferences collects legacy single-image order fields", () => {
  const orders = [
    {
      uploadedImageUrl: "https://res.cloudinary.com/demo/image/upload/v1/a.jpg",
      uploadedImagePublicId: "puttalam-drop/user_uploads/u1/orders/o1/list",
      paymentReceiptImageUrl: "https://res.cloudinary.com/demo/image/upload/v1/b.jpg",
      paymentReceiptImagePublicId: "puttalam-drop/user_uploads/u1/orders/o1/receipt",
    },
  ];
  const result = extractCloudinaryReferences(orders, []);
  assert.equal(result.publicIds.length, 2);
  assert.equal(result.imageUrls.length, 2);
  assert.ok(result.publicIds.includes("puttalam-drop/user_uploads/u1/orders/o1/list"));
  assert.ok(result.publicIds.includes("puttalam-drop/user_uploads/u1/orders/o1/receipt"));
});

test("extractCloudinaryReferences also walks the newer per-category photoLists array", () => {
  const orders = [
    {
      photoLists: [
        {
          category: "Groceries",
          imageUrl: "https://res.cloudinary.com/demo/image/upload/v1/g.jpg",
          imagePublicId: "puttalam-drop/user_uploads/u1/orders/o2/groceries",
        },
        {
          category: "Household",
          imageUrl: "https://res.cloudinary.com/demo/image/upload/v1/h.jpg",
          imagePublicId: "puttalam-drop/user_uploads/u1/orders/o2/household",
        },
      ],
    },
  ];
  const result = extractCloudinaryReferences(orders, []);
  assert.equal(result.publicIds.length, 2);
  assert.ok(result.publicIds.includes("puttalam-drop/user_uploads/u1/orders/o2/groceries"));
  assert.ok(result.publicIds.includes("puttalam-drop/user_uploads/u1/orders/o2/household"));
});

test("extractCloudinaryReferences collects support message images", () => {
  const messages = [
    {imageUrl: "https://res.cloudinary.com/demo/image/upload/v1/m.jpg", imagePublicId: "puttalam-drop/support/t1/u1/msg"},
  ];
  const result = extractCloudinaryReferences([], messages);
  assert.deepEqual(result.publicIds, ["puttalam-drop/support/t1/u1/msg"]);
});

test("extractCloudinaryReferences ignores empty/missing fields and de-dupes", () => {
  const orders = [
    {uploadedImageUrl: "", uploadedImagePublicId: null, photoLists: []},
    {photoLists: [{imageUrl: undefined, imagePublicId: "  "}]},
  ];
  const result = extractCloudinaryReferences(orders, [null, undefined]);
  assert.deepEqual(result.publicIds, []);
  assert.deepEqual(result.imageUrls, []);
});

test("extractCloudinaryReferences ignores non-Cloudinary URLs (e.g. legacy Firebase Storage links)", () => {
  const orders = [
    {uploadedImageUrl: "https://firebasestorage.googleapis.com/v0/b/app/o/x.jpg"},
  ];
  const result = extractCloudinaryReferences(orders, []);
  assert.deepEqual(result.imageUrls, []);
});

test("extractCloudinaryReferences de-duplicates a public id referenced twice", () => {
  const sharedId = "puttalam-drop/user_uploads/u1/orders/o1/list";
  const orders = [
    {uploadedImagePublicId: sharedId},
    {photoLists: [{imagePublicId: sharedId}]},
  ];
  const result = extractCloudinaryReferences(orders, []);
  assert.deepEqual(result.publicIds, [sharedId]);
});

test("isMediaCleanupEligible requires at least one real public id", () => {
  assert.equal(isMediaCleanupEligible({imagePublicIds: [], attempts: 0}), false);
  assert.equal(isMediaCleanupEligible({imagePublicIds: ["  "], attempts: 0}), false);
  assert.equal(isMediaCleanupEligible({imagePublicIds: ["abc"], attempts: 0}), true);
});

test("isMediaCleanupEligible stops retrying once the attempt cap is reached", () => {
  assert.equal(
    isMediaCleanupEligible({imagePublicIds: ["abc"], attempts: CLOUDINARY_MAX_CLEANUP_ATTEMPTS - 1}),
    true,
  );
  assert.equal(
    isMediaCleanupEligible({imagePublicIds: ["abc"], attempts: CLOUDINARY_MAX_CLEANUP_ATTEMPTS}),
    false,
  );
  assert.equal(
    isMediaCleanupEligible({imagePublicIds: ["abc"], attempts: CLOUDINARY_MAX_CLEANUP_ATTEMPTS + 3}),
    false,
  );
});

test("interpretCloudinaryDestroyResult treats a successful destroy as deleted", () => {
  assert.equal(interpretCloudinaryDestroyResult(true, {result: "ok"}), "deleted");
});

test("interpretCloudinaryDestroyResult treats an already-missing asset as deleted, not failed", () => {
  assert.equal(interpretCloudinaryDestroyResult(true, {result: "not found"}), "deleted");
});

test("interpretCloudinaryDestroyResult treats any other response as failed (to be retried)", () => {
  assert.equal(interpretCloudinaryDestroyResult(false, {}), "failed");
  assert.equal(interpretCloudinaryDestroyResult(true, {result: "error"}), "failed");
  assert.equal(interpretCloudinaryDestroyResult(false, {result: "ok"}), "failed");
});
