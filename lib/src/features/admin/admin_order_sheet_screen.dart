import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/models.dart';
import '../../services/shop_order_pdf_service.dart';
import '../customer/customer_screens.dart';

const _sheetBackground = Color(0xFFF3F7F4);
const _sheetInk = Color(0xFF14231C);
const _sheetMuted = Color(0xFF627168);
const _sheetLine = Color(0xFFDCE8DF);
const _sheetPrimary = Color(0xFF176B45);

class AdminOrderSheetScreen extends StatefulWidget {
  const AdminOrderSheetScreen({super.key, required this.order});

  final OrderModel order;

  @override
  State<AdminOrderSheetScreen> createState() => _AdminOrderSheetScreenState();
}

class _AdminOrderSheetScreenState extends State<AdminOrderSheetScreen> {
  Future<Uint8List>? _pdfFuture;
  var _isDownloading = false;
  var _isSharing = false;

  Future<Uint8List> _pdfBytes() {
    return _pdfFuture ??= ShopOrderPdfService.build(widget.order);
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final catalogQuantity =
        order.items.fold<int>(0, (sum, item) => sum + item.quantity);
    return Scaffold(
      backgroundColor: _sheetBackground,
      appBar: AppBar(
        title: const Text(
          'Shop order sheet',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: _sheetBackground,
        foregroundColor: _sheetInk,
      ),
      body: ListView(
        physics: appRefreshScrollPhysics,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
        children: [
          _SheetHero(
            order: order,
            catalogQuantity: catalogQuantity,
          ),
          const SizedBox(height: 14),
          _SheetSection(
            number: '1',
            title: 'Catalog cart items',
            subtitle: order.items.isEmpty
                ? 'No catalog products'
                : '${order.items.length} products, $catalogQuantity total quantity',
            icon: Icons.shopping_basket_outlined,
            child: order.items.isEmpty
                ? const _SheetEmpty(
                    message: 'No catalog cart items in this order.',
                  )
                : Column(
                    children: [
                      for (var index = 0;
                          index < order.items.length;
                          index++) ...[
                        _CatalogOrderItem(
                          index: index + 1,
                          item: order.items[index],
                        ),
                        if (index != order.items.length - 1)
                          const Divider(height: 18),
                      ],
                    ],
                  ),
          ),
          const SizedBox(height: 14),
          _SheetSection(
            number: '2',
            title: 'Shopping-list photo',
            subtitle: order.hasUpload
                ? 'Customer uploaded list'
                : 'No photo provided',
            icon: Icons.image_outlined,
            child: order.hasUpload
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: AspectRatio(
                      aspectRatio: 1.1,
                      child: ProductImage(
                        url: order.uploadedImageUrl,
                        radius: 0,
                      ),
                    ),
                  )
                : const _SheetEmpty(
                    message: 'No shopping-list photo was uploaded.',
                  ),
          ),
          const SizedBox(height: 14),
          _SheetSection(
            number: '3',
            title: 'Typed manual list',
            subtitle: order.manualListLines.isEmpty
                ? 'No typed items'
                : '${order.manualListLines.length} list lines',
            icon: Icons.edit_note,
            child: order.manualListLines.isEmpty
                ? const _SheetEmpty(
                    message: 'No typed manual-list items were added.',
                  )
                : Column(
                    children: [
                      for (var index = 0;
                          index < order.manualListLines.length;
                          index++) ...[
                        _ManualOrderItem(
                          index: index + 1,
                          text: order.manualListLines[index],
                        ),
                        if (index != order.manualListLines.length - 1)
                          const SizedBox(height: 8),
                      ],
                    ],
                  ),
          ),
          if (order.customerNotes.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            _SheetSection(
              number: '!',
              title: 'Customer note',
              subtitle: 'Check before purchasing',
              icon: Icons.sticky_note_2_outlined,
              child: SelectableText(
                order.customerNotes.trim(),
                style: const TextStyle(
                  color: _sheetInk,
                  fontWeight: FontWeight.w700,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: const Border(top: BorderSide(color: _sheetLine)),
            boxShadow: [
              BoxShadow(
                color: _sheetInk.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isDownloading || _isSharing ? null : _downloadPdf,
                  icon: _isDownloading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download_outlined),
                  label: const Text('Download PDF'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _isDownloading || _isSharing ? null : _sharePdf,
                  icon: _isSharing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.share_outlined),
                  label: const Text('Send PDF'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _downloadPdf() async {
    setState(() => _isDownloading = true);
    try {
      final bytes = await _pdfBytes();
      await Printing.layoutPdf(
        name: ShopOrderPdfService.fileName(widget.order),
        onLayout: (_) async => bytes,
      );
    } catch (error) {
      if (mounted) {
        showSnack(context, 'Could not create the PDF. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  Future<void> _sharePdf() async {
    setState(() => _isSharing = true);
    try {
      final bytes = await _pdfBytes();
      await Printing.sharePdf(
        bytes: bytes,
        filename: ShopOrderPdfService.fileName(widget.order),
      );
    } catch (error) {
      if (mounted) {
        showSnack(context, 'Could not share the PDF. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }
}

class _SheetHero extends StatelessWidget {
  const _SheetHero({
    required this.order,
    required this.catalogQuantity,
  });

  final OrderModel order;
  final int catalogQuantity;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _sheetPrimary,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _sheetPrimary.withValues(alpha: 0.22),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.storefront_outlined,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${_shortOrderId(order.orderId)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      DateFormat.yMMMd().add_jm().format(order.createdAt),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.76),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Everything the shop needs in one view',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeroChip(
                icon: Icons.shopping_cart_outlined,
                label: '$catalogQuantity cart qty',
              ),
              _HeroChip(
                icon: Icons.image_outlined,
                label: order.hasUpload ? 'Photo attached' : 'No photo',
              ),
              _HeroChip(
                icon: Icons.edit_note,
                label: '${order.manualListLines.length} manual lines',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 15),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetSection extends StatelessWidget {
  const _SheetSection({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  final String number;
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _sheetLine),
        boxShadow: [
          BoxShadow(
            color: _sheetInk.withValues(alpha: 0.045),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _sheetPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(icon, color: _sheetPrimary, size: 23),
                    Positioned(
                      right: 3,
                      top: 2,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 15),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 3,
                          vertical: 1,
                        ),
                        decoration: const BoxDecoration(
                          color: _sheetPrimary,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _sheetInk,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: _sheetMuted,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _CatalogOrderItem extends StatelessWidget {
  const _CatalogOrderItem({required this.index, required this.item});

  final int index;
  final OrderItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 58,
          height: 58,
          child: item.imageUrl.trim().isEmpty
              ? DecoratedBox(
                  decoration: BoxDecoration(
                    color: _sheetBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _sheetLine),
                  ),
                  child: Center(
                    child: Text(
                      '$index',
                      style: const TextStyle(
                        color: _sheetMuted,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                )
              : ProductImage(url: item.imageUrl),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: const TextStyle(
                  color: _sheetInk,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
              if (item.shopName.trim().isNotEmpty)
                Text(
                  item.shopName,
                  style: const TextStyle(
                    color: _sheetMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              const SizedBox(height: 3),
              Text(
                '${item.quantity} x ${item.price.money} / ${item.unit}',
                style: const TextStyle(
                  color: _sheetMuted,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              if (!item.isAvailable)
                const Text(
                  'Marked unavailable',
                  style: TextStyle(
                    color: Color(0xFFC83A2B),
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          item.lineTotal.money,
          style: const TextStyle(
            color: _sheetPrimary,
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _ManualOrderItem extends StatelessWidget {
  const _ManualOrderItem({required this.index, required this.text});

  final int index;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _sheetBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _sheetLine),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _sheetPrimary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$index',
              style: const TextStyle(
                color: _sheetPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SelectableText(
              text,
              style: const TextStyle(
                color: _sheetInk,
                fontWeight: FontWeight.w800,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetEmpty extends StatelessWidget {
  const _SheetEmpty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _sheetBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: _sheetMuted,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

String _shortOrderId(String orderId) {
  if (orderId.length <= 8) {
    return orderId;
  }
  return orderId.substring(0, 8);
}
