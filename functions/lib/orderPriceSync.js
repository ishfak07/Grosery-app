"use strict";

/**
 * Pure logic for propagating a changed `products/{productId}.price` onto
 * already-placed orders. Kept free of any Firestore/admin-sdk dependency so
 * it can be unit tested with the Node built-in test runner (no emulator).
 *
 * This mirrors (and must be kept in sync with) the Dart-side single source
 * of truth in lib/src/models/models.dart:
 *   - OrderModel.canApplyCurrentProductPrice
 *   - OrderModel.applyCatalogPrices
 * Dart and Cloud Functions are separate runtimes, so the rule can't be
 * shared directly — this file is the Node mirror of that same rule.
 */

// Terminal/historical order statuses. A price change must never touch an
// order once it reaches one of these — matches AppConstants.finalizedOrderStatuses
// in the Flutter app and the existing `terminalOrderStatuses` used elsewhere
// in this functions project.
const TERMINAL_ORDER_STATUSES = new Set(["Delivered", "Cancelled", "Rejected"]);

// Narrower subset of the non-terminal statuses that get a product price
// change AUTOMATICALLY (no admin action) when the admin edits a catalog
// price. Orders that have moved on to "Bill Updated" or "Out for Delivery"
// are intentionally excluded here — the admin has already finalized the
// bill / dispatched the order, so an automatic price shift underneath that
// could contradict a bill the admin just confirmed, or a COD amount a
// delivery boy is already collecting. Those orders remain reachable through
// the existing manual "Apply latest prices" admin action instead (which
// uses the broader `canApplyCurrentProductPrice` rule, not this one).
const AUTO_SYNC_ORDER_STATUSES = new Set([
  "Pending",
  "Accepted",
  "Need Clarification",
  "Shopping Started",
]);

/** True for any order that is not yet a finalized/historical record. */
function canApplyCurrentProductPrice(order) {
  return !TERMINAL_ORDER_STATUSES.has(order && order.orderStatus);
}

/** True only for the narrower pre-bill-finalization automatic-sync window. */
function isAutoSyncEligible(order) {
  return AUTO_SYNC_ORDER_STATUSES.has(order && order.orderStatus);
}

/**
 * Returns the updated order fields to write (items/cartItemsAmount/
 * subtotal/totalAmount) if [order] has a structured item for [productId]
 * whose price differs from [newPrice] and the order is within the
 * automatic-sync window, or `null` when nothing should change (ineligible
 * order, missing/blank productId, item not found, or price already
 * matches — a safe no-op either way).
 *
 * Never mutates [order]. `originalPrice` on the affected item is preserved
 * (or backfilled from its current price the first time it's synced) so the
 * price the customer originally saw is never lost.
 */
function applyCatalogPriceToOrder(order, productId, newPrice) {
  if (!order || !productId || typeof newPrice !== "number" || !Number.isFinite(newPrice)) {
    return null;
  }
  if (!isAutoSyncEligible(order)) {
    return null;
  }
  const items = Array.isArray(order.items) ? order.items : [];
  let changed = false;
  const updatedItems = items.map((item) => {
    if (!item || item.productId !== productId) {
      return item;
    }
    const currentPrice = Number(item.price) || 0;
    if (currentPrice === newPrice) {
      return item;
    }
    changed = true;
    const originalPrice =
      typeof item.originalPrice === "number" ? item.originalPrice : currentPrice;
    return Object.assign({}, item, {
      price: newPrice,
      originalPrice: originalPrice,
    });
  });
  if (!changed) {
    return null;
  }

  const cartItemsAmount = updatedItems.reduce((sum, item) => {
    const price = Number(item.price) || 0;
    const quantity = Number(item.quantity) || 0;
    return sum + price * quantity;
  }, 0);
  const photoListAmount = Number(order.photoListAmount) || 0;
  const manualListAmount = Number(order.manualListAmount) || 0;
  const deliveryCharge = Number(order.deliveryCharge) || 0;
  const serviceCharge = Number(order.serviceCharge) || 0;
  const subtotal = cartItemsAmount + photoListAmount + manualListAmount;
  const totalAmount = subtotal + deliveryCharge + serviceCharge;

  return {
    items: updatedItems,
    cartItemsAmount: cartItemsAmount,
    subtotal: subtotal,
    totalAmount: totalAmount,
  };
}

module.exports = {
  TERMINAL_ORDER_STATUSES,
  AUTO_SYNC_ORDER_STATUSES,
  canApplyCurrentProductPrice,
  isAutoSyncEligible,
  applyCatalogPriceToOrder,
};
