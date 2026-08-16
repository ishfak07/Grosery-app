"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");

const {
  AUTO_SYNC_ORDER_STATUSES,
  TERMINAL_ORDER_STATUSES,
  canApplyCurrentProductPrice,
  isAutoSyncEligible,
  applyCatalogPriceToOrder,
} = require("../lib/orderPriceSync");

function order(overrides) {
  return Object.assign(
    {
      orderStatus: "Pending",
      items: [],
      photoListAmount: 0,
      manualListAmount: 0,
      deliveryCharge: 0,
      serviceCharge: 0,
    },
    overrides,
  );
}

function item(overrides) {
  return Object.assign(
    {productId: "p1", price: 1200, quantity: 1},
    overrides,
  );
}

test("canApplyCurrentProductPrice is true for every non-terminal status", () => {
  for (const status of [
    "Pending",
    "Accepted",
    "Need Clarification",
    "Shopping Started",
    "Bill Updated",
    "Out for Delivery",
  ]) {
    assert.equal(canApplyCurrentProductPrice(order({orderStatus: status})), true, status);
  }
});

test("canApplyCurrentProductPrice is false for Delivered/Cancelled/Rejected", () => {
  for (const status of TERMINAL_ORDER_STATUSES) {
    assert.equal(canApplyCurrentProductPrice(order({orderStatus: status})), false, status);
  }
});

test("isAutoSyncEligible only covers the pre-bill-finalization statuses", () => {
  for (const status of AUTO_SYNC_ORDER_STATUSES) {
    assert.equal(isAutoSyncEligible(order({orderStatus: status})), true, status);
  }
  for (const status of ["Bill Updated", "Out for Delivery", ...TERMINAL_ORDER_STATUSES]) {
    assert.equal(isAutoSyncEligible(order({orderStatus: status})), false, status);
  }
});

test("active order: price change propagates and totals recalculate", () => {
  const activeOrder = order({
    orderStatus: "Accepted",
    items: [item({productId: "p1", price: 1200, quantity: 2})],
    deliveryCharge: 250,
  });

  const result = applyCatalogPriceToOrder(activeOrder, "p1", 1300);

  assert.ok(result);
  assert.equal(result.items[0].price, 1300);
  assert.equal(result.items[0].originalPrice, 1200);
  assert.equal(result.cartItemsAmount, 2600);
  assert.equal(result.subtotal, 2600);
  assert.equal(result.totalAmount, 2850);
});

test("quantity math: 2 x 1200 (2400) becomes 2 x 1300 (2600)", () => {
  const activeOrder = order({
    orderStatus: "Shopping Started",
    items: [item({productId: "p1", price: 1200, quantity: 2})],
  });

  const result = applyCatalogPriceToOrder(activeOrder, "p1", 1300);

  assert.equal(result.items[0].price * result.items[0].quantity, 2600);
  assert.equal(result.subtotal, 2600);
});

test("originalPrice is preserved (backfilled once, never overwritten again)", () => {
  const firstSync = applyCatalogPriceToOrder(
    order({
      orderStatus: "Pending",
      items: [item({productId: "p1", price: 1200, quantity: 1})],
    }),
    "p1",
    1300,
  );
  assert.equal(firstSync.items[0].originalPrice, 1200);

  // A second, later price change re-applies on top of the already-synced
  // order (as read fresh from Firestore) — originalPrice must still read
  // back as the very first price the customer saw, not the intermediate one.
  const secondSync = applyCatalogPriceToOrder(
    order({
      orderStatus: "Pending",
      items: [
        {productId: "p1", price: 1300, originalPrice: 1200, quantity: 1},
      ],
    }),
    "p1",
    1450,
  );
  assert.equal(secondSync.items[0].price, 1450);
  assert.equal(secondSync.items[0].originalPrice, 1200);
});

test("Delivered/Cancelled/Rejected orders are never touched", () => {
  for (const status of TERMINAL_ORDER_STATUSES) {
    const historicalOrder = order({
      orderStatus: status,
      items: [item({productId: "p1", price: 1200, quantity: 2})],
    });

    const result = applyCatalogPriceToOrder(historicalOrder, "p1", 1300);

    assert.equal(result, null, status);
  }
});

test("a delivered order's stored total is unaffected by a later catalog change", () => {
  const deliveredOrder = order({
    orderStatus: "Delivered",
    items: [item({productId: "p1", price: 1200, quantity: 2})],
    deliveryCharge: 250,
  });

  const result = applyCatalogPriceToOrder(deliveredOrder, "p1", 1300);

  assert.equal(result, null);
  assert.equal(deliveredOrder.items[0].price, 1200);
});

test("Bill Updated and Out for Delivery orders are not auto-synced (manual-only)", () => {
  for (const status of ["Bill Updated", "Out for Delivery"]) {
    const dispatchedOrder = order({
      orderStatus: status,
      items: [item({productId: "p1", price: 1200, quantity: 1})],
    });

    const result = applyCatalogPriceToOrder(dispatchedOrder, "p1", 1300);

    assert.equal(result, null, status);
  }
});

test("an order without the changed product id is untouched", () => {
  const unrelatedOrder = order({
    orderStatus: "Pending",
    items: [item({productId: "other-product", price: 500, quantity: 1})],
  });

  const result = applyCatalogPriceToOrder(unrelatedOrder, "p1", 1300);

  assert.equal(result, null);
});

test("a catalog price equal to the current price is a no-op", () => {
  const activeOrder = order({
    orderStatus: "Pending",
    items: [item({productId: "p1", price: 1200, quantity: 1})],
  });

  assert.equal(applyCatalogPriceToOrder(activeOrder, "p1", 1200), null);
});

test("only the matching item is updated; a sibling item is left alone", () => {
  const activeOrder = order({
    orderStatus: "Pending",
    items: [
      item({productId: "p1", price: 1200, quantity: 1}),
      item({productId: "p2", price: 400, quantity: 3}),
    ],
  });

  const result = applyCatalogPriceToOrder(activeOrder, "p1", 1300);

  const p1 = result.items.find((entry) => entry.productId === "p1");
  const p2 = result.items.find((entry) => entry.productId === "p2");
  assert.equal(p1.price, 1300);
  assert.equal(p2.price, 400);
  assert.equal(result.cartItemsAmount, 1300 + 400 * 3);
});

test("two eligible active orders containing the same product both update "
  + "independently and correctly", () => {
  const orderA = order({
    orderStatus: "Pending",
    items: [item({productId: "p1", price: 1200, quantity: 1})],
  });
  const orderB = order({
    orderStatus: "Accepted",
    items: [item({productId: "p1", price: 1200, quantity: 3})],
  });

  const resultA = applyCatalogPriceToOrder(orderA, "p1", 1300);
  const resultB = applyCatalogPriceToOrder(orderB, "p1", 1300);

  assert.equal(resultA.cartItemsAmount, 1300);
  assert.equal(resultB.cartItemsAmount, 3900);
});

test("photo/manual-list amounts (no productId) are carried through, never "
  + "reinterpreted as a structured item", () => {
  const mixedOrder = order({
    orderStatus: "Pending",
    items: [item({productId: "p1", price: 1200, quantity: 1})],
    photoListAmount: 300,
    manualListAmount: 150,
    deliveryCharge: 250,
    serviceCharge: 50,
  });

  const result = applyCatalogPriceToOrder(mixedOrder, "p1", 1300);

  assert.equal(result.subtotal, 1300 + 300 + 150);
  assert.equal(result.totalAmount, 1300 + 300 + 150 + 250 + 50);
});

test("an item without a productId (e.g. a legacy/free-text line) never "
  + "matches and is left untouched", () => {
  const activeOrder = order({
    orderStatus: "Pending",
    items: [{price: 500, quantity: 1}],
  });

  const result = applyCatalogPriceToOrder(activeOrder, "p1", 1300);

  assert.equal(result, null);
});
