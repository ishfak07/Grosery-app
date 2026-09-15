import 'package:flutter/widgets.dart';

/// Helpers for showing a Tamil name/label alongside its English counterpart.
class BilingualText {
  const BilingualText._();

  /// Single-line label such as `"Tomato / தக்காளி"`. Falls back to just
  /// [english] when there is no distinct Tamil value.
  static String label(String english, String tamil, {String separator = ' / '}) {
    final en = english.trim();
    final ta = tamil.trim();
    if (ta.isEmpty || ta == en) return en;
    return '$en$separator$ta';
  }

  /// Whether [tamil] is a distinct, non-empty value worth showing next to
  /// [english].
  static bool hasDistinctTamil(String english, String tamil) {
    final en = english.trim();
    final ta = tamil.trim();
    return ta.isNotEmpty && ta != en;
  }
}

/// Renders a product/offer name with clear English/Tamil hierarchy: English
/// first as the primary line (using [style] as-is), Tamil second as a
/// smaller, lighter, secondary line beneath it. When Tamil is missing or
/// identical to English, only the English line is shown — never an empty
/// line or placeholder text.
///
/// Pass [tamilStyle] to control the secondary line explicitly; otherwise a
/// comfortable secondary style is derived automatically from [style] (a
/// touch smaller, lighter weight, and softened color) so every call site
/// gets consistent hierarchy without hand-tuning each one.
class BilingualLines extends StatelessWidget {
  const BilingualLines({
    super.key,
    required this.english,
    required this.tamil,
    required this.style,
    this.tamilStyle,
    this.maxLinesEach = 1,
    this.overflow = TextOverflow.ellipsis,
    this.gap = 3,
    this.textAlign,
  });

  final String english;
  final String tamil;
  final TextStyle style;
  final TextStyle? tamilStyle;
  final int maxLinesEach;
  final TextOverflow overflow;
  final double gap;
  final TextAlign? textAlign;

  static TextStyle deriveSecondaryStyle(TextStyle primary) {
    final baseSize = primary.fontSize ?? 14;
    final baseColor = primary.color ?? const Color(0xFF10231A);
    return primary.copyWith(
      fontSize: baseSize <= 12 ? baseSize : baseSize - 1.5,
      fontWeight: FontWeight.w500,
      color: baseColor.withValues(alpha: baseColor.a * 0.64),
      letterSpacing: 0,
      height: 1.3,
    );
  }

  @override
  Widget build(BuildContext context) {
    final showBoth = BilingualText.hasDistinctTamil(english, tamil);
    final resolvedTamilStyle = tamilStyle ?? deriveSecondaryStyle(style);
    return Column(
      crossAxisAlignment: textAlign == TextAlign.center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          english.trim(),
          maxLines: maxLinesEach,
          overflow: overflow,
          textAlign: textAlign,
          style: style,
        ),
        if (showBoth) ...[
          SizedBox(height: gap),
          Text(
            tamil.trim(),
            maxLines: maxLinesEach,
            overflow: overflow,
            textAlign: textAlign,
            style: resolvedTamilStyle,
          ),
        ],
      ],
    );
  }
}
