import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yanzee_app/core/theme/app_status_colors.dart';
import 'package:yanzee_app/core/theme/app_theme.dart';
import 'package:yanzee_app/core/theme/seller_form_theme.dart';
import 'package:yanzee_app/core/utils/format_price.dart';
import 'package:yanzee_app/data/models/inventory.dart';
import 'package:yanzee_app/data/models/product_batches.dart';
import 'package:yanzee_app/features/seller/widgets/providers/seller_inventory_provider.dart';

/// The received lots (batches) of one stock row, with how much of each is
/// left. Opened by tapping a card on the Inventory screen.
class ProductBatchesScreen extends ConsumerWidget {
  const ProductBatchesScreen({super.key, required this.item});

  final StockItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = (productId: item.productId, variantId: item.variantId);
    final async = ref.watch(productBatchesProvider(query));

    return SellerFormTheme(
      child: Scaffold(
        appBar: AppBar(title: const Text('Stock batches')),
        body: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    e.toString().replaceFirst('Exception: ', ''),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () =>
                        ref.invalidate(productBatchesProvider(query)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: (batches) => RefreshIndicator(
            onRefresh: () => ref.refresh(productBatchesProvider(query).future),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: batches == null
                  ? const [
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
                        child: Center(child: Text('No store loaded.')),
                      ),
                    ]
                  : [
                      _Header(batches: batches, title: item.name),
                      const SizedBox(height: 16),
                      if (batches.variants.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(child: Text('No batches yet.')),
                        )
                      else
                        for (var i = 0; i < batches.variants.length; i++) ...[
                          SellerReveal(
                            index: i < 6 ? i : 6,
                            child: _VariantSection(
                              variant: batches.variants[i],
                              showName:
                                  batches.variants.length > 1 ||
                                  batches.hasVariants,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                    ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.batches, required this.title});

  final ProductBatches batches;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    Widget tile(String label, String value) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );

    return Material(
      color: scheme.surfaceContainerLowest,
      elevation: 1,
      shadowColor: scheme.shadow.withValues(alpha: 0.06),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.r2xl),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              batches.productName.isEmpty ? title : batches.productName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                tile('Batches', '${batches.batchCount}'),
                tile('Received', '${batches.totalReceived}'),
                tile('Left', '${batches.totalRemaining}'),
                tile('Cost', formatPrice(batches.totalCost)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VariantSection extends StatelessWidget {
  const _VariantSection({required this.variant, required this.showName});

  final VariantBatches variant;
  final bool showName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SellerSectionCard(
      icon: Icons.layers_outlined,
      title: showName ? variant.name : 'Batches',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${variant.batchCount} batch${variant.batchCount == 1 ? '' : 'es'}'
            ' · ${variant.totalRemaining} of ${variant.totalReceived} left'
            ' · ${formatPrice(variant.totalCost)} at cost',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          if (variant.batches.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No batches yet. Add stock with Stock in.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            )
          else
            for (var i = 0; i < variant.batches.length; i++)
              _BatchTile(
                batch: variant.batches[i],
                last: i == variant.batches.length - 1,
              ),
          if (variant.batchCount > variant.batches.length)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Showing the latest ${variant.batches.length} of ${variant.batchCount} batches.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BatchTile extends StatelessWidget {
  const _BatchTile({required this.batch, required this.last});

  final StockBatch batch;
  final bool last;

  static final _date = DateFormat('dd MMM yyyy');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final status = context.status;
    final s = batch.stock;
    final progress = s.received == 0 ? 0.0 : s.remaining / s.received;

    // Expiry text and colour.
    String? expiryText;
    Color expiryColor = scheme.onSurfaceVariant;
    final expiry = batch.expiryDate;
    if (expiry != null) {
      final days = expiry.difference(DateTime.now()).inDays;
      if (expiry.isBefore(DateTime.now())) {
        expiryText = 'Expired ${_date.format(expiry)}';
        expiryColor = status.dangerFg;
      } else if (days <= 30) {
        expiryText =
            'Expires ${_date.format(expiry)} ($days day${days == 1 ? '' : 's'} left)';
        expiryColor = status.warningFg;
      } else {
        expiryText = 'Expires ${_date.format(expiry)}';
      }
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      batch.label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    '${s.remaining} left',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                [
                  if (batch.outletName != null) batch.outletName!,
                  if (batch.createdAt != null)
                    'Received ${_date.format(batch.createdAt!.toLocal())}',
                ].join(' · '),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  color: scheme.primary,
                  backgroundColor: scheme.surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Received ${s.received} · Used ${s.used}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              Text(
                '${formatPrice(batch.unitCost)} each · ${formatPrice(batch.totalCost)} total',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              if (expiryText != null) ...[
                const SizedBox(height: 2),
                Text(
                  expiryText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: expiryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (!last) Divider(height: 1, color: scheme.outlineVariant),
      ],
    );
  }
}