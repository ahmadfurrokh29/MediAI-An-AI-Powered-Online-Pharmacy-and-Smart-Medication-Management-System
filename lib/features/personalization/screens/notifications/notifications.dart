import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:med/common/widgets/appbar/appbar.dart';
import 'package:med/features/personalization/screens/mymedication/my_medication.dart';
import 'package:med/utils/constants/colors.dart';
import 'package:med/utils/constants/sizes.dart';
import 'package:med/utils/helpers/helper_functions.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = MHelperFunctions.isDarkMode(context);
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: MAppBar(
        title: Text(
          'Notifications',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        showBackArrow: true,
        actions: [
          if (uid != null)
            TextButton(
              onPressed: () => _markAllRead(uid),
              child: Text(
                'Mark all read',
                style: TextStyle(fontSize: 12, color: MColors.primary),
              ),
            ),
        ],
      ),
      body: uid == null
          ? const Center(child: Text('Please log in to view notifications.'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Users')
                  .doc(uid)
                  .collection('Notifications')
                  .orderBy('createdAt', descending: true)
                  .limit(50)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return _buildFallbackList(uid, dark);
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState(dark);
                }

                final docs = snapshot.data!.docs;
                return ListView.separated(
                  padding: const EdgeInsets.all(MSizes.defaultSpace),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: MSizes.spaceBtwItems / 2),
                  itemBuilder: (context, index) {
                    return _NotificationTile(doc: docs[index], dark: dark);
                  },
                );
              },
            ),
    );
  }

  Widget _buildFallbackList(String uid, bool dark) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Users')
          .doc(uid)
          .collection('Notifications')
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(dark);
        }

        final docs = snapshot.data!.docs.toList();
        docs.sort((a, b) {
          final aTs = a['createdAt'];
          final bTs = b['createdAt'];
          if (aTs is Timestamp && bTs is Timestamp) {
            return bTs.compareTo(aTs);
          }
          return 0;
        });

        return ListView.separated(
          padding: const EdgeInsets.all(MSizes.defaultSpace),
          itemCount: docs.length,
          separatorBuilder: (_, __) =>
              const SizedBox(height: MSizes.spaceBtwItems / 2),
          itemBuilder: (context, index) {
            return _NotificationTile(doc: docs[index], dark: dark);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(bool dark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.notification,
            size: 80,
            color: dark ? Colors.grey.shade600 : Colors.grey.shade300,
          ),
          const SizedBox(height: MSizes.spaceBtwItems),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: dark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: MSizes.xs),
          Text(
            'You\'ll see announcements and updates here.',
            style: TextStyle(
              fontSize: 14,
              color: dark ? Colors.grey.shade500 : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _markAllRead(String uid) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('Users')
          .doc(uid)
          .collection('Notifications')
          .where('isRead', isEqualTo: false)
          .get();

      if (snap.docs.isEmpty) return;

      for (int i = 0; i < snap.docs.length; i += 400) {
        final chunk = snap.docs.skip(i).take(400);
        final batch = FirebaseFirestore.instance.batch();
        for (final doc in chunk) {
          batch.update(doc.reference, {'isRead': true});
        }
        await batch.commit();
      }
    } catch (_) {}
  }
}

// ═══════════════════════════════════════════════════════════════
// Notification tile widget
// ═══════════════════════════════════════════════════════════════
class _NotificationTile extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final bool dark;

  const _NotificationTile({required this.doc, required this.dark});

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final title = data['title'] as String? ?? 'Notification';
    final body = data['body'] as String? ?? '';
    final type = data['type'] as String? ?? '';
    final isRead = data['isRead'] as bool? ?? false;
    final createdBy = data['createdBy'] as String? ?? '';

    DateTime createdAt = DateTime.now();
    final ts = data['createdAt'];
    if (ts is Timestamp) createdAt = ts.toDate();

    final timeAgo = _formatTimeAgo(createdAt);

    return GestureDetector(
      onTap: () {
        // Mark as read on tap
        if (!isRead) {
          doc.reference.update({'isRead': true}).catchError((_) {});
        }
        // Navigate to in-stock tab for stock alerts
        if (type == 'stock_alert') {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const MMyMedicationScreen(initialTab: 1),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(MSizes.md),
        decoration: BoxDecoration(
          color: isRead
              ? (dark ? Colors.grey.shade900 : Colors.white)
              : (dark
                    ? MColors.primary.withValues(alpha: 0.08)
                    : MColors.primary.withValues(alpha: 0.04)),
          borderRadius: BorderRadius.circular(MSizes.borderRadiusSm + 8),
          border: Border.all(
            color: isRead
                ? (dark ? Colors.grey.shade800 : Colors.grey.shade200)
                : MColors.primary.withValues(alpha: 0.3),
            width: isRead ? 1 : 1.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Unread indicator bar ──
            if (!isRead)
              Container(
                width: 4,
                height: 52,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: MColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

            // ── Icon ──
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: type == 'stock_alert'
                    ? Colors.orange.withValues(alpha: 0.12)
                    : type == 'medicine_alarm'
                    ? MColors.primary.withValues(alpha: 0.12)
                    : type == 'announcement'
                    ? MColors.primary.withValues(alpha: 0.12)
                    : Colors.blue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                type == 'stock_alert'
                    ? Iconsax.box
                    : type == 'medicine_alarm'
                    ? Iconsax.health
                    : type == 'announcement'
                    ? Iconsax.speaker
                    : Iconsax.notification,
                color: type == 'stock_alert'
                    ? Colors.orange
                    : type == 'medicine_alarm'
                    ? MColors.primary
                    : type == 'announcement'
                    ? MColors.primary
                    : Colors.blue,
                size: 22,
              ),
            ),
            const SizedBox(width: MSizes.spaceBtwItems),

            // ── Content ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isRead
                                ? FontWeight.w500
                                : FontWeight.w700,
                            color: dark ? Colors.white : MColors.textPrimary,
                          ),
                        ),
                      ),
                      // ── Unread dot ──
                      if (!isRead)
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: MColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  if (body.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      body,
                      style: TextStyle(
                        fontSize: 13,
                        color: dark
                            ? Colors.grey.shade400
                            : MColors.textSecondary,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Iconsax.clock,
                        size: 12,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        timeAgo,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      if (createdBy.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          '· by $createdBy',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                      const Spacer(),
                      // ── Delete button ──
                      GestureDetector(
                        onTap: () => _confirmDelete(context),
                        child: Icon(
                          Iconsax.trash,
                          size: 18,
                          color: Colors.red.shade400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Notification?'),
        content: const Text('This notification will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              doc.reference.delete().catchError((_) {});
            },
            child: Text(
              'Delete',
              style: TextStyle(
                color: Colors.red.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM dd, yyyy').format(dateTime);
  }
}
