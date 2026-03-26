import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:med/common/widgets/custom_shapes/containers/rounded_container.dart';
import 'package:med/utils/constants/colors.dart';
import 'package:med/utils/constants/sizes.dart';
import 'package:med/utils/helpers/helper_functions.dart';

class MSigleAddress extends StatelessWidget {
  const MSigleAddress({
    super.key,
    required this.selectedAdress,
    required this.address,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  final bool selectedAdress;

  /// The address map: { name, phoneNumber, street, postalCode, city, state, country }
  final Map<String, dynamic> address;

  /// Called when the user taps the card / radio to select this address.
  final VoidCallback? onTap;

  /// Called when the user taps the edit icon.
  final VoidCallback? onEdit;

  /// Called when the user taps the delete icon.
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final dark = MHelperFunctions.isDarkMode(context);

    final name = address['name'] as String? ?? '';
    final phone = address['phoneNumber'] as String? ?? '';
    final houseNo = address['houseNo'] as String? ?? '';
    final street = address['street'] as String? ?? '';
    final city = address['city'] as String? ?? '';
    final state = address['state'] as String? ?? '';
    final postalCode = address['postalCode'] as String? ?? '';
    final country = address['country'] as String? ?? '';

    final addressLine = [
      houseNo,
      street,
      city,
      state,
      postalCode,
      country,
    ].where((p) => p.isNotEmpty).join(', ');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(MSizes.cardRadiusLg),
      child: MRoundedContainer(
        width: double.infinity,
        showBorder: true,
        padding: const EdgeInsets.all(MSizes.md),
        backgroundColor: selectedAdress
            ? MColors.primary.withValues(alpha: 0.08)
            : Colors.transparent,
        borderColor: selectedAdress
            ? MColors.primary
            : dark
                ? MColors.darkGrey
                : MColors.grey,
        margin: const EdgeInsets.only(bottom: MSizes.spaceBtwItems),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ── Radio Button ──
            Radio<bool>(
              value: true,
              groupValue: selectedAdress,
              onChanged: (_) => onTap?.call(),
              activeColor: MColors.primary,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: MSizes.sm),

            /// ── Address Details ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Name + action icons
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name.isNotEmpty ? name : 'No name',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (onEdit != null)
                        GestureDetector(
                          onTap: onEdit,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              Iconsax.edit,
                              size: 18,
                              color: dark
                                  ? MColors.light
                                  : MColors.dark.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      if (onDelete != null)
                        GestureDetector(
                          onTap: onDelete,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              Iconsax.trash,
                              size: 18,
                              color: Colors.redAccent,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: MSizes.sm / 2),

                  /// Phone number
                  if (phone.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.phone, size: 14, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                          phone,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: MSizes.sm / 2),
                  ],

                  /// Full address line
                  Text(
                    addressLine.isNotEmpty ? addressLine : 'No address saved',
                    softWrap: true,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
