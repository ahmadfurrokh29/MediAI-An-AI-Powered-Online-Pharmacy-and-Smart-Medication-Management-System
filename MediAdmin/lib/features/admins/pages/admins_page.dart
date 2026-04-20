import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/admin_controller.dart';

class AdminsPage extends StatefulWidget {
  final VoidCallback onCreatePressed;
  final Function(Map<String, dynamic>)? onEditPressed;

  const AdminsPage({
    super.key,
    required this.onCreatePressed,
    this.onEditPressed,
  });

  @override
  State<AdminsPage> createState() => _AdminsPageState();
}

class _AdminsPageState extends State<AdminsPage> {
  late final AdminController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(AdminController());
    _controller.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: widget.onCreatePressed,
                  child: const Text(
                    "Create Admin",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 20),
                Obx(
                  () => Text(
                    'Total Admins: ${_controller.admins.length}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            Row(
              children: [
                IconButton(icon: const Icon(Icons.download), onPressed: () {}),
                IconButton(icon: const Icon(Icons.print), onPressed: () {}),
              ],
            ),
          ],
        ),

        const SizedBox(height: 20),

        TextField(
          onChanged: (value) {
            _controller.searchQuery.value = value;
          },
          decoration: InputDecoration(
            hintText: "Search admins...",
            filled: true,
            fillColor: Colors.white,
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          ),
        ),

        const SizedBox(height: 20),

        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 8),
              ],
            ),
            child: Obx(() {
              if (_controller.isLoading.value && _controller.admins.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              final admins = _controller.filteredAdmins;

              if (admins.isEmpty) {
                return const Center(
                  child: Text('No admins found. Create your first admin!'),
                );
              }

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    columnSpacing: 50,
                    horizontalMargin: 20,
                    headingRowColor: WidgetStateProperty.all(
                      Colors.grey.shade100,
                    ),
                    columns: const [
                      DataColumn(label: Text("Admin")),
                      DataColumn(label: Text("Email")),
                      DataColumn(label: Text("Phone")),
                      DataColumn(label: Text("Role")),
                      DataColumn(label: Text("Status")),
                      DataColumn(label: Text("Date")),
                      DataColumn(label: Text("Action")),
                    ],
                    rows: admins.map((admin) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: _avatarColor(admin.fullName),
                                  child: Text(
                                    admin.initials,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  admin.fullName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DataCell(Text(admin.email)),
                          DataCell(
                            Text(
                              admin.phoneNumber.isEmpty
                                  ? '—'
                                  : admin.phoneNumber,
                            ),
                          ),
                          DataCell(
                            Chip(
                              label: Text(
                                admin.role.isEmpty ? 'admin' : admin.role,
                                style: const TextStyle(fontSize: 12),
                              ),
                              backgroundColor: Colors.blue.shade50,
                            ),
                          ),
                          DataCell(
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: admin.isActive
                                        ? Colors.green
                                        : Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  admin.isActive ? "Active" : "Inactive",
                                  style: TextStyle(
                                    color: admin.isActive
                                        ? Colors.green
                                        : Colors.red,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DataCell(
                            Text(
                              DateFormat('dd/MM/yyyy').format(admin.createdAt),
                            ),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Color(0xFF4299E1),
                                  ),
                                  tooltip: 'Edit Admin',
                                  onPressed: () {
                                    if (widget.onEditPressed != null) {
                                      widget.onEditPressed!({
                                        'id': admin.id,
                                        'firstName': admin.firstName,
                                        'lastName': admin.lastName,
                                        'email': admin.email,
                                        'phoneNumber': admin.phoneNumber,
                                        'profilePicture': admin.profilePicture,
                                        'role': admin.role,
                                        'isActive': admin.isActive,
                                      });
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    Get.dialog(
                                      AlertDialog(
                                        title: const Text('Delete Admin'),
                                        content: Text(
                                          'Are you sure you want to delete "${admin.fullName}"?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Get.back(),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              Get.back();
                                              _controller.deleteAdmin(admin.id);
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                            ),
                                            child: const Text(
                                              'Delete',
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              );
            }),
          ),
        ),

        const SizedBox(height: 10),

        Obx(
          () => Text(
            "Showing ${_controller.filteredAdmins.length} of ${_controller.admins.length} Admins",
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Color _avatarColor(String name) {
    final colours = [
      const Color(0xFF4299E1),
      const Color(0xFF9F7AEA),
      const Color(0xFFED8936),
      const Color(0xFF48BB78),
      const Color(0xFFE53E3E),
      const Color(0xFF805AD5),
      const Color(0xFFD69E2E),
      const Color(0xFF2C5282),
      const Color(0xFFD53F8C),
      const Color(0xFF2B6CB0),
    ];
    if (name.isEmpty) return colours[0];
    return colours[name.codeUnitAt(0) % colours.length];
  }
}
