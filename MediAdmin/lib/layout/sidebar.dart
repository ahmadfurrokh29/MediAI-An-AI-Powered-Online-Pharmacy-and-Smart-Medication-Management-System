import 'package:flutter/material.dart';

class Sidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final VoidCallback onLogout;

  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.onLogout,
  });

  Widget buildMenuItem({
    required IconData icon,
    required String title,
    required int index,
  }) {
    final bool isActive = selectedIndex == index;

    return InkWell(
      onTap: () => onItemSelected(index),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? Colors.green : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: const Color(0xFF1E1E1E),
      child: Column(
        children: [
          // 🔹 Logo Section
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            alignment: Alignment.center,
            child: Row(
              children: [
                Image.asset('assets/logos/medi-ai.png', height: 60),
                const SizedBox(width: 12),
                const Text(
                  "Admin Panel",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // 🔹 Scrollable Menu Section
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "OVERVIEW",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  buildMenuItem(
                    icon: Icons.dashboard,
                    title: "Dashboard",
                    index: 0,
                  ),

                  const SizedBox(height: 24),
                  const Text(
                    "DATA MANAGEMENT",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  buildMenuItem(
                    icon: Icons.category,
                    title: "Categories",
                    index: 1,
                  ),
                  buildMenuItem(
                    icon: Icons.layers,
                    title: "Subcategories",
                    index: 2,
                  ),
                  buildMenuItem(
                    icon: Icons.branding_watermark,
                    title: "Brands",
                    index: 3,
                  ),

                  const SizedBox(height: 24),
                  const Text(
                    "PRODUCT MANAGEMENT",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 12),

                  buildMenuItem(
                    icon: Icons.inventory,
                    title: "Products",
                    index: 4,
                  ),
                  buildMenuItem(
                    icon: Icons.star,
                    title: "Recommended Products",
                    index: 5,
                  ),
                  buildMenuItem(
                    icon: Icons.shopping_cart,
                    title: "Orders",
                    index: 6,
                  ),

                  const SizedBox(height: 24),
                  const Text(
                    "PROMOTION MANAGEMENT",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  buildMenuItem(icon: Icons.flag, title: "Banners", index: 7),
                  buildMenuItem(
                    icon: Icons.local_offer,
                    title: "Coupons",
                    index: 8,
                  ),

                  const SizedBox(height: 24),
                  const Text(
                    "USER MANAGEMENT",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  buildMenuItem(
                    icon: Icons.people,
                    title: "Customers",
                    index: 9,
                  ),

                  const SizedBox(height: 24),
                  const Text(
                    "ADMIN MANAGEMENT",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  buildMenuItem(
                    icon: Icons.admin_panel_settings,
                    title: "Admins",
                    index: 10,
                  ),
                ],
              ),
            ),
          ),

          // 🔹 Logout Section (Fixed Bottom)
          const Divider(color: Colors.grey),
          Padding(
            padding: const EdgeInsets.all(16),
            child: InkWell(
              onTap: onLogout,
              child: const Row(
                children: [
                  Icon(Icons.logout, color: Colors.white),
                  SizedBox(width: 12),
                  Text("Logout", style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
