import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../features/auth/controllers/auth_controller.dart';
import '../features/products/controllers/product_controller.dart';
import '../features/categories/controllers/category_controller.dart';
import '../features/subcategories/controllers/subcategory_controller.dart';
import '../features/brands/controllers/brand_controller.dart';
import '../features/banners/controllers/banner_controller.dart';
import '../features/orders/controllers/order_controller.dart';
import '../features/customers/controllers/customer_controller.dart';
import '../features/admins/controllers/admin_controller.dart';

class Topbar extends StatefulWidget {
  const Topbar({super.key, this.onSearchResultTap, this.onSettingsTap});

  /// Called when a search result is tapped.
  /// Passes section index and optional search query.
  final void Function(int sectionIndex, String query)? onSearchResultTap;

  /// Called when the settings button is tapped.
  final VoidCallback? onSettingsTap;

  @override
  State<Topbar> createState() => _TopbarState();
}

class _TopbarState extends State<Topbar> {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) _removeOverlay();
    });
  }

  @override
  void dispose() {
    _removeOverlay();
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) {
      _removeOverlay();
      return;
    }

    final results = <_SearchResult>[];

    // Search Products
    try {
      final productCtrl = Get.find<ProductController>();
      for (final p in productCtrl.products) {
        if (p.name.toLowerCase().contains(q) ||
            p.categoryName.toLowerCase().contains(q) ||
            p.brandName.toLowerCase().contains(q)) {
          results.add(
            _SearchResult(
              icon: Icons.inventory,
              title: p.name,
              subtitle: '${p.brandName} · ${p.categoryName}',
              section: 'Product',
              sectionIndex: 4,
            ),
          );
        }
        if (results.length >= 12) break;
      }
    } catch (_) {}

    // Search Categories
    try {
      final catCtrl = Get.find<CategoryController>();
      for (final c in catCtrl.categories) {
        if (c.name.toLowerCase().contains(q)) {
          results.add(
            _SearchResult(
              icon: Icons.category,
              title: c.name,
              subtitle: c.isActive ? 'Active' : 'Inactive',
              section: 'Category',
              sectionIndex: 1,
            ),
          );
        }
        if (results.length >= 12) break;
      }
    } catch (_) {}

    // Search Subcategories
    try {
      final subCtrl = Get.find<SubcategoryController>();
      for (final s in subCtrl.subcategories) {
        if (s.name.toLowerCase().contains(q) ||
            s.categoryName.toLowerCase().contains(q)) {
          results.add(
            _SearchResult(
              icon: Icons.layers,
              title: s.name,
              subtitle: s.categoryName,
              section: 'Subcategory',
              sectionIndex: 2,
            ),
          );
        }
        if (results.length >= 12) break;
      }
    } catch (_) {}

    // Search Brands
    try {
      final brandCtrl = Get.find<BrandController>();
      for (final b in brandCtrl.brands) {
        if (b.name.toLowerCase().contains(q)) {
          results.add(
            _SearchResult(
              icon: Icons.branding_watermark,
              title: b.name,
              subtitle: '${b.productCount} products',
              section: 'Brand',
              sectionIndex: 3,
            ),
          );
        }
        if (results.length >= 12) break;
      }
    } catch (_) {}

    // Search Banners
    try {
      final bannerCtrl = BannerController.instance;
      for (final b in bannerCtrl.banners) {
        if (b.title.toLowerCase().contains(q) ||
            b.description.toLowerCase().contains(q)) {
          results.add(
            _SearchResult(
              icon: Icons.flag,
              title: b.title,
              subtitle: b.isActive ? 'Active' : 'Inactive',
              section: 'Banner',
              sectionIndex: 7,
            ),
          );
        }
        if (results.length >= 12) break;
      }
    } catch (_) {}

    // Search Orders
    try {
      final orderCtrl = OrderController.instance;
      for (final o in orderCtrl.orders) {
        if (o.id.toLowerCase().contains(q) ||
            o.customerName.toLowerCase().contains(q) ||
            o.customerEmail.toLowerCase().contains(q)) {
          results.add(
            _SearchResult(
              icon: Icons.shopping_cart,
              title: '#${o.id.length > 8 ? o.id.substring(0, 8) : o.id}',
              subtitle: o.customerName,
              section: 'Order',
              sectionIndex: 6,
            ),
          );
        }
        if (results.length >= 12) break;
      }
    } catch (_) {}

    // Search Customers
    try {
      final custCtrl = CustomerController.instance;
      for (final c in custCtrl.customers) {
        if (c.fullName.toLowerCase().contains(q) ||
            c.email.toLowerCase().contains(q)) {
          results.add(
            _SearchResult(
              icon: Icons.people,
              title: c.fullName,
              subtitle: c.email,
              section: 'Customer',
              sectionIndex: 9,
            ),
          );
        }
        if (results.length >= 12) break;
      }
    } catch (_) {}

    // Search Admins
    try {
      final adminCtrl = Get.find<AdminController>();
      for (final a in adminCtrl.admins) {
        if (a.fullName.toLowerCase().contains(q) ||
            a.email.toLowerCase().contains(q)) {
          results.add(
            _SearchResult(
              icon: Icons.admin_panel_settings,
              title: a.fullName,
              subtitle: a.email,
              section: 'Admin',
              sectionIndex: 10,
            ),
          );
        }
        if (results.length >= 12) break;
      }
    } catch (_) {}

    // Limit to 12 total results
    final limited = results.take(12).toList();

    _removeOverlay();
    if (limited.isEmpty) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: 500,
        child: CompositedTransformFollower(
          link: _layerLink,
          offset: const Offset(0, 50),
          showWhenUnlinked: false,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 400),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: limited.length,
                itemBuilder: (_, i) {
                  final r = limited[i];
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      r.icon,
                      size: 20,
                      color: Colors.grey.shade600,
                    ),
                    title: Text(
                      r.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      r.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        r.section,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    onTap: () {
                      final query = _searchCtrl.text;
                      _searchCtrl.clear();
                      _removeOverlay();
                      _focusNode.unfocus();
                      widget.onSearchResultTap?.call(r.sectionIndex, query);
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        children: [
          // Search Bar
          Expanded(
            child: CompositedTransformTarget(
              link: _layerLink,
              child: TextField(
                controller: _searchCtrl,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: "Search products, categories, orders, customers...",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: const Color(0xFFF2F2F2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),
          ),

          const SizedBox(width: 20),

          // Settings
          IconButton(
            onPressed: widget.onSettingsTap ?? () {},
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
          ),

          const SizedBox(width: 10),

          // Profile Section
          Obx(() {
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

            return PopupMenuButton<String>(
              offset: const Offset(0, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (value) {
                if (value == 'logout') {
                  authController.logout();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  enabled: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Role: ${user.role.isEmpty ? "Admin" : user.role}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Logout', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.green,
                    child: Text(
                      initials.isEmpty ? 'A' : initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    displayName,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, size: 20),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SearchResult {
  final IconData icon;
  final String title;
  final String subtitle;
  final String section;
  final int sectionIndex;

  _SearchResult({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.section,
    required this.sectionIndex,
  });
}
