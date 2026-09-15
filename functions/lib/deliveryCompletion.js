"use strict";

/**
 * Pure logic for markAssignedOrderDelivered's COD payment-collection gate
 * (F5 fix). Kept free of any Firestore/Admin-SDK dependency - same pattern
 * as lib/passwordReset.js - so the exact business rule ("Delivered" must
 * never leave a COD order with payment still pending) can be unit tested
 * without an emulator.
 */

const PAYMENT_METHOD_COD = "COD";
const PAYMENT_STATUS_COLLECTED = "collected";

/**
 * Whether marking this order Delivered right now would leave it in the
 * COD-delivered-but-unpaid inconsistent state F5 exists to prevent. Only
 * COD orders are gated. Bank Transfer (or any other non-COD method) may be
 * substantiated by a receipt uploaded after the final bill is updated, so
 * delivery completion must not apply the COD cash-collection gate to it.
 */
function isCodPaymentPendingForDelivery(paymentMethod, paymentStatus) {
  return paymentMethod === PAYMENT_METHOD_COD &&
    paymentStatus !== PAYMENT_STATUS_COLLECTED;
}

module.exports = {
  PAYMENT_METHOD_COD,
  PAYMENT_STATUS_COLLECTED,
  isCodPaymentPendingForDelivery,
};
