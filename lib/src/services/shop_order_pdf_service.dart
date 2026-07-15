import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/models.dart';

class ShopOrderPdfService {
  const ShopOrderPdfService._();

  static String fileName(OrderModel order) {
    final safeId = order.orderId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '');
    final suffix = safeId.isEmpty ? 'order' : safeId;
    return 'shop-order-$suffix.pdf';
  }

  static Future<Uint8List> build(OrderModel order) async {
    final imageUrls = <String>{
      if (order.uploadedImageUrl.trim().isNotEmpty)
        order.uploadedImageUrl.trim(),
      for (final item in order.items)
        if (item.imageUrl.trim().isNotEmpty) item.imageUrl.trim(),
    };
    final images = <String, Uint8List>{};
    final themeFuture = _loadTamilTheme();
    await Future.wait(imageUrls.map((url) async {
      final bytes = await _downloadImage(url);
      if (bytes != null) {
        images[url] = bytes;
      }
    }));
    return buildFromImages(
      order,
      images: images,
      theme: await themeFuture,
    );
  }

  static Future<Uint8List> buildFromImages(
    OrderModel order, {
    Map<String, Uint8List> images = const <String, Uint8List>{},
    pw.ThemeData? theme,
  }) async {
    final document = pw.Document(
      theme: theme,
      title: 'Order preparation ${order.orderId}',
      author: 'Puttalam Drop',
      subject: 'Combined order preparation list',  
    );
    final placedAt = DateFormat('dd MMM yyyy, h:mm a').format(order.createdAt);

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 10),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.7),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'PUTTALAM DROP',
                style: pw.TextStyle(
                  color: PdfColors.green800,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              pw.Text(
                'ORDER PREPARATION SHEET',
                style: pw.TextStyle(
                  color: PdfColors.grey700,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        footer: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(top: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              top: pw.BorderSide(color: PdfColors.grey300, width: 0.7),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Order ${order.orderId}',
                style: const pw.TextStyle(
                  color: PdfColors.grey600,
                  fontSize: 8,
                ),
              ),
              pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: const pw.TextStyle(
                  color: PdfColors.grey600,
                  fontSize: 8,
                ),
              ),
            ],
          ),
        ),
        build: (context) => [
          pw.SizedBox(height: 12),
          pw.Text(
            'Combined purchase list',
            style: pw.TextStyle(
              color: PdfColors.grey900,
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Use this sheet to purchase every item requested in the order.',
            style: const pw.TextStyle(
              color: PdfColors.grey600,
              fontSize: 10,
            ),
          ),
          pw.SizedBox(height: 18),
          _infoPanel(order, placedAt),
          pw.SizedBox(height: 20),
          _sectionTitle('1. Catalog cart items', '${order.items.length} items'),
          pw.SizedBox(height: 8),
          if (order.items.isEmpty)
            _emptyMessage('No catalog cart items in this order.')
          else
            ...order.items.asMap().entries.map(
                  (entry) => _catalogItem(
                    entry.key + 1,
                    entry.value,
                    images[entry.value.imageUrl.trim()],
                  ),
                ),
          pw.SizedBox(height: 18),
          _sectionTitle(
            '2. Uploaded shopping-list photo',
            order.hasUpload ? 'Attached' : 'Not provided',
          ),
          pw.SizedBox(height: 8),
          if (!order.hasUpload)
            _emptyMessage('No shopping-list photo was uploaded.')
          else
            _photoList(
              order.uploadedImageUrl,
              images[order.uploadedImageUrl.trim()],
            ),
          pw.SizedBox(height: 18),
          _sectionTitle(
            '3. Typed manual list',
            '${order.manualListLines.length} lines',
          ),
          pw.SizedBox(height: 8),
          if (order.manualListLines.isEmpty)
            _emptyMessage('No typed manual-list items were added.')
          else
            ...order.manualListLines.asMap().entries.map(
                  (entry) => _manualItem(entry.key + 1, entry.value),
                ),
          if (order.customerNotes.trim().isNotEmpty) ...[
            pw.SizedBox(height: 18),
            _sectionTitle('Customer note', ''),
            pw.SizedBox(height: 8),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.amber50,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: PdfColors.amber200),
              ),
              child: pw.Text(
                order.customerNotes.trim(),
                style: const pw.TextStyle(fontSize: 10, height: 1.4),
              ),
            ),
          ],
        ],
      ),
    );

    return document.save();
  }

  static pw.Widget _infoPanel(OrderModel order, String placedAt) {
    final catalogQuantity =
        order.items.fold<int>(0, (sum, item) => sum + item.quantity);
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: PdfColors.green50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.green200),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _infoRow('Order ID', order.orderId),
          _infoRow('Placed', placedAt),
          _infoRow('Customer', order.customerName),
          _infoRow('Phone', order.customerPhone),
          _infoRow('Delivery address', order.customerAddress),
          _infoRow('Catalog quantity', '$catalogQuantity'),
        ],
      ),
    );
  }

  static pw.Widget _infoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 92,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                color: PdfColors.grey700,
                fontWeight: pw.FontWeight.bold,
                fontSize: 9,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value.trim().isEmpty ? '-' : value,
              style: const pw.TextStyle(fontSize: 9),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _sectionTitle(String title, String trailing) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            color: PdfColors.green900,
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        if (trailing.isNotEmpty)
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: pw.BoxDecoration(
              color: PdfColors.green50,
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Text(
              trailing,
              style: pw.TextStyle(
                color: PdfColors.green800,
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  static pw.Widget _catalogItem(
    int index,
    OrderItem item,
    Uint8List? imageBytes,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 7),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: item.isAvailable ? PdfColors.white : PdfColors.red50,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(
          color: item.isAvailable ? PdfColors.grey300 : PdfColors.red200,
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          _thumbnail(imageBytes, '$index'),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  item.name,
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey900,
                  ),
                ),
                if (item.shopName.trim().isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Category: ${item.shopName}',
                    style: const pw.TextStyle(
                      color: PdfColors.grey600,
                      fontSize: 8,
                    ),
                  ),
                ],
                pw.SizedBox(height: 3),
                pw.Text(
                  '${item.quantity} x ${_money(item.price)} / ${item.unit}',
                  style: const pw.TextStyle(
                    color: PdfColors.grey700,
                    fontSize: 9,
                  ),
                ),
                if (!item.isAvailable)
                  pw.Text(
                    'Marked unavailable',
                    style: pw.TextStyle(
                      color: PdfColors.red700,
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Text(
            _money(item.lineTotal),
            style: pw.TextStyle(
              color: PdfColors.green900,
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _thumbnail(Uint8List? bytes, String fallback) {
    return pw.Container(
      width: 44,
      height: 44,
      alignment: pw.Alignment.center,
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(5),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: bytes == null
          ? pw.Text(
              fallback,
              style: pw.TextStyle(
                color: PdfColors.grey600,
                fontWeight: pw.FontWeight.bold,
              ),
            )
          : pw.ClipRRect(
              horizontalRadius: 5,
              verticalRadius: 5,
              child: pw.Image(
                pw.MemoryImage(bytes),
                width: 44,
                height: 44,
                fit: pw.BoxFit.cover,
              ),
            ),
    );
  }

  static pw.Widget _photoList(String url, Uint8List? imageBytes) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: imageBytes == null
          ? pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'The photo could not be embedded. Open the original link:',
                  style: pw.TextStyle(
                    color: PdfColors.orange800,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 9,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.UrlLink(
                  destination: url,
                  child: pw.Text(
                    url,
                    style: const pw.TextStyle(
                      color: PdfColors.blue700,
                      fontSize: 8,
                    ),
                  ),
                ),
              ],
            )
          : pw.Center(
              child: pw.Image(
                pw.MemoryImage(imageBytes),
                fit: pw.BoxFit.contain,
                height: 360,
              ),
            ),
    );
  }

  static pw.Widget _manualItem(int index, String text) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 6),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 22,
            height: 22,
            alignment: pw.Alignment.center,
            decoration: const pw.BoxDecoration(
              color: PdfColors.green100,
              shape: pw.BoxShape.circle,
            ),
            child: pw.Text(
              '$index',
              style: pw.TextStyle(
                color: PdfColors.green900,
                fontWeight: pw.FontWeight.bold,
                fontSize: 8,
              ),
            ),
          ),
          pw.SizedBox(width: 9),
          pw.Expanded(
            child: pw.Text(
              text,
              style: const pw.TextStyle(fontSize: 10, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _emptyMessage(String message) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Text(
        message,
        style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 9),
      ),
    );
  }

  static String _money(double amount) => 'LKR ${amount.toStringAsFixed(2)}';

  static Future<Uint8List?> _downloadImage(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      return null;
    }
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          response.bodyBytes.isEmpty) {
        return null;
      }
      return response.bodyBytes;
    } catch (_) {
      return null;
    }
  }

  static Future<pw.ThemeData?> _loadTamilTheme() async {
    try {
      final fonts = await Future.wait([
        PdfGoogleFonts.notoSansTamilRegular(),
        PdfGoogleFonts.notoSansTamilBold(),
      ]);
      return pw.ThemeData.withFont(base: fonts[0], bold: fonts[1]);
    } catch (_) {
      return null;
    }
  }
}
