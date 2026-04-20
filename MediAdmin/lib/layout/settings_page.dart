import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../features/auth/controllers/auth_controller.dart';

// ══════════════════════════════════════════════════════════════════════════════
// Settings Page — Notifications · Announcements · Theme · Change Password
// ══════════════════════════════════════════════════════════════════════════════

class SettingsPage extends StatefulWidget {
  final VoidCallback? onChangePassword;
  const SettingsPage({super.key, this.onChangePassword});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with SingleTickerProviderStateMixin {
  final _db = FirebaseFirestore.instance;
  bool _isDarkMode = false;

  // Sub-view state: null = main settings, 'notifications' = notifications detail
  String? _activeSubView;

  // Announcement form
  final _announceTitleCtrl = TextEditingController();
  final _announceBodyCtrl = TextEditingController();
  bool _isSendingAnnouncement = false;

  // Tabs for notifications sub-view
  late TabController _tabController;

  // Track order IDs that have been marked as read
  final Set<String> _readOrderIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _announceTitleCtrl.dispose();
    _announceBodyCtrl.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // ── Send Announcement — dual-write: Announcements collection + each user's Notifications ──
  Future<void> _sendAnnouncement() async {
    final title = _announceTitleCtrl.text.trim();
    final body = _announceBodyCtrl.text.trim();
    if (title.isEmpty || body.isEmpty) {
      Get.snackbar(
        'Error',
        'Please fill in both title and message.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red,
      );
      return;
    }

    setState(() => _isSendingAnnouncement = true);
    try {
      final authCtrl = Get.find<AuthController>();
      final now = Timestamp.now();
      final announcementData = {
        'title': title,
        'body': body,
        'type': 'announcement',
        'createdAt': now,
        'createdBy': authCtrl.user.value.fullName,
        'createdByEmail': authCtrl.user.value.email,
        'isRead': false,
      };

      // 1. Write to top-level Announcements collection (admin reads this)
      await _db.collection('Announcements').add(announcementData);

      // 2. Write to each user's Notifications subcollection (app reads this)
      final usersSnapshot = await _db.collection('Users').get();
      final userDocs = usersSnapshot.docs;
      for (int i = 0; i < userDocs.length; i += 400) {
        final chunk = userDocs.skip(i).take(400);
        final batch = _db.batch();
        for (final userDoc in chunk) {
          final notifRef = _db
              .collection('Users')
              .doc(userDoc.id)
              .collection('Notifications')
              .doc();
          batch.set(notifRef, announcementData);
        }
        await batch.commit();
      }

      _announceTitleCtrl.clear();
      _announceBodyCtrl.clear();
      Get.snackbar(
        'Success',
        'Announcement published to ${userDocs.length} users.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade50,
        colorText: Colors.green,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to send announcement: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red,
      );
    } finally {
      setState(() => _isSendingAnnouncement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show notifications sub-view
    if (_activeSubView == 'notifications') {
      return _buildNotificationsSubView();
    }

    // Main settings list
    final authController = Get.find<AuthController>();
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _buildProfileCard(authController),
          const SizedBox(height: 24),
          _buildGeneralSettingsSection(),
          const SizedBox(height: 24),
          _buildSecuritySection(),
          const SizedBox(height: 24),
          _buildAboutSection(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ══════════════════════ PROFILE CARD ══════════════════════
  Widget _buildProfileCard(AuthController authController) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Obx(() {
        final user = authController.user.value;
        final displayName = user.fullName.trim().isEmpty
            ? 'Admin'
            : user.fullName;
        final email = user.email.isEmpty ? 'admin@mediai.com' : user.email;
        final initials = displayName
            .split(' ')
            .where((w) => w.isNotEmpty)
            .take(2)
            .map((w) => w[0].toUpperCase())
            .join();

        return Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.green,
              child: Text(
                initials.isEmpty ? 'A' : initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                ),
              ),
            ),
            const SizedBox(width: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    user.role.isEmpty ? 'Admin' : user.role,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      }),
    );
  }

  // ══════════════════════ NOTIFICATIONS SUB-VIEW ══════════════════════
  Widget _buildNotificationsSubView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        // Back button
        Row(
          children: [
            IconButton(
              onPressed: () => setState(() => _activeSubView = null),
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Back to Settings',
            ),
            const SizedBox(width: 8),
            const Text(
              'Notifications & Announcements',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Tab bar
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF4299E1),
            unselectedLabelColor: Colors.grey.shade600,
            indicatorColor: const Color(0xFF4299E1),
            indicatorWeight: 3,
            tabs: const [
              Tab(
                icon: Icon(Icons.notifications_active),
                text: 'Order Notifications',
              ),
              Tab(icon: Icon(Icons.campaign), text: 'Announcements'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [_buildOrderNotificationsTab(), _buildAnnouncementsTab()],
          ),
        ),
      ],
    );
  }

  // ── Order Notifications tab ──
  Widget _buildOrderNotificationsTab() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notifications_active,
                size: 22,
                color: Colors.orange.shade700,
              ),
              const SizedBox(width: 10),
              const Text(
                'Recent Orders',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _markAllNotificationsRead,
                icon: const Icon(Icons.done_all, size: 16),
                label: const Text(
                  'Mark all read',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _db
                  .collection('Orders')
                  .orderBy('createdAt', descending: true)
                  .limit(30)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No new order notifications',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                final orders = snapshot.data!.docs;
                // Store latest order IDs so mark-all-read can reference them
                _latestOrderIds = orders.map((d) => d.id).toList();
                return ListView.separated(
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final data = orders[index].data() as Map<String, dynamic>;
                    final customerName =
                        data['customerName'] as String? ??
                        data['CustomerName'] as String? ??
                        'Customer';
                    final status =
                        data['orderStatus'] as String? ??
                        data['OrderStatus'] as String? ??
                        'Pending';
                    final total =
                        (data['totalAmount'] as num? ??
                                data['TotalAmount'] as num? ??
                                0)
                            .toDouble();
                    final ts = data['createdAt'] ?? data['CreatedAt'];
                    DateTime createdAt = DateTime.now();
                    if (ts is Timestamp) createdAt = ts.toDate();

                    final isNew =
                        DateTime.now().difference(createdAt).inHours < 24 &&
                        !_readOrderIds.contains(orders[index].id);

                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: isNew
                            ? Colors.orange.shade50
                            : Colors.grey.shade100,
                        child: Icon(
                          Icons.shopping_cart,
                          size: 18,
                          color: isNew
                              ? Colors.orange.shade700
                              : Colors.grey.shade500,
                        ),
                      ),
                      title: Text(
                        '$customerName placed a new order',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isNew
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        'Status: $status · \$${total.toStringAsFixed(2)} · ${DateFormat('MMM dd, HH:mm').format(createdAt)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      trailing: isNew
                          ? Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.orange,
                                shape: BoxShape.circle,
                              ),
                            )
                          : null,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _markAllNotificationsRead() {
    // Mark all currently loaded order notification IDs as read
    setState(() {
      _readOrderIds.addAll(_latestOrderIds);
    });
    Get.snackbar(
      'Notifications',
      'All notifications marked as read.',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  // Keep track of the latest order IDs from the stream for mark-all-read
  List<String> _latestOrderIds = [];

  // ── Announcements tab ──
  Widget _buildAnnouncementsTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Create announcement form
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 8),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.campaign, size: 22, color: Colors.blue.shade700),
                    const SizedBox(width: 10),
                    const Text(
                      'Create Announcement',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Publish an announcement to all MediAI app users. It will appear in their notification section on the profile page.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _announceTitleCtrl,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    hintText: 'e.g. New feature available!',
                    filled: true,
                    fillColor: const Color(0xFFF7FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFF4299E1),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _announceBodyCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Message',
                    hintText: 'Enter announcement message...',
                    filled: true,
                    fillColor: const Color(0xFFF7FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFF4299E1),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSendingAnnouncement
                        ? null
                        : _sendAnnouncement,
                    icon: _isSendingAnnouncement
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send, size: 18),
                    label: Text(
                      _isSendingAnnouncement
                          ? 'Publishing...'
                          : 'Publish Announcement',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4299E1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Recent announcements — read from first user's Notifications subcollection
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 8),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recent Announcements',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Published announcements visible to all app users.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 16),
                SizedBox(height: 300, child: _buildRecentAnnouncementsList()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Fetches recent announcements from top-level Announcements collection.
  Widget _buildRecentAnnouncementsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection('Announcements')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading announcements.',
              style: TextStyle(color: Colors.red.shade400),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No announcements yet.',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          );
        }
        final docs = snapshot.data!.docs;
        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final d = docs[index].data() as Map<String, dynamic>;
            final ts = d['createdAt'];
            DateTime date = DateTime.now();
            if (ts is Timestamp) date = ts.toDate();
            return ListTile(
              dense: true,
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.blue.shade50,
                child: Icon(
                  Icons.campaign,
                  size: 16,
                  color: Colors.blue.shade700,
                ),
              ),
              title: Text(
                d['title'] ?? '',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                '${d['body'] ?? ''}\n${DateFormat('MMM dd, yyyy HH:mm').format(date)} · by ${d['createdBy'] ?? 'Admin'}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              trailing: IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: Colors.red.shade300,
                ),
                tooltip: 'Delete announcement',
                onPressed: () => _deleteAnnouncement(docs[index].id, d),
              ),
            );
          },
        );
      },
    );
  }

  /// Deletes an announcement from the Announcements collection and all users' Notifications.
  Future<void> _deleteAnnouncement(
    String announcementDocId,
    Map<String, dynamic> announcement,
  ) async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete Announcement'),
        content: const Text(
          'This will remove the announcement from all users. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      // 1. Delete from top-level Announcements collection
      await _db.collection('Announcements').doc(announcementDocId).delete();

      // 2. Delete from each user's Notifications subcollection
      final usersSnap = await _db.collection('Users').get();
      for (int i = 0; i < usersSnap.docs.length; i += 400) {
        final chunk = usersSnap.docs.skip(i).take(400);
        final batch = _db.batch();
        for (final userDoc in chunk) {
          final notifsSnap = await _db
              .collection('Users')
              .doc(userDoc.id)
              .collection('Notifications')
              .where('title', isEqualTo: announcement['title'])
              .where('body', isEqualTo: announcement['body'])
              .where('type', isEqualTo: 'announcement')
              .limit(1)
              .get();
          for (final doc in notifsSnap.docs) {
            batch.delete(doc.reference);
          }
        }
        await batch.commit();
      }

      Get.snackbar(
        'Deleted',
        'Announcement removed from all users.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red,
      );
    }
  }

  // ══════════════════════ NOTIFICATIONS SETTINGS ITEM WITH BADGE ══════════════════════
  Widget _buildNotificationsSettingsItem() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection('Orders')
          .orderBy('createdAt', descending: true)
          .limit(30)
          .snapshots(),
      builder: (context, snapshot) {
        int unreadCount = 0;
        if (snapshot.hasData) {
          for (final doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final ts = data['createdAt'] ?? data['CreatedAt'];
            DateTime createdAt = DateTime.now();
            if (ts is Timestamp) createdAt = ts.toDate();
            final isNew =
                DateTime.now().difference(createdAt).inHours < 24 &&
                !_readOrderIds.contains(doc.id);
            if (isNew) unreadCount++;
          }
        }

        return InkWell(
          onTap: () => setState(() => _activeSubView = 'notifications'),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.notifications_active,
                    size: 22,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Notifications',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Order notifications & send announcements',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: Colors.grey.shade400),
              ],
            ),
          ),
        );
      },
    );
  }

  // ══════════════════════ GENERAL SETTINGS ══════════════════════
  Widget _buildGeneralSettingsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'General Settings',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // Notifications — clickable item that opens sub-view (with unread badge)
          _buildNotificationsSettingsItem(),
          const Divider(height: 1),

          // Theme toggle
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _isDarkMode ? Icons.dark_mode : Icons.light_mode,
                    size: 22,
                    color: _isDarkMode
                        ? Colors.indigo.shade400
                        : Colors.orange.shade600,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Theme',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _isDarkMode ? 'Dark mode' : 'Light mode',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 44,
                  height: 24,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Switch(
                      value: _isDarkMode,
                      activeColor: Colors.indigo,
                      onChanged: (val) {
                        setState(() => _isDarkMode = val);
                        Get.changeThemeMode(
                          val ? ThemeMode.dark : ThemeMode.light,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════ SECURITY ══════════════════════
  Widget _buildSecuritySection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Security',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _settingsItem(
            icon: Icons.lock_outline,
            title: 'Change Password',
            subtitle: 'Update your password',
            onTap: () {
              if (widget.onChangePassword != null) {
                widget.onChangePassword!();
              }
            },
          ),
        ],
      ),
    );
  }

  // ══════════════════════ ABOUT ══════════════════════
  Widget _buildAboutSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _settingsItem(
            icon: Icons.info_outline,
            title: 'MediAI Admin Panel',
            subtitle: 'Version 1.0.0',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  // ══════════════════════ REUSABLE ITEM ══════════════════════
  Widget _settingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 22, color: Colors.grey.shade700),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
