import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:med_admin/features/brands/pages/create_brand_page.dart'
    show CreateBrandPage;
import 'package:med_admin/features/categories/pages/create_category_page.dart'
    show CreateCategoryPage;
import 'package:med_admin/features/categories/pages/update_category_page.dart'
    show UpdateCategoryPage;
import 'package:med_admin/features/orders/orders_detail_page.dart'
    show OrderDetailsPage;
import 'package:med_admin/features/orders/models/order_model.dart';
import 'package:med_admin/features/customers/models/customer_model.dart';
import 'package:med_admin/features/subcategories/pages/create_subcategory_page.dart'
    show CreateSubcategoryPage;
import 'package:med_admin/features/subcategories/pages/update_subcategory_page.dart'
    show UpdateSubcategoryPage;
import '../features/auth/controllers/auth_controller.dart';
import '../features/dashboard/dashboard_page.dart' show DashboardPage;
import '../features/categories/pages/categories_page.dart' show CategoriesPage;
import '../features/subcategories/pages/subcategories_page.dart'
    show SubcategoriesPage;
import '../features/brands/pages/brands_page.dart' show BrandsPage;
import '../features/brands/pages/update_brand_page.dart' show UpdateBrandPage;
import '../features/products/pages/create_product_page.dart'
    show CreateProductPage;
import '../features/products/pages/products_page.dart' show ProductsPage;
import '../features/products/pages/update_product_page.dart'
    show UpdateProductPage;
import '../features/products/recommended_products_page.dart'
    show RecommendedProductsPage;
import '../features/orders/orders_page.dart' show OrdersPage;
import '../features/customers/pages/customers_page.dart' show CustomersPage;
import '../features/customers/pages/customer_detail_page.dart'
    show CustomerDetailPage;
import '../features/banners/pages/banners_page.dart' show BannersPage;
import '../features/banners/pages/create_banner_page.dart'
    show CreateBannerPage;
import '../features/banners/pages/update_banner_page.dart'
    show UpdateBannerPage;
import '../features/coupons/pages/coupons_page.dart' show CouponsPage;
import '../features/coupons/pages/campaigns_page.dart' show CampaignsPage;
import '../features/coupons/controllers/coupon_controller.dart'
    show CouponController;
import '../features/coupons/pages/create_coupon_page.dart'
    show CreateCouponPage;
import '../features/coupons/pages/update_coupon_page.dart'
    show UpdateCouponPage;
import '../features/admins/pages/admins_page.dart' show AdminsPage;
import '../features/admins/pages/create_admin_page.dart' show CreateAdminPage;
import '../features/admins/pages/update_admin_page.dart' show UpdateAdminPage;
import '../features/prescription_requests/pages/prescription_requests_page.dart'
    show PrescriptionRequestsPage;
import '../features/prescription_requests/pages/prescription_request_detail_page.dart'
    show PrescriptionRequestDetailPage;
import '../features/prescription_requests/models/prescription_request_model.dart';
import '../features/prescription_requests/controllers/prescription_request_controller.dart'
    show PrescriptionRequestController;
import 'sidebar.dart';
import 'topbar.dart';
import 'settings_page.dart';

class AdminLayout extends StatefulWidget {
  const AdminLayout({super.key});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  int selectedIndex = 0;
  bool isCreatingCategory = false;
  bool isUpdatingCategory = false;
  Map<String, dynamic>? selectedCategory;
  bool isCreatingSubcategory = false;
  bool isUpdatingSubcategory = false;
  Map<String, dynamic>? selectedSubcategory;
  bool isCreatingBrand = false;
  bool isUpdatingBrand = false;
  Map<String, dynamic>? selectedBrandData;
  bool isCreatingProduct = false;
  bool isUpdatingProduct = false;
  Map<String, dynamic>? selectedProduct;
  OrderModel? selectedOrder;
  bool isViewingOrder = false;
  CustomerModel? selectedCustomer;
  bool isViewingCustomer = false;
  // Order opened from within customer detail
  OrderModel? selectedOrderFromCustomer;
  bool isViewingOrderFromCustomer = false;
  bool isCreatingBanner = false;
  Map<String, dynamic>? selectedBanner;
  bool isUpdatingBanner = false;
  bool isCreatingCoupon = false;
  Map<String, dynamic>? selectedCoupon;
  bool isUpdatingCoupon = false;
  bool isCreatingAdmin = false;
  bool isUpdatingAdmin = false;
  Map<String, dynamic>? selectedAdmin;
  bool _cameFromSettings = false;
  PrescriptionRequestModel? selectedPrescriptionRequest;
  bool isViewingPrescriptionRequest = false;

  @override
  void initState() {
    super.initState();
    // Register CouponController globally so both CouponsPage and CampaignsPage
    // can access it without needing each other to be initialized first.
    if (!Get.isRegistered<CouponController>()) {
      final ctrl = Get.put(CouponController());
      ctrl.initialize();
    }
  }

  String getPageTitle() {
    switch (selectedIndex) {
      case 0:
        return "Dashboard";
      case 1:
        return "Categories";
      case 2:
        return "Subcategories";
      case 3:
        return "Brands";
      case 4:
        return "Products";
      case 5:
        return "Recommended Products";
      case 6:
        return "Orders";
      case 7:
        return "Banners";
      case 8:
        return "Coupons";
      case 12:
        return "Campaigns";
      case 9:
        return isViewingCustomer ? "Customer Details" : "Customers";
      case 10:
        return "Admins";
      case 11:
        return "Settings";
      case 13:
        return isViewingPrescriptionRequest
            ? "Prescription Request Details"
            : "Prescription Requests";
      default:
        return "Dashboard";
    }
  }

  Widget getSelectedPage() {
    switch (selectedIndex) {
      // 0 - Dashboard
      case 0:
        return const DashboardPage();

      // 1 - Categories
      case 1:
        if (isCreatingCategory) {
          return CreateCategoryPage(
            onBack: () {
              setState(() {
                isCreatingCategory = false;
              });
            },
          );
        }
        if (isUpdatingCategory && selectedCategory != null) {
          return UpdateCategoryPage(
            category: selectedCategory!,
            onBack: () {
              setState(() {
                isUpdatingCategory = false;
                selectedCategory = null;
              });
            },
          );
        }
        return CategoriesPage(
          onCreatePressed: () {
            setState(() {
              isCreatingCategory = true;
            });
          },
          onEditPressed: (category) {
            setState(() {
              selectedCategory = category;
              isUpdatingCategory = true;
            });
          },
        );

      // 2 - Subcategories
      case 2:
        if (isCreatingSubcategory) {
          return CreateSubcategoryPage(
            onBack: () {
              setState(() {
                isCreatingSubcategory = false;
              });
            },
          );
        }
        if (isUpdatingSubcategory && selectedSubcategory != null) {
          return UpdateSubcategoryPage(
            subcategory: selectedSubcategory!,
            onBack: () {
              setState(() {
                isUpdatingSubcategory = false;
                selectedSubcategory = null;
              });
            },
          );
        }
        return SubcategoriesPage(
          onCreatePressed: () {
            setState(() {
              isCreatingSubcategory = true;
            });
          },
          onEditPressed: (subcategory) {
            setState(() {
              selectedSubcategory = subcategory;
              isUpdatingSubcategory = true;
            });
          },
        );

      // 3 - Brands
      case 3:
        if (isCreatingBrand) {
          return CreateBrandPage(
            onBack: () {
              setState(() {
                isCreatingBrand = false;
              });
            },
          );
        }
        if (isUpdatingBrand && selectedBrandData != null) {
          return UpdateBrandPage(
            brand: selectedBrandData!,
            onBack: () {
              setState(() {
                isUpdatingBrand = false;
                selectedBrandData = null;
              });
            },
          );
        }
        return BrandsPage(
          onCreatePressed: () {
            setState(() {
              isCreatingBrand = true;
            });
          },
          onEditPressed: (brand) {
            setState(() {
              selectedBrandData = brand;
              isUpdatingBrand = true;
            });
          },
        );

      // 4 - Add Product

      case 4:
        if (isCreatingProduct) {
          return CreateProductPage(
            onBack: () {
              setState(() {
                isCreatingProduct = false;
              });
            },
          );
        }
        if (isUpdatingProduct && selectedProduct != null) {
          return UpdateProductPage(
            product: selectedProduct!,
            onBack: () {
              setState(() {
                isUpdatingProduct = false;
                selectedProduct = null;
              });
            },
          );
        }

        return ProductsPage(
          onCreatePressed: () {
            setState(() {
              isCreatingProduct = true;
            });
          },
          onEditPressed: (product) {
            setState(() {
              selectedProduct = product;
              isUpdatingProduct = true;
            });
          },
        );

      // 6 - Recommended Products
      case 5:
        return const RecommendedProductsPage();

      // 7 - Orders
      case 6:
        if (isViewingOrder && selectedOrder != null) {
          return OrderDetailsPage(
            order: selectedOrder!,
            onBack: () {
              setState(() {
                isViewingOrder = false;
                selectedOrder = null;
                selectedIndex = 6; // Stay on Orders tab
              });
            },
          );
        }

        return OrdersPage(
          onView: (OrderModel order) {
            setState(() {
              selectedOrder = order;
              isViewingOrder = true;
            });
          },
        );

      // 7 - Banners
      case 7:
        if (isCreatingBanner) {
          return CreateBannerPage(
            onBack: () {
              setState(() {
                isCreatingBanner = false;
              });
            },
          );
        }
        if (isUpdatingBanner && selectedBanner != null) {
          return UpdateBannerPage(
            banner: selectedBanner!,
            onBack: () {
              setState(() {
                isUpdatingBanner = false;
                selectedBanner = null;
              });
            },
          );
        }
        return BannersPage(
          onCreatePressed: () {
            setState(() {
              isCreatingBanner = true;
            });
          },
          onViewPressed: (banner) {
            setState(() {
              selectedBanner = banner;
              isUpdatingBanner = true;
            });
          },
        );

      // 8 - Coupons
      case 8:
        if (isCreatingCoupon) {
          return CreateCouponPage(
            onBack: () {
              setState(() {
                isCreatingCoupon = false;
              });
            },
          );
        }
        if (isUpdatingCoupon && selectedCoupon != null) {
          return UpdateCouponPage(
            coupon: selectedCoupon!,
            onBack: () {
              setState(() {
                isUpdatingCoupon = false;
                selectedCoupon = null;
              });
            },
          );
        }
        return CouponsPage(
          onCreatePressed: () {
            setState(() {
              isCreatingCoupon = true;
            });
          },
          onViewPressed: (coupon) {
            setState(() {
              selectedCoupon = coupon;
              isUpdatingCoupon = true;
            });
          },
        );

      // 9 - Customers
      case 9:
        // Viewing an order that was opened from within a customer's detail page
        if (isViewingOrderFromCustomer && selectedOrderFromCustomer != null) {
          return OrderDetailsPage(
            order: selectedOrderFromCustomer!,
            onBack: () {
              setState(() {
                isViewingOrderFromCustomer = false;
                selectedOrderFromCustomer = null;
              });
            },
          );
        }

        if (isViewingCustomer && selectedCustomer != null) {
          return CustomerDetailPage(
            customer: selectedCustomer!,
            onBack: () {
              setState(() {
                isViewingCustomer = false;
                selectedCustomer = null;
              });
            },
            onOrderTap: (order) {
              setState(() {
                selectedOrderFromCustomer = order;
                isViewingOrderFromCustomer = true;
              });
            },
          );
        }

        return CustomersPage(
          onView: (CustomerModel customer) {
            setState(() {
              selectedCustomer = customer;
              isViewingCustomer = true;
            });
          },
        );

      // 10 - Admins
      case 10:
        if (isCreatingAdmin) {
          return CreateAdminPage(
            onBack: () {
              setState(() {
                isCreatingAdmin = false;
              });
            },
          );
        }
        if (isUpdatingAdmin && selectedAdmin != null) {
          return UpdateAdminPage(
            admin: selectedAdmin!,
            onBack: () {
              setState(() {
                final returnToSettings = _cameFromSettings;
                isUpdatingAdmin = false;
                selectedAdmin = null;
                _cameFromSettings = false;
                if (returnToSettings) {
                  selectedIndex = 11; // Back to Settings
                }
              });
            },
          );
        }
        return AdminsPage(
          onCreatePressed: () {
            setState(() {
              isCreatingAdmin = true;
            });
          },
          onEditPressed: (admin) {
            setState(() {
              selectedAdmin = admin;
              isUpdatingAdmin = true;
            });
          },
        );

      // 12 - Campaigns
      case 12:
        return const CampaignsPage();

      // 13 - Prescription Requests
      case 13:
        if (isViewingPrescriptionRequest &&
            selectedPrescriptionRequest != null) {
          return PrescriptionRequestDetailPage(
            request: selectedPrescriptionRequest!,
            onBack: () {
              setState(() {
                isViewingPrescriptionRequest = false;
                selectedPrescriptionRequest = null;
              });
            },
          );
        }
        return PrescriptionRequestsPage(
          onView: (PrescriptionRequestModel req) {
            setState(() {
              selectedPrescriptionRequest = req;
              isViewingPrescriptionRequest = true;
            });
          },
        );

      // 11 - Settings
      case 11:
        return SettingsPage(
          onChangePassword: () {
            // Navigate to Update Admin page for current logged-in user
            final authCtrl = Get.find<AuthController>();
            final u = authCtrl.user.value;
            setState(() {
              selectedAdmin = {
                'id': u.id,
                'firstName': u.firstName,
                'lastName': u.lastName,
                'email': u.email,
                'phoneNumber': u.phoneNumber,
                'isActive': true,
              };
              isUpdatingAdmin = true;
              _cameFromSettings = true;
              selectedIndex = 10; // Admins section hosts UpdateAdminPage
            });
          },
        );

      default:
        return const DashboardPage();
    }
  }

  void handleLogout() {
    // Show confirmation dialog
    Get.dialog(
      AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Get.back(); // Close dialog
              Get.find<AuthController>().logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Sidebar(
            selectedIndex: selectedIndex,
            onItemSelected: (index) {
              setState(() {
                selectedIndex = index;
              });
            },
            onLogout: handleLogout,
          ),
          Expanded(
            child: Column(
              children: [
                Topbar(
                  onSearchResultTap: (sectionIndex, query) {
                    setState(() {
                      selectedIndex = sectionIndex;
                      // Reset all create/update states
                      isCreatingCategory = false;
                      isUpdatingCategory = false;
                      isCreatingSubcategory = false;
                      isUpdatingSubcategory = false;
                      isCreatingBrand = false;
                      isUpdatingBrand = false;
                      isCreatingProduct = false;
                      isUpdatingProduct = false;
                      isViewingOrder = false;
                      isViewingCustomer = false;
                      isViewingOrderFromCustomer = false;
                      isCreatingBanner = false;
                      isUpdatingBanner = false;
                      isCreatingCoupon = false;
                      isUpdatingCoupon = false;
                      isCreatingAdmin = false;
                      isUpdatingAdmin = false;
                    });
                  },
                  onSettingsTap: () {
                    setState(() {
                      selectedIndex = 11;
                    });
                  },
                ),
                Expanded(
                  child: Container(
                    color: const Color(0xFFF5F6FA),
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🔹 Breadcrumb
                        Text(
                          "Dashboard / ${getPageTitle()}",
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // 🔹 Page Title
                        Text(
                          getPageTitle(),
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 🔹 Page Content
                        Expanded(child: getSelectedPage()),
                      ],
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
}
