# Puttalam Drop Full Testing Guide

Use this guide to test the app step by step. Test all 3 roles:

- Customer/user
- Delivery boy
- Admin

Mark every item as:

- PASS: working correctly
- FAIL: not working
- NA: cannot test

When something fails, take a screenshot and write:

- Which phone/account was used
- What button was tapped
- What you expected
- What actually happened
- Date and time

## 1. Test Accounts

Fill these before giving the guide to the tester.

| Role | Phone number | Password | Notes |
| --- | --- | --- | --- |
| Customer/user |  |  | Use for normal ordering |
| Admin |  |  | Must open Admin dashboard |
| Delivery boy |  |  | Can be created by admin in Delivery boys |

Important:

- Use only test accounts and test orders.
- Do not delete a real customer account.
- Do not block a real customer account.
- Do not use real bank payments. Use test receipt screenshots only.

## 2. Device Setup

1. Install the app.
2. Connect the phone to the internet.
3. Open the app.
4. Allow notification permission if asked.
5. Allow camera/gallery permission when testing image upload.
6. Make sure WhatsApp and phone calling are available if testing those buttons.

Expected result:

- App opens without crashing.
- Splash screen finishes.
- Login screen or onboarding screen appears.

## 3. Basic App Test

1. Open the app.
2. Change language to English.
3. Change language to Tamil.
4. Go back to English if needed.
5. Close the app.
6. Open it again.

Expected result:

- App opens correctly every time.
- Language button works.
- No blank screen.
- No endless loading.

## 4. Customer/User Testing

### 4.1 Create Customer Account

1. Open the app.
2. Tap Create account.
3. Enter a valid Sri Lankan phone number.
4. Enter password.
5. Enter full name.
6. Enter delivery address.
7. Complete registration.

Expected result:

- Account is created.
- Customer home page opens.
- Customer does not see admin pages.
- Customer does not see delivery-boy dashboard.

PASS/FAIL: 

### 4.2 Customer Login and Logout

1. Logout from Profile.
2. Login again with the customer phone and password.

Expected result:

- Login succeeds.
- Customer home page opens.
- Profile shows the correct customer name, phone, and address.

PASS/FAIL: 

### 4.3 Forgot Password Request

1. Logout.
2. Tap Forgot password.
3. Enter the customer phone number.
4. Submit the request.

Expected result:

- Password reset request is created.
- App shows a success message or next instruction.
- Admin can see the request later in Password resets.

PASS/FAIL: 

### 4.4 Home Page and Product Browsing

1. Login as customer.
2. Check Home page.
3. Check offers/banner area.
4. Search for a product.
5. Open a product.
6. Add product to cart.

Expected result:

- Products load.
- Search works.
- Product details open.
- Add to cart works.
- Cart icon/count updates.

PASS/FAIL: 

### 4.5 Cart Test

1. Open Cart.
2. Increase product quantity.
3. Decrease product quantity.
4. Remove one item if possible.
5. Add another product again.

Expected result:

- Quantity changes correctly.
- Price total changes correctly.
- Removed item disappears.
- Checkout button is enabled when cart/list has items.

PASS/FAIL: 

### 4.6 Cash on Delivery Order

1. Add at least one product to cart.
2. Open Cart.
3. Tap Checkout.
4. Select Cash on Delivery.
5. Confirm customer name.
6. Confirm delivery address.
7. Place order.

Expected result:

- Order is created.
- Success screen appears.
- Track order button opens order tracking.
- New order appears in customer Orders.
- Admin receives/sees the new order.

PASS/FAIL: 

### 4.7 Bank Transfer Order

1. Add at least one product to cart.
2. Open Checkout.
3. Select Bank transfer.
4. Check bank details are visible.
5. Try placing order without receipt.
6. Upload a test receipt image.
7. Place order.

Expected result:

- Without receipt, app asks to upload receipt.
- After receipt upload, order is created.
- Receipt image is visible to admin in Order details.

PASS/FAIL: 

### 4.8 Upload Shopping List Photo

1. From Home or Cart, open Upload list.
2. Choose Gallery or Camera.
3. Select/take a clear test shopping-list photo.
4. Continue to Checkout.
5. Place order.

Expected result:

- Image uploads successfully.
- Checkout allows the uploaded-list order.
- Admin can see the uploaded list image in Order details.

PASS/FAIL: 

### 4.9 Manual List Order

1. From Home or Cart, open Manual list.
2. Type items, for example:
   - Rice 5kg
   - Milk 2 packets
   - Onion 1kg
3. Save/continue to Checkout.
4. Place order.

Expected result:

- Manual list is saved.
- Checkout shows the typed list.
- Admin can see the typed list in Order details.

PASS/FAIL: 

### 4.10 Customer Order Tracking

1. Open Orders.
2. Open the newest order.
3. Check order status timeline.
4. Ask admin to update statuses:
   - Accepted
   - Shopping Started
   - Bill Updated
   - Out for Delivery
   - Delivered

Expected result:

- Customer sees updated status.
- After Bill Updated, final bill breakdown is visible.
- After Out for Delivery, delivery-boy name/phone are visible.
- After Delivered, customer can rate the delivery.

PASS/FAIL: 

### 4.11 Customer Delivery Rating

1. Wait until the order is Delivered.
2. Open the delivered order.
3. Tap Rate delivery.
4. Choose stars.
5. Add optional review text.
6. Save.
7. Open the order again.

Expected result:

- Review saves successfully.
- Stars and review text are visible.
- Delivery boy can see the review in his delivery history.

PASS/FAIL: 

### 4.12 Customer Support

1. Open Support.
2. Create a support ticket.
3. Add subject and message.
4. Send.
5. Open the ticket.
6. Send another message.
7. Attach an image if possible.

Expected result:

- Ticket is created.
- Messages appear in correct order.
- Image uploads if selected.
- Admin can see and reply to the ticket.

PASS/FAIL: 

### 4.13 Customer Notifications

1. Open Notifications from customer home.
2. Check current notifications.
3. Ask admin to update an order or send broadcast.
4. Reopen Notifications.

Expected result:

- New notifications appear.
- Old unrelated notifications from before account creation should not appear for a new customer.
- No duplicate same notification should appear many times.

PASS/FAIL: 

### 4.14 Customer Profile

1. Open Profile.
2. Edit full name.
3. Edit delivery address.
4. Save.
5. Logout and login again.

Expected result:

- Profile updates save correctly.
- Updated name/address remain after login.
- Privacy policy link opens.
- Delete account option is visible but do not delete real accounts.

PASS/FAIL: 

## 5. Admin Testing

### 5.1 Admin Login

1. Logout from any current account.
2. Login using admin phone and password.

Expected result:

- Admin dashboard opens.
- Admin does not see customer home page.
- Admin does not see delivery-boy dashboard.

PASS/FAIL: 

### 5.2 Admin Dashboard

1. Check dashboard cards and counts.
2. Open Notifications.
3. Return to dashboard.

Expected result:

- Counts load.
- New orders area loads.
- Notifications screen opens.

PASS/FAIL: 

### 5.3 Shop Management

1. Open Shops.
2. Add a new test shop.
3. Enter shop name.
4. Enter valid phone number.
5. Enter address.
6. Save.
7. Edit the shop.
8. Hide/deactivate the shop.
9. Activate it again.

Expected result:

- Shop saves.
- Shop edits save.
- Active/hidden switch works.
- Active shop can be selected when adding products.

PASS/FAIL: 

### 5.4 Product Management

1. Open Products.
2. Add a new test product.
3. Select active shop.
4. Select category.
5. Enter price and unit.
6. Add product image from Gallery or Camera.
7. Save.
8. Edit product price/name.
9. Change stock status to unavailable.
10. Change it back to available.
11. Hide/deactivate product.
12. Activate it again.

Expected result:

- Product saves and appears.
- Product image loads.
- Customer can order only active and available products.
- Hidden/unavailable product is not orderable.

PASS/FAIL: 

### 5.5 Offers/Banners

1. Open Offers if available on admin dashboard.
2. Add test offer/banner.
3. Add title, caption, and image.
4. Save.
5. Login as customer and check Home page.
6. Deactivate the offer.

Expected result:

- Active offer appears on customer home page.
- Inactive offer does not show to customer.

PASS/FAIL: 

### 5.6 Checkout Charges and Payment Settings

1. Open checkout/payment settings.
2. Change delivery charge.
3. Change service charge.
4. Turn Cash on Delivery off and save.
5. Login as customer and check Checkout.
6. Turn Cash on Delivery on again.
7. Turn Bank transfer off and save.
8. Login as customer and check Checkout.
9. Turn Bank transfer on again.

Expected result:

- Charges save.
- Customer checkout total uses new charges.
- Disabled payment method cannot be selected by customer.
- Enabled payment method becomes available again.

PASS/FAIL: 

### 5.7 Admin Order List

1. Open Orders.
2. Test filters:
   - All
   - Pending
   - Accepted
   - Out for Delivery
   - Delivered
3. Search for an order by customer/order text.
4. Open an order.

Expected result:

- Orders load.
- Filters work.
- Search works.
- Order details opens.

PASS/FAIL: 

### 5.8 Admin Order Details

1. Open a customer order.
2. Check customer name, phone, address.
3. Tap Call.
4. Tap WhatsApp.
5. Check Payment section.
6. Check ordered items.
7. Check uploaded list image if this order has one.
8. Check manual list if this order has one.
9. Tap View shop order sheet.
10. Download PDF.
11. Send PDF if possible.

Expected result:

- All order details are correct.
- Call/WhatsApp open the correct number.
- Receipt/list images open zoom view.
- Shop order sheet shows all cart items, uploaded image/list, and manual list.
- PDF download/share works.

PASS/FAIL: 

### 5.9 Save Final Bill

1. Open an order with cart/list items.
2. Enter final cart amount.
3. Enter photo list amount if needed.
4. Enter manual list amount if needed.
5. Enter delivery charge.
6. Enter service charge.
7. Select payment status:
   - pending
   - receipt uploaded
   - collected
8. Tap Save bill amount.
9. Login as customer and open the order.

Expected result:

- Bill saves.
- If order was Pending, status changes to Bill Updated.
- Customer sees final bill breakdown after Bill Updated.
- Customer receives notification.

PASS/FAIL: 

### 5.10 Update Order Status

1. Open Order details.
2. Change status to Accepted.
3. Tap Update status.
4. Change status to Shopping Started.
5. Tap Update status.
6. Change status to Bill Updated.
7. Tap Update status.

Expected result:

- Status updates save.
- Customer tracking changes.
- Notifications are created.

PASS/FAIL: 

### 5.11 Delivery Boy Assignment

1. Make sure at least one active delivery-boy account exists.
2. Open Order details.
3. Select status Out for Delivery.
4. Try Update status without selecting delivery boy.
5. Select delivery boy.
6. Tap Update status.
7. Login as customer and open tracking.
8. Login as delivery boy.

Expected result:

- App does not allow Out for Delivery without delivery-boy selection.
- After selecting delivery boy, status saves.
- Customer sees delivery-boy name/phone.
- Assigned order appears on delivery-boy dashboard.

PASS/FAIL: 

### 5.12 Delivered Status

1. With the order already Out for Delivery, login as assigned delivery boy.
2. Tap Delivered on the assigned order.
3. Login as customer and check order.
4. Login as admin and check order.

Expected result:

- Delivery boy can mark only Out for Delivery orders as Delivered.
- Order status becomes Delivered.
- Customer can rate delivery.
- Delivery boy reward stars increase.

PASS/FAIL: 

### 5.13 Admin Broadcast Notification

1. Login as admin.
2. Open Broadcast/Notifications message screen if available.
3. Enter title and message.
4. Send to active customers.
5. Login as customer.
6. Open Notifications.

Expected result:

- Broadcast sends successfully.
- Active customer receives notification.
- No duplicate notification spam.

PASS/FAIL: 

### 5.14 Customer Management

1. Open Customers.
2. Search/find the test customer.
3. Block the test customer.
4. Try to login/place order as that customer.
5. Unblock the customer.
6. Login/place order again.

Expected result:

- Blocked customer cannot use normal customer features.
- Unblocked customer can use the app again.
- Admin cannot accidentally block its own admin account.

PASS/FAIL: 

### 5.15 Password Reset Requests

1. Create forgot-password request from customer app.
2. Login as admin.
3. Open Password resets.
4. Approve the request.
5. Test reset flow as customer if the app asks for new password.
6. Create another request and reject it.

Expected result:

- Pending request appears.
- Approve works.
- Reject works.
- Completed/rejected requests do not show wrong action buttons.

PASS/FAIL: 

### 5.16 Account Deletion Requests

1. Use only a test customer.
2. Submit account deletion request from public web page or app option if available.
3. Login as admin.
4. Open Account deletion.
5. Check pending request.
6. If the customer has active orders, try deleting.
7. Complete or reject only for test account.

Expected result:

- Request appears.
- Active orders block deletion.
- Verified test deletion completes correctly.
- Rejected request changes status.

PASS/FAIL: 

## 6. Delivery Boy Testing

### 6.1 Create Delivery Boy Account

Admin steps:

1. Login as admin.
2. Open Delivery boys.
3. Tap add/create.
4. Enter delivery-boy name.
5. Enter phone number.
6. Enter password.
7. Save.

Expected result:

- Delivery-boy account is created.
- Account appears in Delivery boys list.
- Account status is active.

PASS/FAIL: 

### 6.2 Delivery Boy Login

1. Logout from admin.
2. Login using delivery-boy phone and password.

Expected result:

- Delivery dashboard opens.
- Delivery boy does not see admin dashboard.
- Delivery boy does not see customer shopping home.

PASS/FAIL: 

### 6.3 No Assigned Orders

1. Login as delivery boy before assigning any order.

Expected result:

- Dashboard shows no active deliveries or assigned orders.
- App does not crash.

PASS/FAIL: 

### 6.4 Assigned Order Appears

1. Login as admin.
2. Open an order.
3. Set status to Out for Delivery.
4. Select this delivery boy.
5. Save.
6. Login as delivery boy.

Expected result:

- Assigned order appears.
- Customer name, phone, address, payment method, amount, admin notes, and items are visible.
- Call customer button works.

PASS/FAIL: 

### 6.5 Mark Delivered

1. Login as assigned delivery boy.
2. Open active assigned order.
3. Tap Delivered.
4. Confirm if asked.

Expected result:

- Order is marked Delivered.
- Order moves to delivery history.
- Customer and admin see Delivered status.
- Reward stars increase by 100 for completed delivery.

PASS/FAIL: 

### 6.6 Delivery History and Reviews

1. Login as customer.
2. Rate the delivered order.
3. Login as delivery boy.
4. Open History or All assigned orders.

Expected result:

- Delivered order appears in history.
- Customer review and star rating are visible.
- Dashboard metrics update.

PASS/FAIL: 

### 6.7 Delivery Reward Stars

1. Login as delivery boy.
2. Check reward card.
3. Complete one delivery.
4. Check reward stars again.
5. Login as admin.
6. Open Delivery boys.
7. Check same delivery boy reward stars.

Expected result:

- One delivered order adds 100 stars.
- Admin sees same star total.
- Reward progress is correct.

PASS/FAIL: 

### 6.8 Admin Reward Payment

1. Login as admin.
2. Open Delivery boys.
3. Open the test delivery boy.
4. Tap Pay from stars.
5. Enter payment amount.
6. Save.
7. Login as delivery boy and check stars.

Expected result:

- Payment cannot be more than available stars.
- Payment reduces star balance.
- Paid count/total paid LKR updates.

PASS/FAIL: 

### 6.9 Edit Delivery Boy Account

1. Login as admin.
2. Open Delivery boys.
3. Edit test delivery boy.
4. Change name.
5. Change phone if needed.
6. Set new password if needed.
7. Save.
8. Login with updated details.

Expected result:

- Only admin can edit delivery-boy name, phone, password, and active status.
- Updated login works.
- Old password should not work if password was changed.

PASS/FAIL: 

### 6.10 Inactive Delivery Boy

1. Login as admin.
2. Open Delivery boys.
3. Set test delivery boy inactive/blocked.
4. Try login as delivery boy.
5. Try assigning an order to inactive delivery boy.
6. Activate delivery boy again.

Expected result:

- Inactive delivery boy cannot use normal dashboard.
- Inactive delivery boy should not be selectable for new Out for Delivery assignment.
- After activation, login and assignment work again.

PASS/FAIL: 

## 7. Full End-to-End Test

Do this final test from start to finish.

1. Customer logs in.
2. Customer adds product to cart.
3. Customer adds manual list or uploaded list.
4. Customer places order with Cash on Delivery.
5. Admin logs in.
6. Admin opens new order.
7. Admin reviews items/list.
8. Admin taps View shop order sheet.
9. Admin saves final bill amount.
10. Admin changes status to Accepted.
11. Admin changes status to Shopping Started.
12. Admin changes status to Out for Delivery and selects delivery boy.
13. Customer checks tracking and sees delivery-boy details.
14. Delivery boy logs in.
15. Delivery boy sees assigned order.
16. Delivery boy taps Delivered.
17. Customer opens delivered order.
18. Customer rates delivery.
19. Delivery boy checks review and reward stars.
20. Admin checks order is Delivered.

Expected result:

- Whole flow works without crash.
- Correct screens open for each role.
- Order status is correct for customer, admin, and delivery boy.
- Notifications are not duplicated.
- Delivery-boy reward stars increase.

PASS/FAIL: 

## 8. Offline and Error Testing

1. Open app with internet on.
2. Turn internet off.
3. Try to browse products.
4. Try to place order.
5. Turn internet on again.
6. Refresh/reopen app.

Expected result:

- App shows friendly offline/error message.
- App does not crash.
- App works again when internet returns.

PASS/FAIL: 

## 9. Permission Testing

Test these permissions:

- Camera
- Gallery/photos
- Notifications
- Phone call
- WhatsApp opening

Expected result:

- App asks permission when needed.
- If permission is denied, app shows useful message.
- If permission is allowed, feature works.

PASS/FAIL: 

## 10. Final Tester Report

Fill this after testing.

| Area | PASS/FAIL | Notes |
| --- | --- | --- |
| Install/open app |  |  |
| Customer login/register |  |  |
| Customer product order |  |  |
| Customer uploaded/manual list order |  |  |
| Customer bank transfer order |  |  |
| Customer tracking |  |  |
| Customer support |  |  |
| Customer notifications |  |  |
| Customer delivery rating |  |  |
| Admin login/dashboard |  |  |
| Admin shops/products/offers |  |  |
| Admin order handling |  |  |
| Admin bill update |  |  |
| Admin delivery-boy assignment |  |  |
| Admin customers/password reset/deletion |  |  |
| Delivery-boy login/dashboard |  |  |
| Delivery-boy delivered flow |  |  |
| Delivery-boy rewards |  |  |
| Offline/error handling |  |  |
| Permissions |  |  |

## 11. Bug Report Format

Copy this format for every problem.

```text
Bug title:
Role used: Customer / Admin / Delivery boy
Phone/account used:
Date and time:
Screen:
Steps:
1.
2.
3.
Expected result:
Actual result:
Screenshot/video attached: Yes / No
Internet connection: Wi-Fi / Mobile data
Device model:
Android/iOS version:
```

## 12. Final Decision

After all tests:

- If all important areas are PASS, app is ready for next release check.
- If any payment, order, login, assignment, delivery, notification, or account-delete test is FAIL, fix it before release.
- If only small text/design issues fail, write them separately and decide priority.
