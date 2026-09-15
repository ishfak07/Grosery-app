"use strict";

/**
 * Pure logic for the account-deletion Cloudinary media cleanup (F4 fix).
 * Kept free of any Firestore/Admin-SDK/network dependency - same pattern as
 * lib/passwordReset.js and lib/orderPriceSync.js - so the parts that decide
 * *what* to delete and *whether a result counts as deleted* can be unit
 * tested without an emulator or real Cloudinary credentials. The actual
 * HTTP call to Cloudinary's destroy endpoint stays in index.js, alongside
 * the other Cloudinary I/O (signCloudinaryUpload).
 */

const CLOUDINARY_MAX_CLEANUP_ATTEMPTS = 5;

function isCloudinaryUrl(value) {
  return typeof value === "string" && value.includes("res.cloudinary.com/");
}

function isNonEmptyPublicId(value) {
  return typeof value === "string" && value.trim().length > 0;
}

/**
 * Walks a customer's order and support-message data (plain objects, already
 * read from Firestore - not snapshots) and collects every Cloudinary image
 * reference that belongs to that customer: the legacy single-photo/receipt
 * fields on each order, every entry in the newer per-category photoLists
 * array, and every support message's attached image.
 */
function extractCloudinaryReferences(orders, messages) {
  const urls = [];
  const publicIds = [];
  for (const order of orders || []) {
    const data = order || {};
    urls.push(data.uploadedImageUrl, data.paymentReceiptImageUrl);
    publicIds.push(data.uploadedImagePublicId, data.paymentReceiptImagePublicId);
    const photoLists = Array.isArray(data.photoLists) ? data.photoLists : [];
    for (const photoList of photoLists) {
      urls.push(photoList && photoList.imageUrl);
      publicIds.push(photoList && photoList.imagePublicId);
    }
  }
  for (const message of messages || []) {
    const data = message || {};
    urls.push(data.imageUrl);
    publicIds.push(data.imagePublicId);
  }
  return {
    imageUrls: [...new Set(urls.filter(isCloudinaryUrl))],
    publicIds: [...new Set(publicIds.filter(isNonEmptyPublicId))],
  };
}

/**
 * Whether a legacy_media_cleanup record is worth another destroy attempt:
 * there must be at least one real public id to act on (URL-only legacy
 * entries can't be safely destroyed without guessing an id from the URL),
 * and the retry cap must not already be reached.
 */
function isMediaCleanupEligible(record) {
  const data = record || {};
  const publicIds = Array.isArray(data.imagePublicIds) ? data.imagePublicIds : [];
  const attempts = Number(data.attempts || 0);
  return publicIds.filter(isNonEmptyPublicId).length > 0 &&
    attempts < CLOUDINARY_MAX_CLEANUP_ATTEMPTS;
}

/**
 * Maps one Cloudinary destroy-endpoint response to an outcome. Cloudinary
 * returns {result: "ok"} when it deleted the asset and {result: "not
 * found"} when it was already gone - both mean "this asset no longer
 * exists on Cloudinary", which is the actual goal of cleanup, not a
 * failure that should be retried forever.
 */
function interpretCloudinaryDestroyResult(httpOk, payload) {
  const result = (payload && payload.result) || "";
  if (httpOk && (result === "ok" || result === "not found")) {
    return "deleted";
  }
  return "failed";
}

module.exports = {
  CLOUDINARY_MAX_CLEANUP_ATTEMPTS,
  extractCloudinaryReferences,
  isMediaCleanupEligible,
  interpretCloudinaryDestroyResult,
};
