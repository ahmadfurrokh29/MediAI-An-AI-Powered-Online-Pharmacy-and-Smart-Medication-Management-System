import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddressController extends GetxController {
  static AddressController get instance => Get.find();

  final _db = FirebaseFirestore.instance;

  /// Full list of saved addresses.
  final RxList<Map<String, dynamic>> addresses = <Map<String, dynamic>>[].obs;

  /// Index of the currently selected/active address.
  final RxInt selectedIndex = 0.obs;

  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;

  // Form controllers for AddNewAddressScreen
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final houseNoController = TextEditingController();
  final streetController = TextEditingController();
  final postalCodeController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final countryController = TextEditingController();

  final formKey = GlobalKey<FormState>();

  @override
  void onInit() {
    super.onInit();
    loadAddresses();
  }

  @override
  void onClose() {
    nameController.dispose();
    phoneController.dispose();
    houseNoController.dispose();
    streetController.dispose();
    postalCodeController.dispose();
    cityController.dispose();
    stateController.dispose();
    countryController.dispose();
    super.onClose();
  }

  String get uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  // ── Getters ─────────────────────────────────────────────────────────────

  /// The currently selected address map (or empty map if none).
  Map<String, dynamic> get selectedAddress {
    if (addresses.isEmpty) return {};
    final idx = selectedIndex.value.clamp(0, addresses.length - 1);
    return addresses[idx];
  }

  bool get hasAddresses => addresses.isNotEmpty;

  // ── Load ─────────────────────────────────────────────────────────────────

  Future<void> loadAddresses() async {
    try {
      isLoading.value = true;
      if (uid.isEmpty) return;
      final doc = await _db.collection('Users').doc(uid).get();
      final data = doc.data() ?? {};

      // Support both the new list schema and the legacy single-map schema
      final raw = data['addresses'];
      if (raw is List && raw.isNotEmpty) {
        addresses.value = raw
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        selectedIndex.value = (data['selectedAddressIndex'] as int? ?? 0).clamp(
          0,
          addresses.length - 1,
        );
      } else {
        // Legacy: migrate single shippingAddress map into the list
        final legacy =
            data['shippingAddress'] as Map<String, dynamic>? ??
            data['ShippingAddress'] as Map<String, dynamic>? ??
            {};
        final hasLegacy =
            (legacy['name'] as String? ?? '').isNotEmpty ||
            (legacy['street'] as String? ?? '').isNotEmpty ||
            (legacy['city'] as String? ?? '').isNotEmpty;
        if (hasLegacy) {
          addresses.value = [legacy];
          selectedIndex.value = 0;
          // Persist the migration immediately
          await _persistAddresses();
        } else {
          addresses.value = [];
          selectedIndex.value = 0;
        }
      }
    } catch (_) {
      // non-fatal
    } finally {
      isLoading.value = false;
    }
  }

  // ── Select ───────────────────────────────────────────────────────────────

  Future<void> selectAddress(int index) async {
    if (index < 0 || index >= addresses.length) return;
    selectedIndex.value = index;
    addresses.refresh(); // Force UI rebuild immediately
    await _persistAddresses();
  }

  // ── Add / Save new ───────────────────────────────────────────────────────

  /// Clears the form so the user can enter a brand-new address.
  void clearForm() {
    nameController.clear();
    phoneController.clear();
    houseNoController.clear();
    streetController.clear();
    postalCodeController.clear();
    cityController.clear();
    stateController.clear();
    countryController.clear();
  }

  /// Pre-fills the form with an existing address for editing.
  void populateForm(Map<String, dynamic> a) {
    nameController.text = a['name'] as String? ?? '';
    phoneController.text = a['phoneNumber'] as String? ?? '';
    houseNoController.text = a['houseNo'] as String? ?? '';
    streetController.text = a['street'] as String? ?? '';
    postalCodeController.text = a['postalCode'] as String? ?? '';
    cityController.text = a['city'] as String? ?? '';
    stateController.text = a['state'] as String? ?? '';
    countryController.text = a['country'] as String? ?? '';
  }

  Future<void> saveNewAddress() async {
    if (!formKey.currentState!.validate()) return;
    try {
      isSaving.value = true;
      final newAddr = {
        'name': nameController.text.trim(),
        'phoneNumber': phoneController.text.trim(),
        'houseNo': houseNoController.text.trim(),
        'street': streetController.text.trim(),
        'postalCode': postalCodeController.text.trim(),
        'city': cityController.text.trim(),
        'state': stateController.text.trim(),
        'country': countryController.text.trim(),
      };
      addresses.add(newAddr);
      // Auto-select the newly added address
      selectedIndex.value = addresses.length - 1;
      await _persistAddresses();
      Get.back();
      Get.snackbar(
        'Address Added',
        'Your new address has been saved.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save address: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSaving.value = false;
    }
  }

  // ── Edit / Update existing ────────────────────────────────────────────────

  Future<void> updateAddress(int index) async {
    if (!formKey.currentState!.validate()) return;
    if (index < 0 || index >= addresses.length) return;
    try {
      isSaving.value = true;
      final updated = {
        'name': nameController.text.trim(),
        'phoneNumber': phoneController.text.trim(),
        'houseNo': houseNoController.text.trim(),
        'street': streetController.text.trim(),
        'postalCode': postalCodeController.text.trim(),
        'city': cityController.text.trim(),
        'state': stateController.text.trim(),
        'country': countryController.text.trim(),
      };
      addresses[index] = updated;
      addresses.refresh();
      await _persistAddresses();
      Get.back();
      Get.snackbar(
        'Address Updated',
        'Your address has been updated.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update address: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSaving.value = false;
    }
  }

  // ── Delete ───────────────────────────────────────────────────────────────

  Future<void> deleteAddress(int index) async {
    if (index < 0 || index >= addresses.length) return;
    addresses.removeAt(index);
    // Clamp selected index
    if (addresses.isEmpty) {
      selectedIndex.value = 0;
    } else {
      selectedIndex.value = selectedIndex.value.clamp(0, addresses.length - 1);
    }
    await _persistAddresses();
  }

  // ── Persist ──────────────────────────────────────────────────────────────

  Future<void> _persistAddresses() async {
    if (uid.isEmpty) return;
    // Also keep the legacy shippingAddress field in sync so the Admin panel
    // always reads the currently-selected address.
    final selected = selectedAddress;
    await _db.collection('Users').doc(uid).update({
      'addresses': addresses.map((a) => Map<String, dynamic>.from(a)).toList(),
      'selectedAddressIndex': selectedIndex.value,
      // Legacy field — Admin panel reads this for "Shipping Address"
      'shippingAddress': selected.isNotEmpty ? selected : <String, dynamic>{},
    });
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  String displayFor(Map<String, dynamic> a) {
    final parts = <String>[
      if ((a['houseNo'] as String? ?? '').isNotEmpty) a['houseNo'] as String,
      if ((a['street'] as String? ?? '').isNotEmpty) a['street'] as String,
      if ((a['city'] as String? ?? '').isNotEmpty) a['city'] as String,
      if ((a['state'] as String? ?? '').isNotEmpty) a['state'] as String,
      if ((a['postalCode'] as String? ?? '').isNotEmpty)
        a['postalCode'] as String,
      if ((a['country'] as String? ?? '').isNotEmpty) a['country'] as String,
    ];
    return parts.join(', ');
  }
}
