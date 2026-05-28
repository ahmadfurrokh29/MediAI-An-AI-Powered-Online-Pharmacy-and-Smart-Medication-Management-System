import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/prescription_request_controller.dart';
import '../models/prescription_request_model.dart';

class PrescriptionRequestsPage extends StatelessWidget {
  final void Function(PrescriptionRequestModel) onView;

  const PrescriptionRequestsPage({super.key, required this.onView});

  @override
  Widget build(BuildContext context) {
    final ctrl = PrescriptionRequestController.instance;

    return Container(
      color: const Color(0xFFF5F7FA),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                const Text(
                  'Prescription Requests',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Obx(
                  () => ctrl.pendingCount > 0
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${ctrl.pendingCount} Pending',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(width: 12),
                Obx(
                  () => ctrl.isLoading.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          onPressed: ctrl.fetchRequests,
                          icon: const Icon(Icons.refresh),
                          tooltip: 'Refresh',
                        ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search bar
            SizedBox(
              width: 340,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search by customer or medicine...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (v) => ctrl.searchQuery.value = v,
              ),
            ),
            const SizedBox(height: 20),

            // Table
            Expanded(
              child: Obx(() {
                if (ctrl.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                final requests = ctrl.filteredRequests;
                if (requests.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inbox_outlined,
                            size: 60, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          'No prescription requests yet.',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  );
                }

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                      children: [
                        // Column headers
                        Container(
                          color: const Color(0xFFF8F9FA),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          child: const Row(
                            children: [
                              Expanded(
                                  flex: 3,
                                  child: Text('Customer',
                                      style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600))),
                              Expanded(
                                  flex: 3,
                                  child: Text('Medicine',
                                      style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600))),
                              Expanded(
                                  flex: 2,
                                  child: Text('Date',
                                      style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600))),
                              SizedBox(
                                  width: 100,
                                  child: Text('Status',
                                      style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600))),
                              SizedBox(width: 80),
                            ],
                          ),
                        ),
                        const Divider(height: 1),

                        // Rows
                        Expanded(
                          child: ListView.separated(
                            itemCount: requests.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (_, i) {
                              final r = requests[i];
                              return _RequestRow(
                                  request: r, onView: onView);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestRow extends StatelessWidget {
  final PrescriptionRequestModel request;
  final void Function(PrescriptionRequestModel) onView;

  const _RequestRow({required this.request, required this.onView});

  @override
  Widget build(BuildContext context) {
    final isPending = request.isPending;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(request.customerName,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(request.customerEmail,
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              request.medicineName,
              style: const TextStyle(fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              DateFormat('dd/MM/yyyy').format(request.createdAt),
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ),
          SizedBox(
            width: 100,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isPending
                    ? Colors.orange.withOpacity(0.12)
                    : Colors.green.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                request.status,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isPending ? Colors.orange : Colors.green,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 80,
            child: TextButton(
              onPressed: () => onView(request),
              child: const Text('View'),
            ),
          ),
        ],
      ),
    );
  }
}
