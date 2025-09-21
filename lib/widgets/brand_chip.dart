import 'package:connectly_app/theme/theme.dart';
import 'package:connectly_app/widgets/spacers.dart';
import 'package:flutter/material.dart';

class BrandChip extends StatelessWidget {
  final String label;
  const BrandChip(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).extension<AppBrand>()!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: b.brand,
        borderRadius: BorderRadius.circular(b.radius),
        boxShadow: b.softShadow,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge!.copyWith(color: b.ink),
      ),
    );
  }
}
