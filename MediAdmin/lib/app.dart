import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:med_admin/features/pages/admin_login_page.dart';
import 'features/admins/controllers/admin_controller.dart';
import 'features/auth/controllers/auth_controller.dart';
import 'features/auth/services/auth_service.dart';
import 'features/categories/controllers/category_controller.dart';
import 'features/subcategories/controllers/subcategory_controller.dart';
import 'features/brands/controllers/brand_controller.dart';
import 'features/products/controllers/product_controller.dart';
import 'features/orders/controllers/order_controller.dart';
import 'features/customers/controllers/customer_controller.dart';
import 'features/dashboard/controllers/dashboard_controller.dart';
import 'features/banners/controllers/banner_controller.dart';
import 'layout/admin_layout.dart';
import 'utils/seed_data.dart';

class MediAdminApp extends StatelessWidget {
  const MediAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize services and controllers
    Get.put(AuthService());
    Get.put(AuthController());
    Get.put(CategoryController());
    Get.put(SubcategoryController());
    Get.put(BrandController());
    Get.put(ProductController());
    Get.put(AdminController());
    Get.put(OrderController());
    Get.put(CustomerController());
    Get.put(DashboardController());
    Get.put(BannerController());

    // Seed dummy data for testing (runs once, skips if data exists)
    SeedData.run();

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MediAI Admin Panel',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Urbanist',
        scaffoldBackgroundColor: const Color(0xFFF5F6FA),
      ),
      initialRoute: '/',
      getPages: [
        GetPage(name: '/', page: () => const AdminLoginPage()),
        GetPage(name: '/admin', page: () => const AdminLayout()),
      ],
    );
  }
}
