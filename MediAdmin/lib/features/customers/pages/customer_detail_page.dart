import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../controllers/customer_controller.dart';
import '../models/customer_model.dart';
import '../../orders/models/order_model.dart';

class CustomerDetailPage extends StatefulWidget {
  final CustomerModel customer;
  final VoidCallback onBack;
  final void Function(OrderModel)? onOrderTap;
  const CustomerDetailPage({
    super.key,
    required this.customer,
    required this.onBack,
    this.onOrderTap,
  });
  @override
  State<CustomerDetailPage> createState() => _CustomerDetailPageState();
}

class _CustomerDetailPageState extends State<CustomerDetailPage> {
  final TextEditingController _sc = TextEditingController();
  late final CustomerController _ctrl;
  List<OrderModel> _orders = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _ctrl = CustomerController.instance;
    _loadOrders();
    _sc.addListener(() {
      setState(() => _search = _sc.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _sc.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => _loading = true);
    final orders = await _ctrl.fetchOrdersForCustomer(widget.customer.id);
    if (mounted) {
      setState(() {
        _orders = orders;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.customer;
    final ac = _ac(c.id);
    final fo = _search.isEmpty
        ? _orders
        : _orders
              .where(
                (o) =>
                    o.id.toLowerCase().contains(_search) ||
                    o.orderStatus.toLowerCase().contains(_search),
              )
              .toList();
    final total = _orders.fold(0.0, (s, o) => s + o.totalAmount);

    return Container(
      color: const Color(0xFFF5F7FA),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: widget.onBack,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back, color: Color(0xFF4A5568)),
                SizedBox(width: 8),
                Text(
                  'Back',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF4A5568),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: ac,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  c.initials,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                c.fullName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _infoCard(c, ac),
                        const SizedBox(height: 20),
                        _addrCard(c),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(flex: 2, child: _ordersCard(fo, total)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(CustomerModel c, Color ac) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    padding: const EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.person, color: Color(0xFF4299E1), size: 20),
            SizedBox(width: 8),
            Text(
              'Customer Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: ac,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                c.initials,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.fullName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    c.email,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF718096),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: c.isEmailVerified
                ? const Color(0xFFC6F6D5)
                : const Color(0xFFFFF5F5),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            c.isEmailVerified ? 'Email Verified' : 'Email Not Verified',
            style: TextStyle(
              fontSize: 13,
              color: c.isEmailVerified
                  ? const Color(0xFF22543D)
                  : const Color(0xFFC53030),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFC6F6D5),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            'Approved',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF22543D),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 24),
        _ir(
          'Last Order',
          _orders.isNotEmpty
              ? '#${_orders.first.id.substring(0, _orders.first.id.length > 5 ? 5 : _orders.first.id.length)}'
              : 'No orders yet',
        ),
        const SizedBox(height: 16),
        _ir('Phone Number', c.phoneNumber.isEmpty ? '-' : c.phoneNumber),
        const SizedBox(height: 16),
        _ir(
          'Registered',
          DateFormat('dd/MM/yyyy \'at\' H:mm').format(c.createdAt),
        ),
      ],
    ),
  );

  Widget _addrCard(CustomerModel c) {
    // Use a real-time Firestore stream so the address updates dynamically
    // when the customer changes their selected address in the mobile app.
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Users')
          .doc(c.id)
          .snapshots(),
      builder: (context, snapshot) {
        // While waiting, show the data we already have from the initial fetch
        final liveCustomer = snapshot.hasData && snapshot.data!.exists
            ? CustomerModel.fromSnapshot(snapshot.data!)
            : c;

        final Map<String, dynamic> a = liveCustomer.selectedShippingAddress;
        final hasAddr =
            (a['name'] as String? ?? '').isNotEmpty ||
            (a['street'] as String? ?? '').isNotEmpty ||
            (a['city'] as String? ?? '').isNotEmpty;

        final addrCount = liveCustomer.addresses.length;
        final addrIndex = liveCustomer.selectedAddressIndex.clamp(
          0,
          addrCount > 0 ? addrCount - 1 : 0,
        );

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.location_on, color: Color(0xFF4299E1), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Shipping Address',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                ],
              ),
              if (addrCount > 1) ...[
                const SizedBox(height: 8),
                Text(
                  'Address ${addrIndex + 1} of $addrCount',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF718096),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              if (!hasAddr)
                const Text(
                  'No address saved',
                  style: TextStyle(fontSize: 13, color: Color(0xFF718096)),
                )
              else ...[
                _ir('Name', a['name'] as String? ?? '-'),
                const SizedBox(height: 16),
                _ir(
                  'Phone',
                  a['phoneNumber'] as String? ?? a['phone'] as String? ?? '-',
                ),
                const SizedBox(height: 16),
                if ((a['houseNo'] as String? ?? '').isNotEmpty) ...[
                  _ir('House No.', a['houseNo'] as String? ?? '-'),
                  const SizedBox(height: 16),
                ],
                _ir('Street', a['street'] as String? ?? '-'),
                const SizedBox(height: 16),
                _ir('City', a['city'] as String? ?? '-'),
                const SizedBox(height: 16),
                _ir('State / Town', a['state'] as String? ?? '-'),
                const SizedBox(height: 16),
                _ir('Postal Code', a['postalCode'] as String? ?? '-'),
                const SizedBox(height: 16),
                _ir('Country', a['country'] as String? ?? '-'),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _ordersCard(List<OrderModel> fo, double total) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.shopping_bag,
                          color: Color(0xFF4299E1),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Orders',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Total Sum: \$${total.toStringAsFixed(2)} up to ${_orders.length} Orders',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF718096),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    controller: _sc,
                    decoration: const InputDecoration(
                      hintText: 'Search Orders',
                      hintStyle: TextStyle(color: Color(0xFFA0AEC0)),
                      prefixIcon: Icon(Icons.search, color: Color(0xFFA0AEC0)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : fo.isEmpty
                ? Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDF2F7),
                              borderRadius: BorderRadius.circular(40),
                            ),
                            child: const Icon(
                              Icons.shopping_cart_outlined,
                              size: 40,
                              color: Color(0xFFA0AEC0),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No Orders Found',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF4A5568),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: fo.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    itemBuilder: (_, i) {
                      final o = fo[i];
                      final sid = o.id.length > 5 ? o.id.substring(0, 5) : o.id;
                      return InkWell(
                        onTap: widget.onOrderTap != null
                            ? () => widget.onOrderTap!(o)
                            : null,
                        hoverColor: const Color(0xFFF7FAFC),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '#$sid',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF4299E1),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  DateFormat('dd/MM/yyyy').format(o.createdAt),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF718096),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  '${o.itemCount} item${o.itemCount != 1 ? 's' : ''}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF2D3748),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _sbg(o.orderStatus),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    o.orderStatus,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _stc(o.orderStatus),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  '\$${o.totalAmount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2D3748),
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              if (widget.onOrderTap != null)
                                const Padding(
                                  padding: EdgeInsets.only(left: 8),
                                  child: Icon(
                                    Icons.chevron_right,
                                    size: 16,
                                    color: Color(0xFFA0AEC0),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  static Widget _ir(String l, String v) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 140,
        child: Text(
          l,
          style: const TextStyle(fontSize: 13, color: Color(0xFF718096)),
        ),
      ),
      Expanded(
        child: Text(
          v,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF2D3748),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    ],
  );
  Color _ac(String id) {
    final cs = [
      const Color(0xFF4299E1),
      const Color(0xFF9F7AEA),
      const Color(0xFFED8936),
      const Color(0xFFE53E3E),
      const Color(0xFF48BB78),
    ];
    return cs[id.codeUnits.fold(0, (p, e) => p + e) % cs.length];
  }

  static Color _sbg(String s) {
    switch (s.toLowerCase()) {
      case 'delivered':
        return const Color(0xFFF0FFF4);
      case 'shipped':
        return const Color(0xFFEBF8FF);
      case 'processing':
        return const Color(0xFFFFFAF0);
      default:
        return const Color(0xFFFFF5F5);
    }
  }

  static Color _stc(String s) {
    switch (s.toLowerCase()) {
      case 'delivered':
        return const Color(0xFF276749);
      case 'shipped':
        return const Color(0xFF2B6CB0);
      case 'processing':
        return const Color(0xFFB7791F);
      default:
        return const Color(0xFFC53030);
    }
  }
}
