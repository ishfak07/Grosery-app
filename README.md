# Ishi Grocery Delivery Admin Guide

This README is for administrators who manage Ishi Grocery Delivery operations from the mobile app. It covers the admin workflow from login to daily order handling, catalog control, shop management, customer account control, password reset approvals, support, notifications, and logout.

## Admin Login

Before publishing, create a dedicated Firebase Authentication user for the
administrator and make sure the matching Firestore `users/{uid}` document has
`role: "admin"` and `isBlocked: false`. Do not reuse customer credentials or
ship a fixed administrator password in the app.

1. Open Ishi Grocery Delivery.
2. Wait for the splash screen to finish.
3. On the login screen, enter the provisioned administrator phone number.
4. Enter the administrator password configured in Firebase Authentication.
5. Tap `Login`.

After successful login, the app opens the `Admin dashboard`. If the dashboard does not open, use an account that has admin access.

## Admin Dashboard

The dashboard is the starting point for all admin work.

At the top, the dashboard shows:

- Admin greeting.
- `Notifications` button.
- `Logout` button.
- Quick access tiles.
- Order summary metrics.
- New pending orders.

Quick access tiles:

- `Orders`: review and update orders.
- `Products`: add, edit, hide, or show products.
- `Shops`: add, edit, hide, or show partner shops.
- `Customers`: block or unblock accounts.
- `Password resets`: approve or reject reset requests.
- `Account deletion`: verify and process public web deletion requests.
- `Support`: reply to support tickets.

Dashboard metrics:

- `Total orders`: all orders in the system.
- `Pending`: orders waiting for review.
- `Active work`: orders that are not delivered or cancelled.
- `Delivered`: completed delivered orders.

The `New orders` area shows the latest pending orders. Tap an order card to open its details.

## Notifications

1. From the dashboard, tap the bell icon.
2. Review admin notifications.

Admin notifications can include:

- New order received.
- New support message.
- Other operations updates.

If no notifications exist, the page shows an empty state.

## Orders

1. From the dashboard, tap `Orders`.
2. Use the filter chips at the top:
   - `All`
   - `Pending`
   - `Accepted`
   - `Out for Delivery`
   - `Delivered`
3. Tap an order card to open `Order details`.

Each order card shows:

- Customer name.
- Short order ID.
- Order date and time.
- Current order status.
- Total amount.

## Order Details

The order details page is where admin reviews payment, bill amount, fulfillment, notes, uploaded images, and contact options.

### Customer Information

The first card shows:

- Customer name.
- Order status.
- Phone number.
- Delivery address.
- Order notes, if provided.

Available actions:

- Tap `Call` to call the order phone number.
- Tap `WhatsApp` to open a WhatsApp chat with the order phone number.

### Payment Review

The `Payment` section shows:

- Payment method.
- Payment status.
- Order total.

For bank transfer orders, it also shows:

- Account name: `Ishfaque mif`
- Bank: `Bank Of Cylon (BOC)`
- Branch: `Puttalam`
- Account number: `89001476`
- Transfer receipt image, if uploaded.

Tap a receipt image to zoom and inspect it.

If no receipt was uploaded for a bank transfer order, the page shows `No transfer receipt uploaded.`

### Ordered Items

If catalog items are included, the `Items` section shows:

- Product name.
- Quantity.
- Unit price.
- Unit.
- Line total.
- Availability indicator.

### Uploaded Bill/List Image

If a bill or grocery list image is attached, the `Uploaded bill/list image` section appears.

Tap the image to zoom and review it before updating the final bill.

### Save Final Bill Amount

Use the `Bill amount` card to update the final charge.

1. Enter `Final subtotal`.
2. Enter `Delivery charge`.
3. Enter `Service charge`.
4. Select `Payment status`:
   - `pending`
   - `receipt uploaded`
   - `collected`
5. Tap `Save bill amount`.

The total is calculated from subtotal plus delivery charge plus service charge. If the order was still `Pending`, saving the bill changes the order status to `Bill Updated` and records a notification.

### Update Fulfillment

Use the `Fulfillment` card to update order progress.

1. Select `Order status`.
2. Enter `Assigned delivery person`, if known.
3. Enter `Admin notes`, if needed.
4. Tap `Update status`.

Available order statuses:

- `Pending`
- `Accepted`
- `Need Clarification`
- `Shopping Started`
- `Item Unavailable`
- `Bill Updated`
- `Out for Delivery`
- `Delivered`
- `Cancelled`
- `Rejected`

Important: an order can only be marked `Delivered` after it is already `Out for Delivery`.

Admin notes are saved on the order. Status updates also record a notification.

## Product Management

1. From the dashboard, tap `Products`.
2. Review the product list.
3. Tap the `Product` floating button to add a product.
4. Tap an existing product to edit it.
5. Use the switch on a product card to make it `Active` or `Hidden`.

Product cards show:

- Product image.
- Product name.
- Shop name.
- Price and unit.
- Stock status.
- Active or hidden switch.

A product is orderable only when it is active and its stock status is `available`.

## Add or Edit Product

Products must be linked to an active shop. If no active shop exists, add or activate a shop first.

### Product Details

1. Enter `Product name`.
2. Select `Shop`.
3. Select `Category`.
4. Enter `Description`, if needed.

Available categories:

- `Vegetables`
- `Fruits`
- `Rice & Grains`
- `Dairy`
- `Meat & Fish`
- `Bakery`
- `Beverages`
- `Household`
- `Other`

### Pricing and Stock

1. Enter `Price`.
2. Select `Unit`.
3. Select `Stock status`.

Available units:

- `kg`
- `g`
- `packet`
- `bottle`
- `piece`

Available stock statuses:

- `available`
- `unavailable`

The price must be greater than 0.

### Product Image

1. Tap `Gallery` to choose an image from the device.
2. Tap `Camera` to take a new product photo.
3. When an image is selected, the app shows `Product image selected`.
4. Tap `Save product`.

When editing a product, the old image stays unless a new image is selected.

## Shop Management

1. From the dashboard, tap `Shops`.
2. Review all shops.
3. Tap the `Shop` floating button to add a shop.
4. Tap an existing shop to edit it.
5. Use the switch on a shop card to make it `Active` or `Hidden`.

Shop cards show:

- Shop name.
- Phone number.
- Address, if saved.
- Active or hidden switch.

Active shops can be used for product linking. Hidden shops are kept in the system but are not active in the catalog.

## Add or Edit Shop

1. Open `Shops`.
2. Tap `Shop` to add a new shop, or tap an existing shop to edit it.
3. Enter `Shop name`.
4. Enter `Phone`.
   - The phone field uses `+94`.
   - Enter the 9 digits after `+94`.
   - The number must start with `7`.
5. Enter `Address`.
6. Tap `Save`.

The shop name is required. The phone number must be a valid Sri Lankan mobile number.

## Customer Account Management

1. From the dashboard, tap `Customers`.
2. Review registered accounts.
3. Use the switch beside an account to set it as `Active` or `Blocked`.

Customer cards show:

- Name.
- Phone number.
- Role.
- Active or blocked status.

The currently logged-in admin account cannot be toggled from its own switch.

Blocked accounts cannot place new orders.

## Password Reset Requests

1. From the dashboard, tap `Password resets`.
2. Review reset request cards.
3. For a pending request, tap `Approve` or `Reject`.

Each request card shows:

- Customer name or phone number.
- Phone number.
- Request date and time.
- Request status.

Possible request statuses:

- `pending`
- `approved`
- `rejected`
- `completed`

Only pending requests show the `Approve` and `Reject` buttons. When you tap either action, the button may show `Saving` until the update finishes.

## Account Deletion Requests

1. From the dashboard, tap `Account deletion`.
2. Contact the customer using the submitted phone number and verify that they
   control the account.
3. Tap `Verify & delete`, confirm verification, and wait for completion.
4. Tap `Reject` when identity cannot be verified or the request is invalid.

Deletion is blocked while the customer has an active order. Successful deletion
removes authentication and private account data, deletes Firebase Storage
uploads, and anonymizes closed order/accounting records.

## Support Tickets

1. From the dashboard, tap `Support`.
2. Review all support tickets.
3. Tap a ticket to open the conversation.

Support ticket cards show:

- Subject.
- Customer name.
- Ticket status.

Possible ticket statuses:

- `open`
- `replied`
- `closed`

## Reply to Support

1. Open a ticket from `Support tickets`.
2. Read the conversation.
3. Type a reply in the message field.
4. Tap the send button.

To attach an image:

1. Tap the image icon.
2. Choose `Gallery` or `Camera`.
3. Send the message.

To close a ticket:

1. Open the ticket.
2. Tap the close-ticket icon in the top bar.
3. The ticket status changes to `closed`.

Admin replies are saved in the ticket and record a support notification.

## Logout

1. From the dashboard, tap the logout icon in the top bar.
2. The app signs out and returns to the login screen.

## Daily Admin Workflow

1. Login as admin.
2. Check dashboard metrics and new pending orders.
3. Open each new order.
4. Review customer information and order notes.
5. Review ordered items and uploaded list images.
6. Review bank transfer receipts when applicable.
7. Save the final bill amount if prices or charges changed.
8. Update the order status as work progresses.
9. Assign a delivery person when ready.
10. Add admin notes when clarification or delivery details are needed.
11. Check support tickets and reply.
12. Review password reset requests.
13. Update products and shops when stock or availability changes.
14. Block or unblock accounts only when necessary.
15. Logout after finishing admin work.

## Common Admin Problems

### Admin Dashboard Does Not Open

Use the dedicated Firebase Authentication account whose matching Firestore
profile has `role: "admin"` and `isBlocked: false`.

### Firebase Setup Banner Appears

Backend services are not available. Login, database, functions, notifications, and image uploads may not work until the technical setup is fixed.

### No Shops When Adding Product

Add a shop first, or activate an existing hidden shop.

### Product Will Not Save

Check that a shop is selected, product name is filled, and price is greater than 0.

### Shop Will Not Save

Check that shop name is filled and the phone number is a valid Sri Lankan mobile number starting with `7`.

### Cannot Mark Order Delivered

Set the order status to `Out for Delivery` first, then update it to `Delivered`.

### Bank Transfer Receipt Missing

The payment section will show `No transfer receipt uploaded.` Review the order and update status or notes based on the situation.

### Call or WhatsApp Does Not Open

Make sure the device has a phone app, WhatsApp, and internet connection where required.

### Camera or Gallery Does Not Open

Allow camera and photo/gallery permissions on the device, then try again.

### Password Reset Buttons Are Missing

Only `pending` reset requests can be approved or rejected. Approved, rejected, or completed requests are read-only in this screen.
