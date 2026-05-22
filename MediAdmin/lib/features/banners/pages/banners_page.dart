import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/banner_controller.dart';

class BannersPage extends StatefulWidget {
  final VoidCallback onCreatePressed;
  final Function(Map<String, dynamic>) onViewPressed;

  const BannersPage({
    super.key,
    required this.onCreatePressed,
    required this.onViewPressed,
  });

  @override
  State<BannersPage> createState() => _BannersPageState();
}

class _BannersPageState extends State<BannersPage> {
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    searchController.addListener(() {
      BannerController.instance.searchQuery.value = searchController.text;
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = BannerController.instance;

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
                    "Create New Banner",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 20),
                Obx(
                  () => Text(
                    'Total Banners: ${controller.banners.length}',
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
          controller: searchController,
          decoration: InputDecoration(
            hintText: "Search banners...",
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
              if (controller.isLoading.value && controller.banners.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              final bannerList = controller.filteredBanners;

              if (bannerList.isEmpty) {
                return const Center(
                  child: Text('No banners found. Create your first banner!'),
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
                      DataColumn(label: Text("Banner")),
                      DataColumn(label: Text("Title")),
                      DataColumn(label: Text("Redirect")),
                      DataColumn(label: Text("Views")),
                      DataColumn(label: Text("Clicks")),
                      DataColumn(label: Text("Active")),
                      DataColumn(label: Text("Featured")),
                      DataColumn(label: Text("Start Date")),
                      DataColumn(label: Text("End Date")),
                      DataColumn(label: Text("Action")),
                    ],
                    rows: bannerList.map((banner) {
                      return DataRow(
                        cells: [
                          DataCell(
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: banner.imageUrl.startsWith('http')
                                  ? Image.network(
                                      banner.imageUrl,
                                      width: 80,
                                      height: 45,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 80,
                                        height: 45,
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.image,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    )
                                  : Container(
                                      width: 80,
                                      height: 45,
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.image,
                                        color: Colors.blue,
                                      ),
                                    ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 150,
                              child: Text(
                                banner.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(
                            Chip(
                              label: Text(
                                banner.redirect,
                                style: const TextStyle(fontSize: 12),
                              ),
                              backgroundColor: Colors.blue.shade50,
                            ),
                          ),
                          DataCell(Text(banner.views.toString())),
                          DataCell(Text(banner.clicks.toString())),
                          DataCell(
                            Row(
                              children: [
                                Switch(
                                  value: banner.isActive,
                                  activeThumbColor: Colors.green,
                                  onChanged: (val) =>
                                      controller.toggleActive(banner),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  banner.isActive ? "Active" : "Inactive",
                                  style: TextStyle(
                                    color: banner.isActive
                                        ? Colors.green
                                        : Colors.red,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DataCell(
                            Switch(
                              value: banner.isFeatured,
                              activeThumbColor: Colors.green,
                              onChanged: null,
                            ),
                          ),
                          DataCell(Text(banner.startDate)),
                          DataCell(Text(banner.endDate)),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Color(0xFF4299E1),
                                  ),
                                  tooltip: 'Edit Banner',
                                  onPressed: () {
                                    widget.onViewPressed({
                                      'id': banner.id,
                                      'image': banner.imageUrl,
                                      'imagePublicId': banner.imagePublicId,
                                      'title': banner.title,
                                      'description': banner.description,
                                      'redirect': banner.redirect,
                                      'isActive': banner.isActive,
                                      'isFeatured': banner.isFeatured,
                                      'views': banner.views,
                                      'clicks': banner.clicks,
                                      'startDate': banner.startDate,
                                      'endDate': banner.endDate,
                                    });
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
                                        title: const Text('Delete Banner'),
                                        content: Text(
                                          'Are you sure you want to delete "${banner.title}"?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Get.back(),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              Get.back();
                                              controller.deleteBanner(
                                                banner.id,
                                              );
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
            "Showing ${controller.filteredBanners.length} of ${controller.banners.length} Banners",
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
