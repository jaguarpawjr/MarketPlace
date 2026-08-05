import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FarmerNameBadge extends StatelessWidget {
  final String farmerId;
  final String name;
  final TextStyle? textStyle;
  final bool showStatusBadge;

  const FarmerNameBadge({
    super.key,
    required this.farmerId,
    required this.name,
    this.textStyle,
    this.showStatusBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    if (farmerId.isEmpty) {
      return Text(name, style: textStyle);
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(farmerId)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? <String, dynamic>{};
        final approved =
            data['verificationStatus'] == 'approved' ||
            data['idVerified'] == true;

        return Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 6,
          children: [
            Text(name, style: textStyle),
            if (showStatusBadge)
              _StatusChip(
                label: approved ? 'Approved' : 'Pending',
                isApproved: approved,
              ),
          ],
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool isApproved;

  const _StatusChip({required this.label, required this.isApproved});

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isApproved
        ? const Color(0xFFDCFCE7)
        : const Color(0xFFF3F4F6);
    final foregroundColor = isApproved
        ? const Color(0xFF15803D)
        : const Color(0xFF4B5563);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foregroundColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
