"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");

const {
  PAYMENT_METHOD_COD,
  PAYMENT_STATUS_COLLECTED,
  isCodPaymentPendingForDelivery,
} = require("../lib/deliveryCompletion");

test("a COD order with payment still pending blocks delivery", () => {
  assert.equal(isCodPaymentPendingForDelivery(PAYMENT_METHOD_COD, "pending"), true);
});

test("a COD order with payment collected allows delivery", () => {
  assert.equal(
    isCodPaymentPendingForDelivery(PAYMENT_METHOD_COD, PAYMENT_STATUS_COLLECTED),
    false,
  );
});

test("a Bank Transfer order is never blocked by the COD collection gate", () => {
  assert.equal(isCodPaymentPendingForDelivery("Bank Transfer", "pending"), false);
  assert.equal(isCodPaymentPendingForDelivery("Bank Transfer", "receipt uploaded"), false);
  assert.equal(isCodPaymentPendingForDelivery("Bank Transfer", "collected"), false);
});

test("an unknown/legacy payment method is treated like any non-COD method (not blocked)", () => {
  assert.equal(isCodPaymentPendingForDelivery("", "pending"), false);
  assert.equal(isCodPaymentPendingForDelivery(undefined, "pending"), false);
});
