import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../core/constants/app_constants.dart';
import '../models/models.dart';

/// Builds the customer-facing delivery receipt/invoice PDF. Only ever shown
/// once [OrderModel.orderStatus] is `Delivered` — see
/// `_DeliveredOrderCompletionView` in customer_screens.dart, the sole place
/// that surfaces the download action.
class OrderReceiptPdfService {
  const OrderReceiptPdfService._();

  static String fileName(OrderModel order) {
    final safeId = order.orderId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '');
    final suffix = safeId.isEmpty ? 'order' : safeId;
    return 'puttalam-drop-receipt-$suffix.pdf';
  }

  static Future<Uint8List> build(OrderModel order) async {
    final results = await Future.wait([_loadLogo(), _loadTamilTheme()]);
    final logo = results[0] as pw.MemoryImage?;
    final theme = results[1] as pw.ThemeData?;
    return buildWithAssets(order, logo: logo, theme: theme);
  }

  static Future<Uint8List> buildWithAssets(
    OrderModel order, {
    pw.MemoryImage? logo,
    pw.ThemeData? theme,
  }) async {
    final document = pw.Document(
      theme: theme,
      title: 'Receipt ${order.orderId}',
      author: AppConstants.appName,
      subject: 'Delivery receipt',
    );
    final placedAt = DateFormat('dd MMM yyyy, h:mm a').format(order.createdAt);
    const discount = 0.0;

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
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
                'Thank you for shopping with ${AppConstants.appName}!',
                style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 8),
              ),
              pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 8),
              ),
            ],
          ),
        ),
        build: (context) => [
          _header(logo, order),
          pw.SizedBox(height: 18),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(child: _customerDetails(order, placedAt)),
              pw.SizedBox(width: 16),
              pw.Expanded(child: _statusDetails(order)),
            ],
          ),
          pw.SizedBox(height: 20),
          _itemsTable(order),
          pw.SizedBox(height: 16),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: _totals(order, discount),
          ),
        ],
      ),
    );
    return document.save();
  }

  static pw.Widget _header(pw.MemoryImage? logo, OrderModel order) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.green800, width: 1.4),
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Row(
            children: [
              if (logo != null) ...[
                pw.Container(height: 42, width: 42, child: pw.Image(logo)),
                pw.SizedBox(width: 10),
              ],
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    AppConstants.appName.toUpperCase(),
                    style: pw.TextStyle(
                      color: PdfColors.green800,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  pw.Text(
                    'Grocery delivery',
                    style: const pw.TextStyle(
                      color: PdfColors.grey600,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'DELIVERY RECEIPT',
                style: pw.TextStyle(
                  color: PdfColors.grey700,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              pw.Text(
                'Order #${order.orderId}',
                style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 9),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _customerDetails(OrderModel order, String placedAt) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _label('Billed to'),
          _value(
            order.customerName.isEmpty ? 'Customer' : order.customerName,
          ),
          pw.SizedBox(height: 6),
          _label('Phone'),
          _value(order.customerPhone),
          pw.SizedBox(height: 6),
          _label('Delivery address'),
          _value(
            order.customerAddress.isEmpty
                ? 'Not provided'
                : order.customerAddress,
          ),
          pw.SizedBox(height: 6),
          _label('Order date'),
          _value(placedAt),
        ],
      ),
    );
  }

  static pw.Widget _statusDetails(OrderModel order) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _label('Payment method'),
          _value(order.paymentMethod),
          pw.SizedBox(height: 6),
          _label('Payment status'),
          _value(order.paymentStatus),
          pw.SizedBox(height: 6),
          _label('Delivery status'),
          _value(order.orderStatus),
        ],
      ),
    );
  }

  static pw.Widget _label(String text) => pw.Text(
        text.toUpperCase(),
        style: pw.TextStyle(
          color: PdfColors.grey600,
          fontWeight: pw.FontWeight.bold,
          fontSize: 7.5,
        ),
      );

  static pw.Widget _value(String text) => pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 10),
      );

  static pw.Widget _itemsTable(OrderModel order) {
    final rows = <List<String>>[
      for (final item in order.items)
        [
          item.name,
          '${item.quantity} ${item.unit}',
          _money(item.price),
          _money(item.lineTotal),
        ],
      if (order.photoListAmount > 0)
        ['Shopping-list photo items', '-', '-', _money(order.photoListAmount)],
      if (order.manualListAmount > 0)
        ['Manual grocery list', '-', '-', _money(order.manualListAmount)],
    ];
    if (rows.isEmpty) {
      return pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Text(
          'No itemized products on this order.',
          style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 9),
        ),
      );
    }
    return pw.TableHelper.fromTextArray(
      headers: const ['Item', 'Qty', 'Unit price', 'Amount'],
      data: rows,
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
        fontSize: 9,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.green800),
      cellStyle: const pw.TextStyle(fontSize: 9.5),
      cellAlignments: const {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.center,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
      },
      cellHeight: 22,
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
    );
  }

  static pw.Widget _totals(OrderModel order, double discount) {
    return pw.Container(
      width: 220,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _totalRow('Subtotal', _money(order.subtotal)),
          _totalRow('Delivery fee', _money(order.deliveryCharge)),
          if (order.serviceCharge > 0)
            _totalRow('Service charge', _money(order.serviceCharge)),
          if (discount > 0) _totalRow('Discount', '-${_money(discount)}'),
          pw.Divider(color: PdfColors.grey400, height: 14),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Total',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              pw.Text(
                _money(order.totalAmount - discount),
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                  color: PdfColors.green800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _totalRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 9.5)),
          pw.Text(value, style: const pw.TextStyle(fontSize: 9.5)),
        ],
      ),
    );
  }

  static String _money(double amount) =>
      '${AppConstants.currency} ${amount.toStringAsFixed(2)}';

  static Future<pw.MemoryImage?> _loadLogo() async {
    try {
      final data = await rootBundle.load(AppConstants.appLogoAsset);
      return pw.MemoryImage(data.buffer.asUint8List());
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
