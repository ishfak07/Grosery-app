# Store Data Disclosures

Use this file when completing Google Play Console and App Store Connect for
`Puttalam Drop` (`com.ishi.grocerydelivery`). Recheck it whenever an SDK or data
flow changes.

## Public URLs

- Privacy policy: `https://whatsconnect.sbs/privacy-policy/`
- Account deletion: `https://grocery-delivery-app-388bc.web.app/delete-account`

## Google Play Data Safety

### Overview

- Does the app collect or share required user data? `Yes`
- Is all collected user data encrypted in transit? `Yes`
- Can users request deletion? `Yes`
- Data shared with third parties for their independent purposes: `No`

Firebase and Cloudinary act as service providers. Do not mark service-provider
transfers as sharing unless the production business uses the data for another
third party's independent purpose.

### Collected Data

| Play data type | Collected | Required or optional | Purpose |
| --- | --- | --- | --- |
| Personal info - Name | Yes | Required for an account/order | App functionality, account management |
| Personal info - Phone number | Yes | Required | Authentication, order fulfilment, support |
| Personal info - Address | Yes | Required for delivery | App functionality |
| Financial info - Payment info | Yes | Optional unless bank transfer is selected | Payment processing and fraud prevention |
| Photos and videos - Photos | Yes | Optional | Shopping-list images, receipts, support attachments |
| Messages - Other in-app messages | Yes | Optional | Customer support |
| App activity - Other user-generated content | Yes | Optional | Typed shopping lists, notes, delivery reviews |
| App activity - Purchase history | Yes | Required when placing an order | Order fulfilment, accounting |
| Device or other IDs | Yes | Optional | Firebase Cloud Messaging service notifications |

Do not select location, contacts, browsing history, search history, advertising
data, health, files/documents, audio, calendar, SMS, or call logs. The app does
not use advertising or analytics SDKs.

### Security Practices

- Encryption in transit: `Yes`
- Account deletion request mechanism: `Yes`
- Independent security review: `No`, unless one is completed separately
- Families policy commitment: `No`

## Play Console App Content

### App Access

The app requires login. Supply App Review with:

- One active customer phone/password with no active order.
- One active administrator phone/password.
- Clear note that the login field accepts the Sri Lankan mobile number and the
  password is an Email/Password Firebase credential behind the phone login UI.
- Navigation: customer `Profile > Delete account`; admin dashboard provides
  orders, support, password resets, and account-deletion requests.

Never place production owner credentials in review notes. Create dedicated,
non-sensitive review accounts and keep them active until review finishes.

### Ads, Audience, And Rating

- Contains ads: `No`
- Target audience: `18 and over`
- News app: `No`
- Government app: `No`
- Financial features: select only ordinary purchase/payment functionality; the
  app does not provide loans, investments, banking, crypto, or money transfer.
- Content rating: answer `No` to violence, sexual content, gambling, drugs,
  profanity, and public user-generated content. Private order notes and support
  messages are service communications, not a public social feed.

### Payments

Orders are for physical groceries and delivery. Google Play Billing is not
required for payments for physical goods and services. The app supports cash on
delivery and bank transfer.

## Apple App Privacy

Mark the following as collected, linked to the user, not used for tracking, and
used for `App Functionality` unless App Store Connect asks for a more specific
purpose:

| Apple data type | Notes |
| --- | --- |
| Contact Info - Name | Customer profile and orders |
| Contact Info - Phone Number | Authentication, fulfilment, support |
| Contact Info - Physical Address | Grocery delivery |
| Financial Info - Payment Info | Payment method and optional transfer receipt |
| User Content - Photos or Videos | Shopping lists, receipts, support images |
| User Content - Emails or Text Messages | Private support messages |
| User Content - Customer Support | Tickets and replies |
| User Content - Other User Content | Typed lists, order notes, reviews |
| Identifiers - User ID | Firebase account ID |
| Identifiers - Device ID | Firebase notification token |
| Purchases - Purchase History | Grocery orders |

Select:

- Data used to track the user: `No`
- Third-party advertising: `No`
- Developer advertising or marketing: `No`
- Analytics: `No`

Use the privacy-policy URL above. The account-deletion page can also be entered
as the optional Privacy Choices URL.

## App Review Notes

Explain that:

- The app sells and delivers physical groceries.
- Customer accounts are created with a mobile number and password.
- Account deletion is available in `Profile > Delete account`.
- Password confirmation is required to prevent accidental deletion.
- Accounts with an active order must complete or cancel it first.
- Closed order/accounting records are anonymized; profile, authentication,
  support, notifications, reset requests, and personal Firebase Storage images
  are deleted.
- Anonymized closed-order/accounting records expire seven years after account
  deletion; completed or rejected web deletion requests expire after 90 days.
- Camera/gallery access is user initiated and only attaches an image selected
  for an order, receipt, catalog item, or support message.
