import 'package:flutter/material.dart';

/// One "Label ........ value" line. Shows a dash when the value is empty.
class SellerInfoRow extends StatelessWidget {
  const SellerInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.last = false,
  });

  final String label;
  final String? value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = (value == null || value!.trim().isEmpty) ? '—' : value!;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 104,
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
              Expanded(
                child: Text(
                  text,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        if (!last)
          Divider(
            height: 1,
            color: scheme.outlineVariant.withValues(alpha: 0.5),
          ),
      ],
    );
  }
}

/// Small rounded label such as "Published" or "Hidden".
class SellerStatusPill extends StatelessWidget {
  const SellerStatusPill({
    super.key,
    required this.text,
    required this.positive,
  });

  final String text;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = positive ? const Color(0xFF2E9E2E) : scheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

/// Logo or image with a placeholder icon. Round or softly rounded square.
class SellerDetailAvatar extends StatelessWidget {
  const SellerDetailAvatar({
    super.key,
    required this.url,
    required this.icon,
    this.circular = false,
    this.size = 96,
  });

  final String? url;
  final IconData icon;
  final bool circular;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget placeholder() => Container(
          width: size,
          height: size,
          color: scheme.surfaceContainerHighest,
          child: Icon(icon, size: size * 0.4, color: scheme.onSurfaceVariant),
        );

    return ClipRRect(
      borderRadius: BorderRadius.circular(circular ? size / 2 : size * 0.2),
      child: (url == null || url!.isEmpty)
          ? placeholder()
          : Image.network(
              url!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              cacheWidth: (size * 3).round(),
              errorBuilder: (_, __, ___) => placeholder(),
            ),
    );
  }
}