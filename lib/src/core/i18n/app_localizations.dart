import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import 'language_codes.dart';

class AppLocalizer {
  const AppLocalizer(this.languageCode);

  final String languageCode;

  bool get isTamil => languageCode == AppLanguageCodes.tamil;

  String text(String value, {Map<String, Object?> values = const {}}) {
    var translated = isTamil ? _tamil[value] ?? value : value;
    for (final entry in values.entries) {
      translated = translated.replaceAll('{${entry.key}}', '${entry.value}');
    }
    return translated;
  }

  String serverText(String value) {
    if (!isTamil) {
      return value;
    }
    final direct = _tamil[value];
    if (direct != null) {
      return direct;
    }

    final orderUpdated = RegExp(r'^Order (.+) updated$').firstMatch(value);
    if (orderUpdated != null) {
      return text(
        'Order {id} updated',
        values: {'id': orderUpdated.group(1) ?? ''},
      );
    }

    final statusChanged = RegExp(r'^Status changed to (.+)$').firstMatch(value);
    if (statusChanged != null) {
      return text(
        'Status changed to {status}',
        values: {'status': text(statusChanged.group(1) ?? '')},
      );
    }

    final orderTotal =
        RegExp(r'^Your order total is (.+)\.$').firstMatch(value);
    if (orderTotal != null) {
      return text(
        'Your order total is {amount}.',
        values: {'amount': orderTotal.group(1) ?? ''},
      );
    }

    return value;
  }
}

extension AppLocalizationContext on BuildContext {
  AppLocalizer get localizer {
    return AppLocalizer(_languageCode(listen: true));
  }

  String t(String value, {Map<String, Object?> values = const {}}) {
    return AppLocalizer(_languageCode(listen: true)).text(
      value,
      values: values,
    );
  }

  String tNow(String value, {Map<String, Object?> values = const {}}) {
    return AppLocalizer(_languageCode(listen: false)).text(
      value,
      values: values,
    );
  }

  String serverT(String value) {
    return AppLocalizer(_languageCode(listen: true)).serverText(value);
  }

  String _languageCode({required bool listen}) {
    try {
      return Provider.of<AppState>(this, listen: listen).effectiveLanguageCode;
    } on ProviderNotFoundException {
      return AppLanguageCodes.english;
    }
  }
}

const _tamil = <String, String>{
  'English': 'ஆங்கிலம்',
  'Tamil': 'தமிழ்',
  'Language': 'மொழி',
  'Language / Translate': 'மொழி / மொழிபெயர்ப்பு',
  'Preferred language': 'விருப்ப மொழி',
  'Choose the language for your customer screens.':
      'உங்கள் வாடிக்கையாளர் திரைகளுக்கான மொழியை தேர்வு செய்யுங்கள்.',
  'Current language': 'தற்போதைய மொழி',
  'Switch to English': 'ஆங்கிலத்திற்கு மாற்றவும்',
  'Switch to Tamil': 'தமிழுக்கு மாற்றவும்',
  'Language updated.': 'மொழி புதுப்பிக்கப்பட்டது.',
  'Profile updated.': 'சுயவிவரம் புதுப்பிக்கப்பட்டது.',
  'Loading...': 'ஏற்றப்படுகிறது...',
  'No internet connection. Please check your connection and try again.':
      'இணைய இணைப்பு இல்லை. உங்கள் இணைப்பைச் சரிபார்த்து மீண்டும் முயற்சிக்கவும்.',
  'No Internet Connection': 'இணைய இணைப்பு இல்லை',
  'Check your connection and try again.':
      'உங்கள் இணைப்பைச் சரிபார்த்து மீண்டும் முயற்சிக்கவும்.',
  'Retry': 'மீண்டும் முயற்சி',
  'Saving': 'சேமிக்கிறது',
  'Something went wrong. Please try again.':
      'ஏதோ தவறு ஏற்பட்டது. மீண்டும் முயற்சிக்கவும்.',
  'Service setup is not complete. Please contact support.':
      'சேவை அமைப்பு முழுமையாக இல்லை. ஆதரவை தொடர்புகொள்ளவும்.',
  'Image upload failed. Please check your connection and try again.':
      'படத்தை பதிவேற்ற முடியவில்லை. உங்கள் இணைப்பைச் சரிபார்த்து மீண்டும் முயற்சிக்கவும்.',
  'Refresh failed: {error}': 'புதுப்பிக்க முடியவில்லை: {error}',
  'Show password': 'கடவுச்சொல்லைக் காட்டு',
  'Hide password': 'கடவுச்சொல்லை மறை',
  'Phone number': 'தொலைபேசி எண்',
  'Local groceries, lists, pickup, and COD delivery.':
      'உள்ளூர் மளிகை, பட்டியல்கள், பிக்-அப் மற்றும் COD விநியோகம்.',
  'Everything you need in one place': 'தேவையான அனைத்தும் ஒரே இடத்தில்',
  'Browse our carefully selected products and enjoy a simple grocery shopping experience.':
      'கவனமாக தேர்ந்தெடுக்கப்பட்ட பொருட்களை பார்த்து எளிய மளிகை ஷாப்பிங்கை அனுபவிக்கவும்.',
  'Upload a shopping list': 'ஷாப்பிங் பட்டியலை பதிவேற்றவும்',
  'Send a handwritten or printed list photo when catalog items are not enough.':
      'பட்டியல் பொருட்கள் போதாதபோது கையெழுத்து அல்லது அச்சிடப்பட்ட பட்டியல் புகைப்படத்தை அனுப்புங்கள்.',
  'Cash on delivery': 'விநியோகத்தின் போது பணம்',
  'Admin reviews the bill, buys items, delivers, and collects cash.':
      'அட்மின் பில்லைக் சரிபார்த்து, பொருட்களை வாங்கி, விநியோகித்து, பணம் பெறுவார்.',
  'Fresh': 'புதியது',
  'Fast': 'வேகம்',
  'Trusted': 'நம்பகமானது',
  'Get started': 'தொடங்குங்கள்',
  'Next': 'அடுத்து',
  'Welcome back': 'மீண்டும் வரவேற்கிறோம்',
  'Fresh groceries are waiting': 'புதிய மளிகை பொருட்கள் காத்திருக்கின்றன',
  'Login with your phone and password to reorder, track deliveries, and send shopping lists.':
      'மீண்டும் ஆர்டர் செய்ய, விநியோகத்தை கண்காணிக்க, பட்டியல்கள் அனுப்ப உங்கள் தொலைபேசி மற்றும் கடவுச்சொல்லுடன் உள்நுழையுங்கள்.',
  'Password': 'கடவுச்சொல்',
  'Login': 'உள்நுழை',
  'Create account': 'கணக்கு உருவாக்கு',
  'Forgot password?': 'கடவுச்சொல் மறந்துவிட்டதா?',
  'Forgot password': 'கடவுச்சொல் மறந்துவிட்டது',
  'Reset securely': 'பாதுகாப்பாக மீட்டமைக்கவும்',
  'Admin-approved reset': 'அட்மின் அனுமதி பெற்ற மீட்டமைப்பு',
  'Request approval first. Once approved, you can set a new password here.':
      'முதலில் அனுமதி கோருங்கள். அனுமதி கிடைத்ததும் இங்கே புதிய கடவுச்சொல்லை அமைக்கலாம்.',
  'Request reset': 'மீட்டமைப்பு கோரு',
  'Complete profile': 'சுயவிவரத்தை முடிக்கவும்',
  'Your grocery profile': 'உங்கள் மளிகை சுயவிவரம்',
  'Add your delivery details once and checkout faster on every order.':
      'உங்கள் விநியோக விவரங்களை ஒருமுறை சேர்த்து ஒவ்வொரு ஆர்டரிலும் விரைவாக checkout செய்யுங்கள்.',
  'Full name': 'முழுப் பெயர்',
  'Delivery address': 'விநியோக முகவரி',
  'Confirm password': 'கடவுச்சொல்லை உறுதிப்படுத்து',
  'Set new password': 'புதிய கடவுச்சொல் அமை',
  'Password reset': 'கடவுச்சொல் மீட்டமைப்பு',
  'New password': 'புதிய கடவுச்சொல்',
  'Confirm new password': 'புதிய கடவுச்சொல்லை உறுதிப்படுத்து',
  'Update password': 'கடவுச்சொல் புதுப்பி',
  'Checking': 'சரிபார்க்கிறது',
  'Check approval': 'அனுமதியை சரிபார்',
  'Checking admin approval...': 'அட்மின் அனுமதி சரிபார்க்கப்படுகிறது...',
  'Waiting for admin approval.': 'அட்மின் அனுமதிக்காக காத்திருக்கிறது.',
  'Approved. Set your new password.':
      'அனுமதிக்கப்பட்டது. புதிய கடவுச்சொல்லை அமைக்கவும்.',
  'Rejected. Contact admin support.':
      'நிராகரிக்கப்பட்டது. அட்மின் ஆதரவை தொடர்புகொள்ளவும்.',
  'Password was already updated. Login with the new password.':
      'கடவுச்சொல் ஏற்கனவே புதுப்பிக்கப்பட்டது. புதிய கடவுச்சொல்லுடன் உள்நுழையுங்கள்.',
  'Pending admin approval.': 'அட்மின் அனுமதி நிலுவையில் உள்ளது.',
  'Password updated.': 'கடவுச்சொல் புதுப்பிக்கப்பட்டது.',
  'Home': 'முகப்பு',
  'Orders': 'ஆர்டர்கள்',
  'Support': 'ஆதரவு',
  'Profile': 'சுயவிவரம்',
  'Notifications': 'அறிவிப்புகள்',
  'Cart': 'கார்ட்',
  'Items': 'பொருட்கள்',
  'Pick the items you need.':
      'உங்களுக்கு தேவையான பொருட்களை தேர்வு செய்யுங்கள்.',
  'Photo list': 'புகைப்பட பட்டியல்',
  'Send any grocery list': 'எந்த மளிகை பட்டியலையும் அனுப்புங்கள்',
  'Fresh picks': 'புதிய தேர்வுகள்',
  'Recently added to the catalog': 'பட்டியலில் சமீபத்தில் சேர்க்கப்பட்டது',
  'View all': 'அனைத்தையும் பார்க்க',
  'Hi {name}': 'வணக்கம் {name}',
  'there': 'நண்பரே',
  'Search groceries ': 'மளிகைகளை தேடுங்கள்',
  'Fast local delivery': 'வேகமான உள்ளூர் விநியோகம்',
  'Fresh groceries, photo lists, and COD in one smooth order.':
      'புதிய மளிகை, புகைப்பட பட்டியல்கள், COD அனைத்தும் ஒரே எளிய ஆர்டரில்.',
  'We shop from trusted partners and keep you updated.':
      'நம்பகமான கூட்டாளர்களிடமிருந்து வாங்கி உங்களை தொடர்ந்து புதுப்பிப்போம்.',
  'No products yet': 'இன்னும் பொருட்கள் இல்லை',
  'Admin can add products from the admin dashboard.':
      'அட்மின் டாஷ்போர்டிலிருந்து பொருட்களை சேர்க்கலாம்.',
  'No active shops': 'செயலில் உள்ள கடைகள் இல்லை',
  'Products can still be browsed from the full catalog.':
      'முழு பட்டியலிலிருந்து பொருட்களை இன்னும் பார்க்கலாம்.',
  'Browse catalog': 'பட்டியலை பார்க்க',
  'Choose your Items': 'உங்கள் பொருட்களை தேர்வு செய்யுங்கள்',
  'Browse needed items near you':
      'உங்களுக்கருகில் தேவையான பொருட்களை பார்க்கவும்',
  'Products': 'பொருட்கள்',
  'Search products': 'பொருட்களை தேடுங்கள்',
  'Clear search': 'தேடலை அழி',
  'No products found': 'பொருட்கள் கிடைக்கவில்லை',
  'Try a different product name or shop.':
      'வேறு பொருள் பெயர் அல்லது கடையை முயற்சிக்கவும்.',
  'Could not load products': 'பொருட்களை ஏற்ற முடியவில்லை',
  'Firebase rules blocked product reads. Deploy the latest Firestore rules.':
      'Firebase விதிகள் பொருள் வாசிப்பை தடுத்தன. சமீபத்திய Firestore விதிகளை deploy செய்யுங்கள்.',
  'Firestore needs an index for this product query. The app now uses a simpler product query, so restart and try again.':
      'இந்த பொருள் queryக்கு Firestore index தேவை. இப்போது app எளிய query பயன்படுத்துகிறது; மீண்டும் தொடங்கி முயற்சிக்கவும்.',
  'Firestore did not answer in time. Check the device internet connection and Firebase project.':
      'Firestore நேரத்தில் பதிலளிக்கவில்லை. சாதன இணைய இணைப்பு மற்றும் Firebase projectஐ சரிபார்க்கவும்.',
  'Added to cart.': 'கார்டில் சேர்க்கப்பட்டது.',
  'Add': 'சேர்',
  'Add to cart': 'கார்டில் சேர்',
  'Unavailable': 'கிடைக்கவில்லை',
  'Available': 'கிடைக்கிறது',
  'About this item': 'இந்த பொருள் பற்றி',
  'No description added yet. You can still add it to your cart and confirm details at checkout.':
      'இன்னும் விளக்கம் சேர்க்கப்படவில்லை. இதை கார்டில் சேர்த்து checkoutல் விவரங்களை உறுதிப்படுத்தலாம்.',
  'per {unit}': '{unit} ஒன்றுக்கு',
  'Your cart is empty': 'உங்கள் கார்ட் காலியாக உள்ளது',
  'Add catalog products or upload a shopping list photo.':
      'பட்டியல் பொருட்களை சேர்க்கவும் அல்லது ஷாப்பிங் பட்டியல் புகைப்படத்தை பதிவேற்றவும்.',
  'Browse products': 'பொருட்களை பார்க்க',
  'Items in cart': 'கார்டில் உள்ள பொருட்கள்',
  'Adjust quantities before checkout': 'Checkoutக்கு முன் அளவுகளை மாற்றுங்கள்',
  'Attached list': 'இணைக்கப்பட்ட பட்டியல்',
  'Admin will review this with your order':
      'அட்மின் இதை உங்கள் ஆர்டருடன் சரிபார்ப்பார்',
  'Change bill/list photo': 'பில்/பட்டியல் புகைப்படத்தை மாற்று',
  'Upload bill/list photo': 'பில்/பட்டியல் புகைப்படத்தை பதிவேற்று',
  'Checkout': 'Checkout',
  '1 catalog item': '1 பட்டியல் பொருள்',
  '{count} catalog items': '{count} பட்டியல் பொருட்கள்',
  'Photo list attached for admin pricing':
      'அட்மின் விலை நிர்ணயத்திற்காக புகைப்பட பட்டியல் இணைக்கப்பட்டது',
  'Catalog subtotal before delivery':
      'விநியோகத்திற்கு முன் பட்டியல் துணைத்தொகை',
  'Decrease': 'குறை',
  'Increase': 'அதிகரி',
  'No list photo selected': 'பட்டியல் புகைப்படம் தேர்வு செய்யப்படவில்லை',
  'Use gallery or camera to attach your list.':
      'உங்கள் பட்டியலை இணைக்க gallery அல்லது camera பயன்படுத்துங்கள்.',
  'Upload list': 'பட்டியலை பதிவேற்று',
  'Upload a clear handwritten, printed, or shop list photo. Admin will review it and update your final bill.':
      'தெளிவான கையெழுத்து, அச்சு அல்லது கடை பட்டியல் புகைப்படத்தை பதிவேற்றுங்கள். அட்மின் அதை சரிபார்த்து இறுதி பில்லைக் புதுப்பிப்பார்.',
  'Gallery': 'Gallery',
  'Choose photo': 'புகைப்படம் தேர்வு',
  'Retake': 'மீண்டும் எடு',
  'Camera': 'Camera',
  'Remove photo': 'புகைப்படத்தை நீக்கு',
  'Continue to checkout': 'Checkoutக்கு தொடரவும்',
  'Shopping list image ready for upload.':
      'ஷாப்பிங் பட்டியல் படம் பதிவேற்றத்துக்கு தயாராக உள்ளது.',
  'Payment method': 'கட்டண முறை',
  'Bank transfer': 'வங்கி பரிமாற்றம்',
  'Cash on Delivery': 'விநியோகத்தின் போது பணம்',
  'Pay by cash when your order is delivered.':
      'உங்கள் ஆர்டர் விநியோகிக்கப்படும் போது பணமாக செலுத்துங்கள்.',
  'Transfer to the store account and upload your receipt.':
      'கடை கணக்கிற்கு பணம் மாற்றி ரசீதையை பதிவேற்றவும்.',
  'Subtotal': 'இடைமொத்தம்',
  'Delivery charge': 'டெலிவரி கட்டணம்',
  'Service charge': 'சேவை கட்டணம்',
  'Estimated total': 'மதிப்பிடப்பட்ட மொத்தம்',
  'Bill details': 'பில் விவரங்கள்',
  'Cart items': 'கார்ட் பொருட்கள்',
  'Photo list items': 'புகைப்பட பட்டியல் பொருட்கள்',
  'Manual list items': 'கைமுறை பட்டியல் பொருட்கள்',
  'Order subtotal': 'ஆர்டர் துணைத்தொகை',
  'Grand total': 'மொத்த தொகை',
  'Customer name': 'வாடிக்கையாளர் பெயர்',
  'Order notes': 'ஆர்டர் குறிப்புகள்',
  'Place bank transfer order': 'வங்கி பரிமாற்ற ஆர்டர் இடு',
  'Place COD order': 'COD ஆர்டர் இடு',
  'Upload the bank transfer receipt before checkout.':
      'Checkoutக்கு முன் வங்கி பரிமாற்ற ரசீதையை பதிவேற்றவும்.',
  'Review payment and delivery details':
      'கட்டணம் மற்றும் விநியோக விவரங்களை சரிபார்க்கவும்',
  'The prices of attached list items are not calculated in this estimate. Admin will review the photo and update the final bill.':
      'இணைக்கப்பட்ட பட்டியல் பொருட்களின் விலை இந்த மதிப்பீட்டில் கணக்கிடப்படவில்லை. அட்மின் புகைப்படத்தை சரிபார்த்து இறுதி பில்லைக் புதுப்பிப்பார்.',
  'Transfer account': 'பரிமாற்ற கணக்கு',
  'Name': 'பெயர்',
  'Bank': 'வங்கி',
  'Branch': 'கிளை',
  'Account number': 'கணக்கு எண்',
  'Payment receipt': 'கட்டண ரசீது',
  'Upload the bank slip or transfer screenshot before placing the order.':
      'ஆர்டர் இடுவதற்கு முன் வங்கி slip அல்லது transfer screenshotஐ பதிவேற்றவும்.',
  'Change': 'மாற்று',
  'Remove receipt': 'ரசீதையை நீக்கு',
  'Order placed': 'ஆர்டர் இடப்பட்டது',
  'Order received': 'ஆர்டர் பெறப்பட்டது',
  'Your bank transfer order is pending admin receipt review.':
      'உங்கள் வங்கி பரிமாற்ற ஆர்டர் அட்மின் ரசீது சரிபார்ப்பில் நிலுவையில் உள்ளது.',
  'Your COD order is pending admin review.':
      'உங்கள் COD ஆர்டர் அட்மின் சரிபார்ப்பில் நிலுவையில் உள்ளது.',
  'Order': 'ஆர்டர்',
  'Total': 'மொத்தம்',
  'Payment': 'கட்டணம்',
  'Track order': 'ஆர்டரை கண்காணி',
  'Back home': 'முகப்புக்கு திரும்பு',
  'Order history': 'உங்கள் ஆர்டர்கள்',
  'No orders yet': 'இன்னும் ஆர்டர்கள் இல்லை',
  'Your order history will appear here.':
      'உங்கள் ஆர்டர் வரலாறு இங்கே தோன்றும்.',
  'Recent orders': 'சமீபத்திய ஆர்டர்கள்',
  'Track progress and review previous baskets':
      'ஆர்டர் நிலையும் பழைய ஆர்டர்களும் இங்கே பார்க்கலாம்',
  'Order {id}': 'ஆர்டர் {id}',
  '{count} orders': '{count} ஆர்டர்கள்',
  '{count} of {total} orders': '{total} ஆர்டர்களில் {count}',
  'All': 'அனைத்தும்',
  'Active': 'நடப்பில்',
  'Active orders': 'நடப்பில் உள்ள ஆர்டர்கள்',
  'Orders being prepared, shopped, or delivered.':
      'தயார் செய்யப்படும் அல்லது டெலிவரிக்கு வரும் ஆர்டர்கள்.',
  'No active orders': 'நடப்பில் ஆர்டர்கள் இல்லை',
  'Orders in progress will appear here.':
      'செயல்பாட்டில் உள்ள ஆர்டர்கள் இங்கே தோன்றும்.',
  'Needs attention': 'கவனம் தேவை',
  'Orders with questions, item changes, or updated bills.':
      'உங்கள் பதில், பொருள் மாற்றம் அல்லது பில் சரிபார்ப்பு தேவைப்படும் ஆர்டர்கள்.',
  'Nothing needs attention': 'இப்போது கவனம் தேவைப்படுவது இல்லை',
  'Orders that need your review will appear here.':
      'நீங்கள் பார்க்க வேண்டிய ஆர்டர்கள் இங்கே தோன்றும்.',
  'Delivered orders': 'டெலிவரி முடிந்த ஆர்டர்கள்',
  'Completed baskets are saved for quick review.':
      'முடிந்த ஆர்டர்களை இங்கே மீண்டும் பார்க்கலாம்.',
  'No delivered orders': 'டெலிவரி முடிந்த ஆர்டர்கள் இல்லை',
  'Completed orders will appear here.': 'முடிந்த ஆர்டர்கள் இங்கே தோன்றும்.',
  'Rejected orders': 'ரத்து/நிராகரிக்கப்பட்ட ஆர்டர்கள்',
  'Orders that could not be completed.':
      'முடிக்க முடியாத ஆர்டர்கள் இங்கே இருக்கும்.',
  'No rejected orders': 'ரத்து செய்யப்பட்ட ஆர்டர்கள் இல்லை',
  'Rejected or cancelled orders will appear here.':
      'ரத்து அல்லது நிராகரிக்கப்பட்ட ஆர்டர்கள் இங்கே தோன்றும்.',
  '{rating}/5 delivery rating': '{rating}/5 டெலிவரி மதிப்பீடு',
  'Order tracking': 'ஆர்டர் கண்காணிப்பு',
  'Order not found': 'ஆர்டர் கிடைக்கவில்லை',
  'This order may have been removed.': 'இந்த ஆர்டர் நீக்கப்பட்டிருக்கலாம்.',
  'Uploaded list': 'பதிவேற்றப்பட்ட பட்டியல்',
  'Contact admin': 'அட்மினை தொடர்புகொள்',
  'Updates': 'புதுப்பிப்புகள்',
  'Order and support activity': 'ஆர்டர் மற்றும் ஆதரவு செயல்பாடு',
  'No notifications': 'அறிவிப்புகள் இல்லை',
  'Order and support updates will appear here.':
      'ஆர்டர் மற்றும் ஆதரவு புதுப்பிப்புகள் இங்கே தோன்றும்.',
  'Subject': 'தலைப்பு',
  'Message': 'செய்தி',
  'Create ticket': 'டிக்கெட் உருவாக்கு',
  'Your tickets': 'உங்கள் டிக்கெட்டுகள்',
  'Continue a previous conversation': 'முந்தைய உரையாடலை தொடருங்கள்',
  'No support tickets': 'ஆதரவு டிக்கெட்டுகள் இல்லை',
  'Create a ticket when you need help with an order.':
      'ஆர்டருக்கு உதவி தேவைப்பட்டால் டிக்கெட் உருவாக்குங்கள்.',
  'Subject and message are required.': 'தலைப்பும் செய்தியும் அவசியம்.',
  'Support ticket created.': 'ஆதரவு டிக்கெட் உருவாக்கப்பட்டது.',
  'Close ticket': 'டிக்கெட்டை மூடு',
  'Ticket closed.': 'டிக்கெட் மூடப்பட்டது.',
  'Messages unavailable': 'செய்திகள் கிடைக்கவில்லை',
  'Please go back and open this ticket again.':
      'பின்சென்று இந்த டிக்கெட்டை மீண்டும் திறக்கவும்.',
  'No messages yet': 'இன்னும் செய்திகள் இல்லை',
  'Send a message to continue this support ticket.':
      'இந்த ஆதரவு டிக்கெட்டை தொடர செய்தி அனுப்புங்கள்.',
  'Attach image': 'படத்தை இணை',
  'Type a message': 'செய்தியை எழுதுங்கள்',
  'Image attached': 'படம் இணைக்கப்பட்டது',
  'Save profile': 'சுயவிவரத்தை சேமி',
  'Logout': 'வெளியேறு',
  'Delivery dashboard': 'டெலிவரி வேலைகள்',
  'LKR 1,000 star reward': 'LKR 1,000 நட்சத்திர பரிசு',
  'LKR {amount} is available from your stars':
      'உங்கள் நட்சத்திரங்களில் LKR {amount} கிடைக்கிறது',
  '{count} stars until 1,000 stars': '1,000 நட்சத்திரத்திற்கு இன்னும் {count}',
  '1 star = LKR 1. You can ask the admin for a partial or full payment.':
      '1 நட்சத்திரம் = LKR 1. தேவையானால் பகுதி அல்லது முழு பணம் பெற அட்மினிடம் கேட்கலாம்.',
  'Ready for delivery': 'டெலிவரிக்கு தயார்',
  'Good morning': 'காலை வணக்கம்',
  'Good afternoon': 'மதிய வணக்கம்',
  'Good evening': 'மாலை வணக்கம்',
  '{greeting}, {name}': '{greeting}, {name}',
  'You are all caught up. New assignments will appear here.':
      'இப்போது வேலை எதுவும் இல்லை. புதிய டெலிவரிகள் இங்கே வரும்.',
  'You have 1 delivery waiting for you.':
      'உங்களுக்காக 1 டெலிவரி காத்திருக்கிறது.',
  'You have {count} deliveries waiting for you.':
      'உங்களுக்காக {count} டெலிவரிகள் காத்திருக்கின்றன.',
  'Active now': 'இப்போது நடப்பில்',
  'Delivered today': 'இன்று முடிந்தது',
  'All delivered': 'மொத்த டெலிவரி',
  'Customer rating': 'வாடிக்கையாளர் மதிப்பீடு',
  'New': 'புதியது',
  'No reviews yet': 'இன்னும் மதிப்பீடு இல்லை',
  '1 review': '1 மதிப்பீடு',
  '{count} reviews': '{count} மதிப்பீடுகள்',
  'Current deliveries': 'இன்றைய டெலிவரிகள்',
  'Delivery history': 'டெலிவரி வரலாறு',
  'All assigned orders': 'ஒதுக்கப்பட்ட அனைத்தும்',
  'History': 'வரலாறு',
  'No active deliveries': 'நடப்பில் டெலிவரி இல்லை',
  'Completed deliveries are saved in History.':
      'முடிந்த டெலிவரிகள் வரலாற்றில் சேமிக்கப்படும்.',
  'Assigned deliveries will appear here.':
      'உங்களுக்கு ஒதுக்கப்படும் டெலிவரிகள் இங்கே தோன்றும்.',
  'No delivery history': 'டெலிவரி வரலாறு இல்லை',
  'Delivered and closed assigned orders will appear here.':
      'முடிந்த அல்லது மூடப்பட்ட ஆர்டர்கள் இங்கே தோன்றும்.',
  'No assigned orders': 'ஒதுக்கப்பட்ட ஆர்டர்கள் இல்லை',
  'Customer phone': 'வாடிக்கையாளர் போன்',
  'Address': 'முகவரி',
  'Admin notes': 'அட்மின் குறிப்பு',
  'Call customer': 'வாடிக்கையாளரை அழை',
  'Collected': 'பெறப்பட்டது',
  'collected': 'பெறப்பட்டது',
  'Payment marked collected.': 'கட்டணம் பெற்றதாக சேமிக்கப்பட்டது.',
  'Order marked delivered.': 'ஆர்டர் டெலிவரி முடிந்ததாக சேமிக்கப்பட்டது.',
  'Customer review': 'வாடிக்கையாளர் கருத்து',
  'Amount details': 'தொகை விவரம்',
  'Total amount': 'மொத்த தொகை',
  'Order items': 'ஆர்டர் பொருட்கள்',
  'No cart items. Check the attached list details below.':
      'கார்ட் பொருட்கள் இல்லை. இணைக்கப்பட்ட பட்டியல் விவரத்தை கீழே பாருங்கள்.',
  'Account blocked': 'கணக்கு தடுக்கப்பட்டுள்ளது',
  'Please contact support before placing new orders.':
      'புதிய ஆர்டர்கள் இடுவதற்கு முன் ஆதரவை தொடர்புகொள்ளவும்.',
  'Pending': 'காத்திருக்கிறது',
  'Accepted': 'ஏற்கப்பட்டது',
  'Need Clarification': 'விவரம் தேவை',
  'Shopping Started': 'பொருட்கள் வாங்கப்படுகிறது',
  'Item Unavailable': 'பொருள் கிடைக்கவில்லை',
  'Bill Updated': 'பில் சரிபார்க்கவும்',
  'Out for Delivery': 'டெலிவரிக்கு வருகிறது',
  'Delivered': 'டெலிவரி முடிந்தது',
  'Cancelled': 'ரத்து செய்யப்பட்டது',
  'Rejected': 'நிராகரிக்கப்பட்டது',
  'pending': 'காத்திருக்கிறது',
  'receipt uploaded': 'ரசீது பதிவேற்றப்பட்டது',
  'open': 'திறந்தது',
  'replied': 'பதில் அளிக்கப்பட்டது',
  'closed': 'மூடப்பட்டது',
  'COD': 'COD',
  'Bank Transfer': 'வங்கி பரிமாற்றம்',
  'kg': 'கிலோ',
  'g': 'கிராம்',
  'packet': 'பாக்கெட்',
  'bottle': 'பாட்டில்',
  'piece': 'துண்டு',
  'Full name is required': 'முழுப் பெயர் அவசியம்',
  'Delivery address is required': 'விநியோக முகவரி அவசியம்',
  'Customer name is required': 'வாடிக்கையாளர் பெயர் அவசியம்',
  'Phone number is required': 'தொலைபேசி எண் அவசியம்',
  'Enter the 9 digits after +94': '+94க்குப் பிறகு 9 இலக்கங்களை உள்ளிடுங்கள்',
  'Enter a Sri Lankan mobile number starting with 7':
      '7-இல் தொடங்கும் இலங்கை மொபைல் எண்ணை உள்ளிடுங்கள்',
  'Password is required': 'கடவுச்சொல் அவசியம்',
  'Password must be at least 6 characters':
      'கடவுச்சொல் குறைந்தது 6 எழுத்துகள் இருக்க வேண்டும்',
  'Passwords do not match': 'கடவுச்சொற்கள் பொருந்தவில்லை',
  'Order {id} updated': 'ஆர்டர் {id} புதுப்பிக்கப்பட்டது',
  'Status changed to {status}': 'நிலை {status} என மாற்றப்பட்டது',
  'Your order total is {amount}.': 'உங்கள் ஆர்டர் மொத்தம் {amount}.',
  'New order received': 'புதிய ஆர்டர் பெறப்பட்டது',
  'Final bill updated': 'இறுதி பில் புதுப்பிக்கப்பட்டது',
  'Admin replied': 'அட்மின் பதிலளித்தார்',
  'New support message': 'புதிய ஆதரவு செய்தி',
  'Firebase is not configured. Login, database, functions, and FCM need real Firebase config files.':
      'Firebase அமைக்கப்படவில்லை. Login, database, functions மற்றும் FCMக்கு உண்மையான Firebase config கோப்புகள் தேவை.',
  'user': 'வாடிக்கையாளர்',
  'Enter a valid Sri Lankan mobile number starting with 7.':
      '7-இல் தொடங்கும் செல்லுபடியான இலங்கை மொபைல் எண்ணை உள்ளிடுங்கள்.',
  'An account already exists for this phone number. Login or request a password reset.':
      'இந்த தொலைபேசி எண்ணிற்கு ஏற்கனவே கணக்கு உள்ளது. உள்நுழையவும் அல்லது கடவுச்சொல் மீட்டமைப்பு கோரவும்.',
  'Phone number or password is incorrect.':
      'தொலைபேசி எண் அல்லது கடவுச்சொல் தவறானது.',
  'Too many attempts. Please wait a few minutes and try again.':
      'மிக அதிக முயற்சிகள். சில நிமிடங்கள் காத்திருந்து மீண்டும் முயற்சிக்கவும்.',
  'Network error. Check your connection and try again.':
      'நெட்வொர்க் பிழை. இணைப்பை சரிபார்த்து மீண்டும் முயற்சிக்கவும்.',
  'Firebase authentication quota is exceeded. Try again later.':
      'Firebase authentication quota மீறப்பட்டுள்ளது. பின்னர் முயற்சிக்கவும்.',
  'Firebase sign-in is disabled. Enable Email/Password in Authentication > Sign-in method.':
      'Firebase sign-in முடக்கப்பட்டுள்ளது. Authentication > Sign-in methodல் Email/Passwordஐ இயக்கவும்.',
  'Firebase authentication failed. Try again.':
      'Firebase authentication தோல்வியடைந்தது. மீண்டும் முயற்சிக்கவும்.',
  'User profile was not found in Firestore.':
      'Firestoreல் பயனர் சுயவிவரம் கிடைக்கவில்லை.',
  'This account is blocked. Contact admin support.':
      'இந்த கணக்கு தடுக்கப்பட்டுள்ளது. அட்மின் ஆதரவை தொடர்புகொள்ளவும்.',
  'Check the details and try again.':
      'விவரங்களை சரிபார்த்து மீண்டும் முயற்சிக்கவும்.',
  'No account was found for that phone number.':
      'அந்த தொலைபேசி எண்ணிற்கு கணக்கு கிடைக்கவில்லை.',
  'This request is not ready yet.': 'இந்த கோரிக்கை இன்னும் தயாராக இல்லை.',
  'You are not allowed to perform this action.':
      'இந்த செயலை செய்ய உங்களுக்கு அனுமதி இல்லை.',
  'Password reset service is unavailable. Try again shortly.':
      'கடவுச்சொல் மீட்டமைப்பு சேவை கிடைக்கவில்லை. சிறிது நேரத்தில் முயற்சிக்கவும்.',
  'Password reset failed. Try again.':
      'கடவுச்சொல் மீட்டமைப்பு தோல்வியடைந்தது. மீண்டும் முயற்சிக்கவும்.',
  'Admin approved your reset. Set a new password.':
      'அட்மின் உங்கள் மீட்டமைப்பை அனுமதித்தார். புதிய கடவுச்சொல்லை அமைக்கவும்.',
  'Please login before placing an order.':
      'ஆர்டர் இடுவதற்கு முன் உள்நுழையுங்கள்.',
  'Blocked users cannot place orders.':
      'தடுக்கப்பட்ட பயனர்கள் ஆர்டர் இட முடியாது.',
  'Add products or upload a shopping list before checkout.':
      'Checkoutக்கு முன் பொருட்களை சேர்க்கவும் அல்லது ஷாப்பிங் பட்டியலை பதிவேற்றவும்.',
};
