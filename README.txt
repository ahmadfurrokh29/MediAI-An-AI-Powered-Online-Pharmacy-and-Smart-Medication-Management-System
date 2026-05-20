═══════════════════════════════════════════════════════════════════════════════
                          MEDIAI - COMPREHENSIVE PROJECT DOCUMENTATION
                       Healthcare E-Commerce Platform with Medicine Reminder System
═══════════════════════════════════════════════════════════════════════════════

TABLE OF CONTENTS:
==================
1. PROJECT OVERVIEW
2. FILE STRUCTURE - E-COMMERCE STORE
3. FILE STRUCTURE - STOCK MANAGEMENT & REMINDER SYSTEM
4. FILE STRUCTURE - ADMIN PANEL (MediAdmin)
5. SYSTEM ARCHITECTURE DIAGRAM
6. USE CASE DIAGRAM
7. DATABASE ERD (ENTITY RELATIONSHIP DIAGRAM)
8. TECHNOLOGY STACK
9. KEY FEATURES SUMMARY


═══════════════════════════════════════════════════════════════════════════════
1. PROJECT OVERVIEW
═══════════════════════════════════════════════════════════════════════════════

MediAI is a comprehensive healthcare platform consisting of three main modules:

A) MOBILE APP (MediAI) - Customer-facing Flutter mobile application
   - E-commerce store for purchasing medicines
   - Medicine reminder & stock management system
   - AI-powered chatbot for health consultation
   - User profile & order management

B) WEB ADMIN PANEL (MediAdmin) - Administrative Flutter web application
   - Product, category, and brand management
   - Order processing and customer management
   - Promotional banners and coupon management
   - Real-time dashboard with analytics

C) BACKEND - Firebase Cloud Services
   - Firestore for real-time database
   - Firebase Authentication for user management
   - Firebase Storage for images
   - Cloud Functions for backend logic


═══════════════════════════════════════════════════════════════════════════════
2. FILE STRUCTURE - E-COMMERCE STORE
═══════════════════════════════════════════════════════════════════════════════

lib/features/shop/
│
├── screens/
│   ├── home/
│   │   └── home.dart                    # Home screen with banners, featured categories, recommended products
│   │
│   ├── store/
│   │   └── store.dart                   # Store screen with category tabs, brand showcase
│   │   └── widgets/category_tab.dart    # Dynamic category tabs for filtering
│   │
│   ├── product_details/
│   │   └── product_details.dart         # Product details with images, price, stock, reviews
│   │   └── widgets/
│   │       ├── product_meta_data.dart   # Product name, price, stock info
│   │       └── product_images.dart      # Image carousel
│   │
│   ├── cart/
│   │   └── cart.dart                    # Shopping cart with item list, quantity controls
│   │   └── widgets/cart_items.dart      # Cart item cards
│   │
│   ├── checkout/
│   │   └── checkout.dart                # Checkout screen with address, payment, coupon
│   │   └── widgets/
│   │       ├── billing_amount.dart      # Subtotal, shipping, tax, total breakdown
│   │       └── payment_tile.dart        # Payment method selection
│   │
│   ├── order/
│   │   └── order.dart                   # Order history list
│   │   └── order_details.dart           # Individual order details
│   │
│   ├── wishlist/
│   │   └── wishlist.dart                # Saved products for later
│   │
│   ├── all_products/
│   │   └── all_products.dart            # Product listing with filters
│   │
│   ├── brand/
│   │   └── brand_products.dart          # Products filtered by brand
│   │
│   └── sub_category/
│       └── sub_categories.dart          # Subcategory product listing
│
├── controllers/
│   ├── home_controller.dart             # Manages home screen data (banners, categories, products)
│   ├── category_controller.dart         # Category data fetching and management
│   ├── brand_controller.dart            # Brand data and product filtering
│   ├── product_controller.dart          # Product CRUD, search, filtering
│   ├── cart_controller.dart             # Cart operations (add, remove, update quantity, sync to Firebase)
│   ├── checkout_controller.dart         # Checkout process management
│   ├── order_controller.dart            # Place orders, fetch order history
│   ├── wishlist_controller.dart         # Wishlist add/remove, sync to Firebase
│   ├── payment_controller.dart          # Payment method selection
│   └── review_controller.dart           # Product reviews and ratings
│
└── models/
    ├── product_model.dart               # Product data structure (id, name, price, stock, images, etc.)
    ├── category_model.dart              # Category structure
    ├── brand_model.dart                 # Brand structure
    ├── cart_item_model.dart             # Cart item with quantity
    ├── order_model.dart                 # Order with items, status, payment info
    ├── order_item_model.dart            # Individual order item
    ├── banner_model.dart                # Promotional banner
    └── review_model.dart                # Product review with rating


KEY E-COMMERCE WORKFLOWS:
--------------------------

1. BROWSING & SEARCH
   - HomeController fetches featured categories & products from Firebase
   - BannerController displays active promotional banners
   - ProductController handles search and filtering
   - CategoryController manages category-based navigation

2. ADDING TO CART
   - User views product details
   - CartController.addToCart() saves to local state (RxList)
   - Syncs to Firestore: Users/{uid}/Cart subcollection
   - Reactive UI updates immediately

3. CHECKOUT PROCESS
   - CartController calculates totals (subtotal + shipping + tax)
   - AddressController provides shipping address
   - PaymentController selects payment method
   - CouponController validates and applies discount
   - OrderController.placeOrder() creates order in Firebase Orders collection

4. ORDER PLACEMENT
   - Order document created with items[], status="Pending", paymentStatus="Unpaid"
   - Cart cleared after successful order
   - User redirected to success screen
   - Admin panel can view and manage order


═══════════════════════════════════════════════════════════════════════════════
3. FILE STRUCTURE - STOCK MANAGEMENT & REMINDER SYSTEM
═══════════════════════════════════════════════════════════════════════════════

lib/features/personalization/screens/mymedication/
│
├── my_medication.dart                   # Main medication screen with tabs
│
├── stock_management_screen.dart         # Stock overview (out of stock, low stock, normal)
│
├── multi_disease_edit_page.dart         # Edit medicines with multiple diseases
│
├── reminder/
│   ├── medicine_form_page.dart          # Add/edit medicine form
│   └── widgets/
│       ├── alarm_time_picker.dart       # Time selection for alarms
│       └── stock_info_fields.dart       # Stock quantity input
│
├── alarm/
│   ├── alarm_trigger_screen.dart        # Full-screen alarm when medicine time arrives
│   └── widgets/
│       └── alarm_controls.dart          # Snooze, dismiss controls
│
└── services/
    ├── local_db.dart                    # SQLite database management (medicines, alarms, sync queue)
    ├── notification_service.dart        # Local notifications & full-screen alarms
    ├── sync_service.dart                # Bidirectional sync between SQLite and Firebase
    ├── offline_queue_service.dart       # Queue operations when offline
    ├── connectivity_service.dart        # Network monitoring
    └── stock_alert_service.dart         # Background stock checking and alerts


SQLITE DATABASE SCHEMA:
------------------------

TABLE: medicines
  - medId (PRIMARY KEY)          # Unique medicine identifier
  - uid                          # User ID
  - medicine_name                # Medicine name
  - disease_name                 # Comma-separated diseases (e.g., "Diabetes, Hypertension")
  - frequency                    # Dosage frequency (e.g., "3/day")
  - duration                     # Treatment duration (e.g., "7 days", "chronic")
  - start_date                   # Treatment start date
  - chronic (0/1)                # Is chronic condition?
  - total_no_of_doses            # Total pills needed for full course
  - available_stock              # Current pills in stock
  - alert_before_days            # Days before stock runs out to alert (default: 3)
  - synced (0/1)                 # Sync status with Firebase
  - local_updated_at             # Timestamp for conflict resolution

TABLE: alarms
  - alarmId (PRIMARY KEY)        # Unique alarm identifier
  - uid                          # User ID
  - medId (FOREIGN KEY)          # Links to medicines table
  - specific_dose                # Dose description (e.g., "1 tablet")
  - time_hour (0-23)             # Alarm hour
  - time_minute (0-59)           # Alarm minute
  - duration                     # How long alarm is active
  - isActive (0/1)               # Is alarm enabled?
  - synced (0/1)                 # Sync status
  - local_updated_at             # Timestamp

TABLE: pending_changes (Offline Queue)
  - id                           # Auto-increment
  - operation_type               # INSERT/UPDATE/DELETE
  - entity_type                  # MEDICINE/ALARM
  - entity_id                    # Medicine or alarm ID
  - entity_data                  # JSON serialized data
  - timestamp                    # When operation occurred
  - synced (0/1)                 # Processed status


FIREBASE COLLECTIONS (for sync):
---------------------------------

Users/{uid}/medicines/{medId}
  - Same fields as SQLite medicines table
  - Synced when online

Users/{uid}/medicines/{medId}/alarms/{alarmId}
  - Same fields as SQLite alarms table
  - Subcollection under each medicine


KEY REMINDER WORKFLOWS:
-----------------------

1. ADDING A MEDICINE
   - User fills form: name, disease, frequency, duration, start date, stock
   - Sets alarm times for each dose
   - Saved to SQLite medicines + alarms tables
   - NotificationService schedules local alarms
   - Queued for Firebase sync (offline_queue_service)
   - Synced to Firebase when online

2. MEDICINE ALARM TRIGGERS
   - flutter_local_notifications triggers at scheduled time
   - Full-screen AlarmTriggerScreen appears
   - User can snooze (10 min) or dismiss
   - On dismiss, stock decremented automatically
   - Background WorkManager ensures alarms work even when app closed

3. STOCK MONITORING
   - Background worker runs periodic stock checks
   - Low stock logic: current_stock <= (frequency_per_day × alert_before_days)
   - Out of stock: available_stock = 0
   - Chronic medicines: alert when low regardless of total doses
   - Non-chronic: if stock >= total_no_of_doses, no alert
   - Alerts sent via notification + saved to Users/{uid}/Notifications

4. OFFLINE-FIRST SYNC
   - All medicine operations saved to SQLite first
   - Changes queued in pending_changes table when offline
   - ConnectivityService monitors network
   - When online, SyncService pushes local changes to Firebase
   - Pulls remote changes and merges with local data
   - Conflict resolution using local_updated_at timestamp


═══════════════════════════════════════════════════════════════════════════════
4. FILE STRUCTURE - ADMIN PANEL (MediAdmin)
═══════════════════════════════════════════════════════════════════════════════

MediAdmin/lib/
│
├── main.dart                            # Entry point, Firebase initialization
│
├── routes/
│   └── app_routes.dart                  # Route definitions (/login, /admin, /dashboard)
│
├── features/
│   │
│   ├── authentication/
│   │   ├── screens/
│   │   │   └── login_page.dart          # Admin login screen
│   │   └── controllers/
│   │       └── auth_controller.dart     # Admin authentication, role verification
│   │
│   ├── dashboard/
│   │   ├── screens/
│   │   │   └── dashboard_page.dart      # Real-time stats, charts, low stock alerts
│   │   └── controllers/
│   │       └── dashboard_controller.dart # Fetch and calculate metrics
│   │
│   ├── categories/
│   │   ├── screens/
│   │   │   └── categories_page.dart     # Category management table
│   │   ├── controllers/
│   │   │   └── category_controller.dart # CRUD operations for categories
│   │   └── models/
│   │       └── category_model.dart      # Category data structure
│   │
│   ├── subcategories/
│   │   ├── screens/
│   │   │   └── subcategories_page.dart  # Subcategory management
│   │   ├── controllers/
│   │   │   └── subcategory_controller.dart
│   │   └── models/
│   │       └── subcategory_model.dart
│   │
│   ├── brands/
│   │   ├── screens/
│   │   │   └── brands_page.dart         # Brand management
│   │   ├── controllers/
│   │   │   └── brand_controller.dart    # Multi-category brand assignment
│   │   └── models/
│   │       └── brand_model.dart
│   │
│   ├── products/
│   │   ├── screens/
│   │   │   ├── products_page.dart       # Product listing with triple filter
│   │   │   └── recommended_products_page.dart # Manage recommended products
│   │   ├── controllers/
│   │   │   └── product_controller.dart  # Product CRUD, stock management
│   │   └── models/
│   │       └── product_model.dart       # Product with denormalized data
│   │
│   ├── orders/
│   │   ├── screens/
│   │   │   └── orders_page.dart         # Order management, status updates
│   │   ├── controllers/
│   │   │   └── order_controller.dart    # Update order & payment status
│   │   └── models/
│   │       └── order_model.dart
│   │
│   ├── customers/
│   │   ├── screens/
│   │   │   └── customers_page.dart      # Customer list and details
│   │   ├── controllers/
│   │   │   └── customer_controller.dart # Fetch customers (role='Customer')
│   │   └── models/
│   │       └── customer_model.dart
│   │
│   ├── banners/
│   │   ├── screens/
│   │   │   └── banners_page.dart        # Banner management
│   │   ├── controllers/
│   │   │   └── banner_controller.dart   # CRUD, redirect management
│   │   └── models/
│   │       └── banner_model.dart
│   │
│   ├── coupons/
│   │   ├── screens/
│   │   │   └── coupons_page.dart        # Coupon management
│   │   ├── controllers/
│   │   │   └── coupon_controller.dart   # Discount management
│   │   └── models/
│   │       └── coupon_model.dart
│   │
│   └── admins/
│       ├── screens/
│       │   └── admins_page.dart         # Admin user management
│       ├── controllers/
│       │   └── admin_controller.dart    # Create admin via secondary FirebaseApp
│       └── models/
│           └── admin_model.dart
│
└── common/
    └── widgets/
        ├── sidebar.dart                 # Navigation sidebar with menu items
        ├── topbar.dart                  # Page header with breadcrumbs
        └── data_table.dart              # Reusable table component


ADMIN PANEL FEATURES:
---------------------

1. DASHBOARD (Index 0)
   - Today's sales total
   - Average order value
   - Total orders today
   - Products sold today
   - Order status chart
   - Low stock alerts (stock ≤ 10)
   - Recent orders
   - Export to Excel

2. CATEGORIES (Index 1)
   - Create, Read, Update, Delete categories
   - Toggle IsFeatured (controls "Top Categories" in mobile app)
   - Toggle IsActive (show/hide in store)
   - Real-time search

3. SUBCATEGORIES (Index 2)
   - Full CRUD with parent category selection
   - Featured & Active toggles

4. BRANDS (Index 3)
   - Multi-category assignment
   - Featured brands for store showcase

5. PRODUCTS (Index 4)
   - Triple filter: Search + Category + Brand
   - Stock level color coding (green/orange/red)
   - Featured products (Popular Products)
   - Active/Inactive toggle

6. RECOMMENDED PRODUCTS (Index 5)
   - Manage recommended products per category
   - Toggle recommended status

7. ORDERS (Index 6)
   - View all orders
   - Update order status: Pending → Processing → Shipped → Delivered
   - Update payment status: Unpaid → Paid
   - Auto-payment on COD delivery
   - Search by order ID, customer

8. CUSTOMERS (Index 9)
   - View customer profiles
   - Order history per customer
   - Points & loyalty tracking
   - Delete customer

9. BANNERS (Index 7)
   - Upload banner images
   - Set redirect targets
   - Start/end dates
   - Track views & clicks

10. COUPONS (Index 8)
    - Create discount coupons
    - FLAT or PERCENTAGE type
    - Usage limits & expiry dates

11. ADMINS (Index 10)
    - Create admin accounts (secondary Firebase app)
    - Role assignment
    - Active/Inactive status


═══════════════════════════════════════════════════════════════════════════════
5. SYSTEM ARCHITECTURE DIAGRAM
═══════════════════════════════════════════════════════════════════════════════

┌─────────────────────────────────────────────────────────────────────────────┐
│                            PRESENTATION LAYER                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────────────────────┐          ┌──────────────────────────┐        │
│  │   MOBILE APP (Flutter)   │          │ WEB ADMIN (Flutter Web)  │        │
│  │                          │          │                          │        │
│  │  • Home & Store          │          │  • Dashboard             │        │
│  │  • Product Browsing      │          │  • Product Management    │        │
│  │  • Cart & Checkout       │          │  • Order Management      │        │
│  │  • Medicine Reminders    │          │  • Customer Management   │        │
│  │  • Stock Management      │          │  • Promotions (Banners)  │        │
│  │  • AI Chatbot            │          │  • Coupon Management     │        │
│  │  • Profile & Orders      │          │  • Admin Management      │        │
│  └────────────┬─────────────┘          └─────────────┬────────────┘        │
│               │                                       │                      │
└───────────────┼───────────────────────────────────────┼──────────────────────┘
                │                                       │
                │                                       │
┌───────────────┼───────────────────────────────────────┼──────────────────────┐
│               │         APPLICATION LAYER             │                      │
├───────────────┼───────────────────────────────────────┼──────────────────────┤
│               │                                       │                      │
│  ┌────────────▼───────────┐          ┌───────────────▼────────────┐         │
│  │  GetX Controllers      │          │  GetX Controllers          │         │
│  │  (Mobile App)          │          │  (Admin Panel)             │         │
│  │                        │          │                            │         │
│  │  • HomeController      │          │  • DashboardController     │         │
│  │  • CartController      │          │  • ProductController       │         │
│  │  • OrderController     │          │  • OrderController         │         │
│  │  • ProductController   │          │  • CategoryController      │         │
│  │  • WishlistController  │          │  • BannerController        │         │
│  └────────────┬───────────┘          └───────────────┬────────────┘         │
│               │                                       │                      │
│  ┌────────────▼───────────────────────────────────────▼────────────┐        │
│  │                     Business Logic Layer                         │        │
│  │                                                                  │        │
│  │  • Authentication Logic      • Order Processing                 │        │
│  │  • Product Filtering         • Payment Validation               │        │
│  │  • Stock Calculation         • Discount Calculation             │        │
│  │  • Medicine Scheduling       • Report Generation                │        │
│  └──────────────────────────────┬──────────────────────────────────┘        │
│                                 │                                            │
└─────────────────────────────────┼────────────────────────────────────────────┘
                                  │
┌─────────────────────────────────┼────────────────────────────────────────────┐
│                                 │     DATA LAYER                             │
├─────────────────────────────────┼────────────────────────────────────────────┤
│                                 │                                            │
│  ┌──────────────────────────────▼──────────────────────────────┐            │
│  │                    Repository Pattern                        │            │
│  │                                                              │            │
│  │  • AuthenticationRepository  • ProductRepository            │            │
│  │  • UserRepository           • OrderRepository              │            │
│  │  • CategoryRepository       • BannerRepository             │            │
│  └───────────┬───────────────────────────────┬──────────────────┘            │
│              │                               │                               │
│              ▼                               ▼                               │
│  ┌───────────────────────┐      ┌──────────────────────────┐               │
│  │   LOCAL STORAGE       │      │   CLOUD STORAGE          │               │
│  │                       │      │                          │               │
│  │  ┌─────────────────┐  │      │  ┌────────────────────┐ │               │
│  │  │ SQLite Database │  │      │  │  Firebase Firestore│ │               │
│  │  │                 │  │      │  │                    │ │               │
│  │  │ • medicines     │  │◄────┼──┼─►│ • Users          │ │               │
│  │  │ • alarms        │  │ Sync│  │  │ • Products       │ │               │
│  │  │ • pending_      │  │     │  │  │ • Categories     │ │               │
│  │  │   changes       │  │     │  │  │ • Orders         │ │               │
│  │  └─────────────────┘  │      │  │ • Banners        │ │               │
│  │                       │      │  │ • Brands         │ │               │
│  │  ┌─────────────────┐  │      │  │ • Admins         │ │               │
│  │  │ GetStorage      │  │      │  └────────────────────┘ │               │
│  │  │ (Key-Value)     │  │      │                          │               │
│  │  │                 │  │      │  ┌────────────────────┐ │               │
│  │  │ • Preferences   │  │      │  │ Firebase Auth      │ │               │
│  │  │ • Session Data  │  │      │  │                    │ │               │
│  │  └─────────────────┘  │      │  │ • Email/Password   │ │               │
│  │                       │      │  │ • Google Sign-In   │ │               │
│  └───────────────────────┘      │  │ • Facebook Auth    │ │               │
│                                 │  └────────────────────┘ │               │
│                                 │                          │               │
│                                 │  ┌────────────────────┐ │               │
│                                 │  │ Firebase Storage   │ │               │
│                                 │  │                    │ │               │
│                                 │  │ • Product Images   │ │               │
│                                 │  │ • Banner Images    │ │               │
│                                 │  │ • Profile Photos   │ │               │
│                                 │  └────────────────────┘ │               │
│                                 └──────────────────────────┘               │
└────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                        BACKGROUND SERVICES LAYER                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────────────┐  ┌──────────────────────┐  ┌──────────────────┐   │
│  │ Notification Service│  │ Connectivity Service │  │  WorkManager     │   │
│  │                     │  │                      │  │                  │   │
│  │ • Alarm Scheduling  │  │ • Network Monitoring │  │ • Stock Alerts   │   │
│  │ • Full-Screen Alerts│  │ • Auto Sync Trigger  │  │ • Background Sync│   │
│  │ • Local Notifications│ │                     │  │ • Periodic Tasks │   │
│  └─────────────────────┘  └──────────────────────┘  └──────────────────┘   │
│                                                                              │
│  ┌─────────────────────┐  ┌──────────────────────┐                          │
│  │   Sync Service      │  │ Offline Queue Service│                          │
│  │                     │  │                      │                          │
│  │ • Push Local → Cloud│  │ • Queue Operations   │                          │
│  │ • Pull Cloud → Local│  │ • Retry Logic        │                          │
│  │ • Conflict Resolution│ │ • Deduplication      │                          │
│  └─────────────────────┘  └──────────────────────┘                          │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘


ARCHITECTURE HIGHLIGHTS:
------------------------

1. CLEAN ARCHITECTURE PATTERN
   - Separation of concerns: Presentation, Business Logic, Data layers
   - Repository pattern for data abstraction
   - GetX for state management and dependency injection

2. OFFLINE-FIRST DESIGN
   - SQLite for critical medicine data
   - Local caching with GetStorage
   - Sync queue for offline operations
   - Automatic synchronization when online

3. REAL-TIME SYNCHRONIZATION
   - Firestore real-time listeners
   - Bidirectional sync (local ↔ cloud)
   - Conflict resolution with timestamps

4. MICROSERVICES APPROACH
   - Dedicated services: Notification, Sync, Connectivity, Stock Alerts
   - Background workers for critical tasks
   - Service isolation for maintainability

5. SECURITY LAYERS
   - Firebase Authentication
   - Role-based access control (Customer/Admin)
   - Firestore security rules
   - Data validation at multiple layers


═══════════════════════════════════════════════════════════════════════════════
AI PROMPT TO RECREATE SYSTEM ARCHITECTURE DIAGRAM:
═══════════════════════════════════════════════════════════════════════════════

Create a detailed System Architecture Diagram for MediAI, a healthcare e-commerce platform with medicine reminder system. The architecture should include:

**LAYERS (Top to Bottom):**

1. **Presentation Layer**:
   - Mobile App (Flutter): Home, Store, Cart, Checkout, Medicine Reminders, Stock Management, AI Chatbot, Profile
   - Web Admin Panel (Flutter Web): Dashboard, Product Management, Order Management, Customer Management, Banners, Coupons, Admin Management

2. **Application Layer**:
   - GetX Controllers for Mobile App: HomeController, CartController, OrderController, ProductController, WishlistController
   - GetX Controllers for Admin: DashboardController, ProductController, OrderController, CategoryController, BannerController
   - Business Logic: Authentication, Order Processing, Product Filtering, Stock Calculation, Medicine Scheduling, Payment Validation, Discount Calculation, Report Generation

3. **Data Layer**:
   - Repository Pattern: AuthenticationRepository, UserRepository, ProductRepository, OrderRepository, CategoryRepository, BannerRepository
   
   **Local Storage**:
   - SQLite Database: medicines table, alarms table, pending_changes table (with bidirectional sync arrow to Firebase)
   - GetStorage: Preferences, Session Data
   
   **Cloud Storage**:
   - Firebase Firestore: Collections (Users, Products, Categories, Orders, Banners, Brands, Admins) with nested subcollections (Cart, Wishlist, medicines/alarms under Users)
   - Firebase Authentication: Email/Password, Google Sign-In, Facebook Auth
   - Firebase Storage: Product Images, Banner Images, Profile Photos

4. **Background Services Layer**:
   - Notification Service: Alarm Scheduling, Full-Screen Alerts, Local Notifications
   - Connectivity Service: Network Monitoring, Auto Sync Trigger
   - WorkManager: Stock Alerts, Background Sync, Periodic Tasks
   - Sync Service: Push Local to Cloud, Pull Cloud to Local, Conflict Resolution
   - Offline Queue Service: Queue Operations, Retry Logic, Deduplication

**ARCHITECTURE HIGHLIGHTS** (add as notes):
- Clean Architecture with separation of concerns
- Offline-First design with SQLite
- Real-time synchronization with Firestore
- Microservices approach with dedicated background services
- Role-based security (Customer/Admin)

**VISUAL REQUIREMENTS**:
- Use boxes/containers for each layer
- Draw arrows showing data flow between components
- Show bidirectional sync between SQLite and Firebase
- Use different colors for Mobile App (blue), Admin Panel (green), Backend (orange)
- Include icons for databases, cloud services, and mobile devices
- Make it professional and suitable for a presentation


═══════════════════════════════════════════════════════════════════════════════
6. USE CASE DIAGRAM
═══════════════════════════════════════════════════════════════════════════════

                         MEDIAI - USE CASE DIAGRAM
                         ========================

┌──────────────┐                                              ┌──────────────┐
│              │                                              │              │
│   CUSTOMER   │                                              │    ADMIN     │
│              │                                              │              │
└──────┬───────┘                                              └──────┬───────┘
       │                                                             │
       │                                                             │
       │  ┌─────────────────────────────────────────────────────┐   │
       │  │              E-COMMERCE SYSTEM                       │   │
       │  │                                                      │   │
       ├──┼─►  Register/Login                                   │   │
       │  │                                                      │   │
       ├──┼─►  Browse Products                                  │   │
       │  │     • View by Category                              │   │
       │  │     • View by Brand                                 │   │
       │  │     • Search Products                               │   │
       │  │     • Filter Products                               │   │
       │  │                                                      │   │
       ├──┼─►  View Product Details                             │   │
       │  │     • View Images                                   │   │
       │  │     • Read Reviews                                  │   │
       │  │     • Check Stock                                   │   │
       │  │                                                      │   │
       ├──┼─►  Add to Cart                                      │   │
       │  │                                                      │   │
       ├──┼─►  Manage Cart                                      │   │
       │  │     • Update Quantity                               │   │
       │  │     • Remove Items                                  │   │
       │  │                                                      │   │
       ├──┼─►  Add to Wishlist                                  │   │
       │  │                                                      │   │
       ├──┼─►  Checkout                                         │   │
       │  │     • Select Address          ◄─── <<extends>> ─────┼───┼─  Manage Addresses
       │  │     • Choose Payment Method                         │   │
       │  │     • Apply Coupon Code                             │   │
       │  │     • Place Order                                   │   │
       │  │                                                      │   │
       ├──┼─►  View Order History                               │   │
       │  │     • Track Order Status                            │   │
       │  │                                                      │   │
       ├──┼─►  Write Product Review                             │   │
       │  │                                                      │   │
       ├──┼─►  Manage Profile                                   │   │
       │  │     • Update Personal Info                          │   │
       │  │     • Upload Profile Picture                        │   │
       │  │                                                      │   │
       │  └──────────────────────────────────────────────────────┘   │
       │                                                             │
       │  ┌─────────────────────────────────────────────────────┐   │
       │  │       MEDICINE REMINDER & STOCK SYSTEM              │   │
       │  │                                                      │   │
       ├──┼─►  Add Medicine                                     │   │
       │  │     • Manual Entry                                  │   │
       │  │     • OCR Scan Prescription                         │   │
       │  │                                                      │   │
       ├──┼─►  Set Medicine Reminders                           │   │
       │  │     • Set Alarm Times                               │   │
       │  │     • Configure Frequency                           │   │
       │  │     • Set Duration                                  │   │
       │  │                                                      │   │
       ├──┼─►  Receive Alarm Notifications                      │   │
       │  │     • Full-Screen Alert                             │   │
       │  │     • Snooze Alarm                                  │   │
       │  │     • Mark as Taken                                 │   │
       │  │                                                      │   │
       ├──┼─►  Manage Medicine Stock                            │   │
       │  │     • View Stock Levels                             │   │
       │  │     • Update Stock Quantity                         │   │
       │  │     • Set Alert Thresholds                          │   │
       │  │                                                      │   │
       ├──┼─►  Receive Stock Alerts                             │   │
       │  │     • Low Stock Notifications                       │   │
       │  │     • Out of Stock Warnings                         │   │
       │  │                                                      │   │
       ├──┼─►  View Medicine History                            │   │
       │  │                                                      │   │
       ├──┼─►  Edit/Delete Medicine                             │   │
       │  │                                                      │   │
       │  └──────────────────────────────────────────────────────┘   │
       │                                                             │
       │  ┌─────────────────────────────────────────────────────┐   │
       │  │              AI CHATBOT SYSTEM                       │   │
       │  │                                                      │   │
       ├──┼─►  Consult AI Pharmacist                            │   │
       │  │     • Ask Health Questions                          │   │
       │  │     • Get Medicine Recommendations                  │   │
       │  │                                                      │   │
       │  └──────────────────────────────────────────────────────┘   │
       │                                                             │
       │                                                             │
       │                                                             │
       │  ┌─────────────────────────────────────────────────────┐   │
       │  │          ADMIN MANAGEMENT SYSTEM                     │   │
       │  │                                                      │   │
       │  │                                      Admin Login  ◄──┼───┤
       │  │                                                      │   │
       │  │                          View Dashboard Statistics ◄┼───┤
       │  │                                   • Today's Sales    │   │
       │  │                                   • Order Metrics    │   │
       │  │                                   • Low Stock Alerts │   │
       │  │                                   • Order Charts     │   │
       │  │                                                      │   │
       │  │                            Manage Categories      ◄──┼───┤
       │  │                                   • Create/Edit/Delete│  │
       │  │                                   • Toggle Featured  │   │
       │  │                                   • Toggle Active    │   │
       │  │                                                      │   │
       │  │                            Manage Subcategories   ◄──┼───┤
       │  │                                                      │   │
       │  │                            Manage Brands          ◄──┼───┤
       │  │                                   • Multi-Category   │   │
       │  │                                     Assignment       │   │
       │  │                                                      │   │
       │  │                            Manage Products        ◄──┼───┤
       │  │                                   • Create/Edit/Delete│  │
       │  │                                   • Update Stock     │   │
       │  │                                   • Set Pricing      │   │
       │  │                                   • Upload Images    │   │
       │  │                                   • Toggle Featured  │   │
       │  │                                   • Set Recommended  │   │
       │  │                                                      │   │
       │  │                            Process Orders         ◄──┼───┤
       │  │                                   • Update Order Status│ │
       │  │                                   • Update Payment   │   │
       │  │                                     Status           │   │
       │  │                                   • View Order Details│  │
       │  │                                   • Delete Orders    │   │
       │  │                                                      │   │
       │  │                            Manage Customers       ◄──┼───┤
       │  │                                   • View Profiles    │   │
       │  │                                   • View Order History│  │
       │  │                                   • Delete Customers │   │
       │  │                                                      │   │
       │  │                            Manage Banners         ◄──┼───┤
       │  │                                   • Create/Edit/Delete│  │
       │  │                                   • Set Redirect Target│ │
       │  │                                   • Set Date Range   │   │
       │  │                                   • Track Views/Clicks│  │
       │  │                                                      │   │
       │  │                            Manage Coupons         ◄──┼───┤
       │  │                                   • Create/Edit/Delete│  │
       │  │                                   • Set Discount Type │  │
       │  │                                   • Set Expiry Date  │   │
       │  │                                   • Set Usage Limits │   │
       │  │                                                      │   │
       │  │                            Manage Admins          ◄──┼───┤
       │  │                                   • Create Admin Accounts│
       │  │                                   • Assign Roles      │   │
       │  │                                   • Toggle Active Status│ │
       │  │                                                      │   │
       │  │                            Export Reports         ◄──┼───┤
       │  │                                   • Export to Excel  │   │
       │  │                                                      │   │
       │  └──────────────────────────────────────────────────────┘   │
       │                                                             │
       │                                                             │
       │  ┌─────────────────────────────────────────────────────┐   │
       │  │              SYSTEM (Background)                     │   │
       │  │                                                      │   │
       │  │         Sync Data (SQLite ↔ Firebase)               │   │
       │  │         Schedule Notifications                      │   │
       │  │         Monitor Connectivity                        │   │
       │  │         Check Stock Levels (Periodic)               │   │
       │  │         Queue Offline Operations                    │   │
       │  │                                                      │   │
       │  └──────────────────────────────────────────────────────┘   │
       │                                                             │


ACTOR RELATIONSHIPS:
--------------------

1. CUSTOMER (Primary User)
   - Browses and purchases medicines
   - Manages personal medicine inventory and reminders
   - Interacts with AI chatbot for consultation
   - Reviews products and tracks orders

2. ADMIN (System Administrator)
   - Manages all backend operations
   - Controls product catalog (categories, brands, products)
   - Processes customer orders
   - Creates promotions (banners, coupons)
   - Manages customer accounts and admin users
   - Views analytics and generates reports

3. SYSTEM (Automated Background Actor)
   - Synchronizes data between local SQLite and Firebase
   - Schedules and triggers medicine reminders
   - Monitors network connectivity
   - Performs periodic stock checks
   - Manages offline operation queue


USE CASE RELATIONSHIPS:
-----------------------

• <<extends>>: Select Address extends Checkout (optional step)
• <<includes>>: Place Order includes Payment Validation
• <<includes>>: Receive Alarm includes Update Stock (auto-decrement)


═══════════════════════════════════════════════════════════════════════════════
AI PROMPT TO RECREATE USE CASE DIAGRAM:
═══════════════════════════════════════════════════════════════════════════════

Create a comprehensive Use Case Diagram for MediAI, a healthcare e-commerce platform with medicine reminder system. Include the following:

**ACTORS (3 actors):**
1. **Customer** (Stick figure on left) - End users who buy medicines and manage reminders
2. **Admin** (Stick figure on right) - System administrators who manage the platform
3. **System** (Robot/Gear icon at bottom) - Automated background processes

**USE CASES grouped by MODULES:**

**MODULE 1: E-COMMERCE SYSTEM** (Large boundary box)
Customer use cases:
- Register/Login
- Browse Products (with sub-cases: View by Category, View by Brand, Search Products, Filter Products)
- View Product Details (with sub-cases: View Images, Read Reviews, Check Stock)
- Add to Cart
- Manage Cart (with sub-cases: Update Quantity, Remove Items)
- Add to Wishlist
- Checkout (with sub-cases: Select Address <<extends>>, Choose Payment Method, Apply Coupon Code, Place Order)
- View Order History (with sub-case: Track Order Status)
- Write Product Review
- Manage Profile (with sub-cases: Update Personal Info, Upload Profile Picture)

Customer & Admin shared:
- Manage Addresses

**MODULE 2: MEDICINE REMINDER & STOCK SYSTEM** (Large boundary box)
Customer use cases:
- Add Medicine (with sub-cases: Manual Entry, OCR Scan Prescription)
- Set Medicine Reminders (with sub-cases: Set Alarm Times, Configure Frequency, Set Duration)
- Receive Alarm Notifications (with sub-cases: Full-Screen Alert, Snooze Alarm, Mark as Taken)
- Manage Medicine Stock (with sub-cases: View Stock Levels, Update Stock Quantity, Set Alert Thresholds)
- Receive Stock Alerts (with sub-cases: Low Stock Notifications, Out of Stock Warnings)
- View Medicine History
- Edit/Delete Medicine

**MODULE 3: AI CHATBOT SYSTEM** (Boundary box)
Customer use cases:
- Consult AI Pharmacist (with sub-cases: Ask Health Questions, Get Medicine Recommendations)

**MODULE 4: ADMIN MANAGEMENT SYSTEM** (Large boundary box)
Admin use cases:
- Admin Login
- View Dashboard Statistics (with sub-cases: Today's Sales, Order Metrics, Low Stock Alerts, Order Charts)
- Manage Categories (with sub-cases: Create/Edit/Delete, Toggle Featured, Toggle Active)
- Manage Subcategories
- Manage Brands (with sub-case: Multi-Category Assignment)
- Manage Products (with sub-cases: Create/Edit/Delete, Update Stock, Set Pricing, Upload Images, Toggle Featured, Set Recommended)
- Process Orders (with sub-cases: Update Order Status, Update Payment Status, View Order Details, Delete Orders)
- Manage Customers (with sub-cases: View Profiles, View Order History, Delete Customers)
- Manage Banners (with sub-cases: Create/Edit/Delete, Set Redirect Target, Set Date Range, Track Views/Clicks)
- Manage Coupons (with sub-cases: Create/Edit/Delete, Set Discount Type, Set Expiry Date, Set Usage Limits)
- Manage Admins (with sub-cases: Create Admin Accounts, Assign Roles, Toggle Active Status)
- Export Reports (with sub-case: Export to Excel)

**MODULE 5: SYSTEM (Background Processes)** (Boundary box)
System automated use cases:
- Sync Data (SQLite ↔ Firebase)
- Schedule Notifications
- Monitor Connectivity
- Check Stock Levels (Periodic)
- Queue Offline Operations

**RELATIONSHIPS TO SHOW:**
- Draw lines from Customer to all Customer use cases
- Draw lines from Admin to all Admin use cases
- Draw lines from System to all System use cases
- Use <<extends>> for Select Address extending Checkout
- Use <<includes>> for Place Order including Payment Validation
- Use <<includes>> for Receive Alarm including Update Stock

**VISUAL REQUIREMENTS:**
- Use UML standard notation
- Place Customer stick figure on LEFT
- Place Admin stick figure on RIGHT
- Place System icon at BOTTOM
- Group use cases in clearly labeled boundary boxes by module
- Use ellipses for use cases
- Use clear, readable labels
- Color code: Customer use cases (blue), Admin use cases (green), System use cases (orange)
- Make it professional and suitable for a presentation


═══════════════════════════════════════════════════════════════════════════════
7. DATABASE ERD (ENTITY RELATIONSHIP DIAGRAM)
═══════════════════════════════════════════════════════════════════════════════

                    MEDIAI - DATABASE ENTITY RELATIONSHIP DIAGRAM
                    =============================================

┌─────────────────────────────────────────────────────────────────────────────┐
│                           FIREBASE FIRESTORE                                 │
└─────────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────┐
│        Users             │──────────┐
├──────────────────────────┤          │
│ PK: id (uid)             │          │
│ FirstName                │          │
│ LastName                 │          │
│ Email                    │          │
│ PhoneNumber              │          │
│ Gender                   │          │
│ DateOfBirth              │          │
│ ProfilePicture           │          │
│ role                     │          │
│ points                   │          │
│ orderCount               │          │
│ isEmailVerified          │          │
│ addresses[]              │          │
│ selectedAddressIndex     │          │
│ shippingAddress{}        │          │
│ CreatedAt                │          │
└──────────┬───────────────┘          │
           │                          │
           │ 1                        │
           │                          │
           │ *                        │
           │                          │
           │                          │
┌──────────▼───────────────┐          │              ┌─────────────────────────┐
│   Cart (Subcollection)   │          │              │ Wishlist (Subcollection)│
├──────────────────────────┤          │              ├─────────────────────────┤
│ PK: cartItemId           │          │              │ PK: wishlistId          │
│ FK: uid (Users)          │          │              │ FK: uid (Users)         │
│ FK: productId (Products) │          │              │ FK: productId (Products)│
│ quantity                 │          │              │ CreatedAt               │
│ price                    │          │              └─────────────────────────┘
│ CreatedAt                │          │
└──────────────────────────┘          │
                                      │
                                      │
┌──────────────────────────┐          │
│ Notifications            │          │
│ (Subcollection)          │          │
├──────────────────────────┤          │
│ PK: notificationId       │◄─────────┘
│ FK: uid (Users)          │
│ title                    │
│ message                  │
│ type                     │
│ isRead                   │
│ CreatedAt                │
└──────────────────────────┘


┌──────────────────────────┐          ┌──────────────────────────┐
│   medicines              │          │   alarms                 │
│   (Subcollection)        │          │   (Subcollection)        │
├──────────────────────────┤          ├──────────────────────────┤
│ PK: medId                │─────┬───►│ PK: alarmId              │
│ FK: uid (Users)          │     │1  *│ FK: uid (Users)          │
│ medicine_name            │     │    │ FK: medId (medicines)    │
│ disease_name             │     │    │ specific_dose            │
│ frequency                │     │    │ time_hour                │
│ duration                 │     │    │ time_minute              │
│ start_date               │     │    │ duration                 │
│ chronic                  │     │    │ isActive                 │
│ total_no_of_doses        │     │    │ synced                   │
│ available_stock          │     │    │ local_updated_at         │
│ alert_before_days        │     │    │ updatedAt                │
│ synced                   │     │    │ CreatedAt                │
│ local_updated_at         │     │    └──────────────────────────┘
│ updatedAt                │     │
│ CreatedAt                │     │
└──────────────────────────┘     │
           ▲                     │
           │                     │
           │ Sync                │
           │                     │
           ▼                     │
┌─────────────────────────────────────────────────────────────────────────────┐
│                             SQLITE DATABASE                                  │
│                          (medicines.db - Local)                              │
└─────────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────┐          ┌──────────────────────────┐
│   medicines (Local)      │          │   alarms (Local)         │
├──────────────────────────┤          ├──────────────────────────┤
│ PK: medId                │─────┬───►│ PK: alarmId              │
│ uid                      │     │1  *│ uid                      │
│ medicine_name            │     │    │ FK: medId (medicines)    │
│ disease_name             │     │    │ specific_dose            │
│ frequency                │     │    │ time_hour                │
│ duration                 │     │    │ time_minute              │
│ start_date               │     │    │ duration                 │
│ chronic                  │     │    │ isActive                 │
│ total_no_of_doses        │     │    │ synced                   │
│ available_stock          │     │    │ local_updated_at         │
│ alert_before_days        │     └────┴──────────────────────────┘
│ synced                   │
│ local_updated_at         │
└──────────────────────────┘


┌──────────────────────────┐
│   pending_changes        │
│   (Offline Queue)        │
├──────────────────────────┤
│ PK: id                   │
│ operation_type           │
│ entity_type              │
│ entity_id                │
│ entity_data (JSON)       │
│ timestamp                │
│ synced                   │
└──────────────────────────┘


┌─────────────────────────────────────────────────────────────────────────────┐
│                    FIREBASE FIRESTORE (E-Commerce)                           │
└─────────────────────────────────────────────────────────────────────────────┘


┌──────────────────────────┐          ┌──────────────────────────┐
│      Categories          │          │    Subcategories         │
├──────────────────────────┤          ├──────────────────────────┤
│ PK: id                   │─────┬───►│ PK: id                   │
│ Name                     │     │1  *│ FK: CategoryId           │
│ Image                    │     │    │ CategoryName (denorm)    │
│ IsFeatured               │     │    │ Name                     │
│ IsActive                 │     │    │ Image                    │
│ CreatedAt                │     │    │ IsFeatured               │
│ UpdatedAt                │     │    │ IsActive                 │
└──────────┬───────────────┘     │    │ CreatedAt                │
           │                     │    │ UpdatedAt                │
           │                     │    └──────────────────────────┘
           │                     │
           │                     │
           │ *                   │
           │                     │
           │                     │
           ▼                     │
┌──────────────────────────┐    │
│   CategoryBrand          │    │
│   (Many-to-Many)         │    │
├──────────────────────────┤    │
│ FK: CategoryId           │────┘
│ FK: BrandId              │───────────┐
└──────────────────────────┘           │
                                       │
                                       │
                                       ▼
┌──────────────────────────┐    ┌──────────────────────────┐
│       Brands             │    │       Products           │
├──────────────────────────┤    ├──────────────────────────┤
│ PK: id                   │───►│ PK: id                   │
│ Name                     │1  *│ Name                     │
│ Image                    │    │ FormulaName              │
│ CategoryIds[]            │    │ Description              │
│ IsFeatured               │    │ Price                    │
│ IsActive                 │    │ SalePrice                │
│ ProductCount             │    │ Stock                    │
│ CreatedAt                │    │ Images[]                 │
│ UpdatedAt                │    │ FK: CategoryId           │
└──────────────────────────┘    │ CategoryName (denorm)    │
                                │ FK: SubcategoryId        │
                                │ SubcategoryName (denorm) │
                                │ FK: BrandId              │
                                │ BrandName (denorm)       │
                                │ IsFeatured               │──────┐
                                │ IsRecommended            │      │
                                │ IsActive                 │      │
                                │ CreatedAt                │      │
                                │ UpdatedAt                │      │
                                └──────────┬───────────────┘      │
                                           │                      │
                                           │1                     │
                                           │                      │
                                           │*                     │
                                           │                      │
                                           ▼                      │
                                ┌──────────────────────────┐      │
                                │   Reviews                │      │
                                │   (Subcollection)        │      │
                                ├──────────────────────────┤      │
                                │ PK: id                   │      │
                                │ FK: productId            │      │
                                │ FK: userId               │      │
                                │ userName                 │      │
                                │ rating (1-5)             │      │
                                │ comment                  │      │
                                │ CreatedAt                │      │
                                └──────────────────────────┘      │
                                                                  │
                                                                  │
┌──────────────────────────┐          ┌──────────────────────────┐ │
│       Orders             │          │     OrderItems           │ │
├──────────────────────────┤          │     (Embedded)           │ │
│ PK: id                   │─────┬───►├──────────────────────────┤ │
│ FK: customerId (Users)   │     │1  *│ FK: productId            │─┘
│ customerName             │     │    │ productName              │
│ customerEmail            │     │    │ price                    │
│ items[] (OrderItems)     │─────┘    │ quantity                 │
│ orderStatus              │          └──────────────────────────┘
│ paymentStatus            │
│ paymentMethod            │
│ totalAmount              │
│ subtotal                 │
│ couponCode               │
│ couponDiscount           │
│ shippingFee              │
│ shippingAddress{}        │
│ CreatedAt                │
└──────────────────────────┘


┌──────────────────────────┐
│       Banners            │
├──────────────────────────┤
│ PK: id                   │
│ image                    │
│ title                    │
│ description              │
│ redirect                 │
│ isActive                 │
│ isFeatured               │
│ views                    │
│ clicks                   │
│ startDate                │
│ endDate                  │
│ CreatedAt                │
│ UpdatedAt                │
└──────────────────────────┘


┌──────────────────────────┐
│       Coupons            │
├──────────────────────────┤
│ PK: id                   │
│ Code                     │
│ DiscountValue            │
│ Type (FLAT/PERCENTAGE)   │
│ Description              │
│ IsActive                 │
│ StartDate                │
│ EndDate                  │
│ UsageLimit               │
│ CreatedAt                │
│ UpdatedAt                │
└──────────────────────────┘


┌──────────────────────────┐
│       Admins             │
│   (Separate Collection)  │
├──────────────────────────┤
│ PK: id (uid)             │
│ FirstName                │
│ LastName                 │
│ Email                    │
│ PhoneNumber              │
│ ProfilePicture           │
│ role                     │
│ IsActive                 │
│ CreatedAt                │
└──────────────────────────┘


KEY RELATIONSHIPS:
------------------

1. Users (1) → Orders (*)
   - One user can have multiple orders
   - customerId in Orders references Users.id

2. Users (1) → Cart (*) [Subcollection]
   - Each user has their own Cart subcollection
   - Path: Users/{uid}/Cart

3. Users (1) → Wishlist (*) [Subcollection]
   - Each user has their own Wishlist subcollection
   - Path: Users/{uid}/Wishlist

4. Users (1) → medicines (*) [Subcollection]
   - Each user has their own medicines subcollection
   - Path: Users/{uid}/medicines
   - Synced with SQLite

5. medicines (1) → alarms (*) [Subcollection]
   - Each medicine can have multiple alarms
   - Path: Users/{uid}/medicines/{medId}/alarms
   - Synced with SQLite

6. Categories (1) → Subcategories (*)
   - One category has multiple subcategories
   - CategoryId in Subcategories references Categories.id

7. Categories (*) → Brands (*) [Many-to-Many]
   - Brands can belong to multiple categories
   - Categories can have multiple brands
   - Stored as CategoryIds[] array in Brands

8. Brands (1) → Products (*)
   - One brand has multiple products
   - BrandId in Products references Brands.id

9. Categories (1) → Products (*)
   - One category has multiple products
   - CategoryId in Products references Categories.id

10. Subcategories (1) → Products (*)
    - One subcategory has multiple products
    - SubcategoryId in Products references Subcategories.id

11. Products (1) → Reviews (*) [Subcollection]
    - Each product has its own Reviews subcollection
    - Path: Products/{productId}/Reviews

12. Products (1) → OrderItems (*)
    - One product can appear in multiple order items
    - productId in OrderItems references Products.id

13. Orders (1) → OrderItems (*) [Embedded]
    - Each order contains multiple items
    - OrderItems are embedded in Orders.items[] array


DENORMALIZED DATA (for Performance):
-------------------------------------

To avoid joins and improve query performance, the following data is denormalized:

1. Products store: CategoryName, SubcategoryName, BrandName
   - Prevents need to join Categories/Subcategories/Brands tables
   - Trade-off: Must update products when parent names change

2. Orders store: customerName, customerEmail
   - Quick display without joining Users table

3. Reviews store: userName
   - Display reviews without joining Users table


SYNC MECHANISM (SQLite ↔ Firebase):
------------------------------------

The medicines and alarms tables exist in BOTH SQLite (local) and Firestore (cloud):

SQLITE (Primary for Medicines):
- Used for offline-first functionality
- Critical for medicine reminders (works offline)
- Syncs to Firebase when online

FIREBASE (Backup for Medicines):
- Cloud backup of medicine data
- Syncs across multiple devices
- Path: Users/{uid}/medicines and Users/{uid}/medicines/{medId}/alarms

SYNC FLOW:
1. User adds/edits medicine → Saved to SQLite first
2. Operation queued in pending_changes table
3. When online, SyncService pushes to Firebase
4. On other devices, data pulled from Firebase to SQLite
5. Conflict resolution uses local_updated_at timestamp


═══════════════════════════════════════════════════════════════════════════════
AI PROMPT TO RECREATE ERD DIAGRAM:
═══════════════════════════════════════════════════════════════════════════════

Create a comprehensive Entity Relationship Diagram (ERD) for MediAI, a healthcare e-commerce platform with medicine reminder system. The database uses both Firebase Firestore and SQLite. Include:

**DATABASE SYSTEMS (2 separate sections):**

1. **FIREBASE FIRESTORE** (Cloud Database)
2. **SQLITE** (Local Mobile Database)

**ENTITIES IN FIREBASE FIRESTORE:**

**User Management:**
- **Users**: id (PK), FirstName, LastName, Email, PhoneNumber, Gender, DateOfBirth, ProfilePicture, role, points, orderCount, isEmailVerified, addresses[], selectedAddressIndex, shippingAddress{}, CreatedAt
  - **Cart** (Subcollection): cartItemId (PK), uid (FK→Users), productId (FK→Products), quantity, price, CreatedAt
  - **Wishlist** (Subcollection): wishlistId (PK), uid (FK→Users), productId (FK→Products), CreatedAt
  - **Notifications** (Subcollection): notificationId (PK), uid (FK→Users), title, message, type, isRead, CreatedAt
  - **medicines** (Subcollection): medId (PK), uid (FK→Users), medicine_name, disease_name, frequency, duration, start_date, chronic, total_no_of_doses, available_stock, alert_before_days, synced, local_updated_at, updatedAt, CreatedAt
    - **alarms** (Sub-subcollection): alarmId (PK), uid (FK→Users), medId (FK→medicines), specific_dose, time_hour, time_minute, duration, isActive, synced, local_updated_at, updatedAt, CreatedAt

**Product Catalog:**
- **Categories**: id (PK), Name, Image, IsFeatured, IsActive, CreatedAt, UpdatedAt
- **Subcategories**: id (PK), CategoryId (FK→Categories), CategoryName (denormalized), Name, Image, IsFeatured, IsActive, CreatedAt, UpdatedAt
- **Brands**: id (PK), Name, Image, CategoryIds[] (many-to-many), IsFeatured, IsActive, ProductCount, CreatedAt, UpdatedAt
- **Products**: id (PK), Name, FormulaName, Description, Price, SalePrice, Stock, Images[], CategoryId (FK→Categories), CategoryName (denormalized), SubcategoryId (FK→Subcategories), SubcategoryName (denormalized), BrandId (FK→Brands), BrandName (denormalized), IsFeatured, IsRecommended, IsActive, CreatedAt, UpdatedAt
  - **Reviews** (Subcollection): id (PK), productId (FK→Products), userId (FK→Users), userName (denormalized), rating (1-5), comment, CreatedAt

**Orders:**
- **Orders**: id (PK), customerId (FK→Users), customerName (denormalized), customerEmail (denormalized), items[] (embedded OrderItems), orderStatus (Pending/Processing/Shipped/Delivered), paymentStatus (Unpaid/Paid), paymentMethod, totalAmount, subtotal, couponCode, couponDiscount, shippingFee, shippingAddress{}, CreatedAt
  - **OrderItems** (Embedded array): productId (FK→Products), productName, price, quantity

**Promotions:**
- **Banners**: id (PK), image, title, description, redirect, isActive, isFeatured, views, clicks, startDate, endDate, CreatedAt, UpdatedAt
- **Coupons**: id (PK), Code, DiscountValue, Type (FLAT/PERCENTAGE), Description, IsActive, StartDate, EndDate, UsageLimit, CreatedAt, UpdatedAt

**Admin:**
- **Admins**: id (PK), FirstName, LastName, Email, PhoneNumber, ProfilePicture, role, IsActive, CreatedAt


**ENTITIES IN SQLITE (Local Database):**

- **medicines**: medId (PK), uid, medicine_name, disease_name, frequency, duration, start_date, chronic, total_no_of_doses, available_stock, alert_before_days, synced, local_updated_at
- **alarms**: alarmId (PK), uid, medId (FK→medicines), specific_dose, time_hour, time_minute, duration, isActive, synced, local_updated_at
- **pending_changes**: id (PK), operation_type (INSERT/UPDATE/DELETE), entity_type (MEDICINE/ALARM), entity_id, entity_data (JSON), timestamp, synced


**RELATIONSHIPS TO SHOW:**

1. Users 1→* Orders (customerId)
2. Users 1→* Cart (subcollection)
3. Users 1→* Wishlist (subcollection)
4. Users 1→* Notifications (subcollection)
5. Users 1→* medicines (subcollection)
6. medicines 1→* alarms (sub-subcollection)
7. Categories 1→* Subcategories (CategoryId)
8. Categories *→* Brands (many-to-many via CategoryIds[])
9. Brands 1→* Products (BrandId)
10. Categories 1→* Products (CategoryId)
11. Subcategories 1→* Products (SubcategoryId)
12. Products 1→* Reviews (subcollection)
13. Products 1→* OrderItems (productId)
14. Orders 1→* OrderItems (embedded array)
15. SQLite medicines ↔ Firebase medicines (bidirectional sync with double arrow)
16. SQLite alarms ↔ Firebase alarms (bidirectional sync with double arrow)

**SPECIAL NOTATIONS:**

- Mark Primary Keys (PK)
- Mark Foreign Keys (FK)
- Mark denormalized fields with "(denorm)" note
- Mark subcollections with "(Subcollection)" label
- Mark embedded arrays with "(Embedded)" label
- Show sync arrows between SQLite and Firebase medicines/alarms
- Use crow's foot notation for cardinality (1, *, 1..*, etc.)

**VISUAL REQUIREMENTS:**

- Group Firebase entities in one large box/section
- Group SQLite entities in a separate box/section
- Use different colors: Firebase entities (blue), SQLite entities (green), Admin entities (orange)
- Use rectangles for entities
- Show attributes inside entity boxes
- Draw relationship lines with cardinality notation
- Show sync arrows (double arrows) between SQLite and Firebase
- Make it clear, professional, and suitable for a presentation
- Use standard ERD notation (Chen or Crow's Foot)


═══════════════════════════════════════════════════════════════════════════════
8. TECHNOLOGY STACK
═══════════════════════════════════════════════════════════════════════════════

MOBILE APP (MediAI):
--------------------
• Framework: Flutter 3.x (Dart)
• State Management: GetX
• Local Database: SQLite (sqflite package)
• Key-Value Storage: GetStorage
• Backend: Firebase
  - Authentication (Email, Google, Facebook)
  - Firestore (NoSQL Database)
  - Storage (Images)
  - Cloud Messaging (Notifications)
• Notifications: flutter_local_notifications
• Background Tasks: workmanager
• Time Zone: timezone package (Asia/Karachi)
• Connectivity: connectivity_plus
• Image Picker: image_picker
• OCR: (For prescription scanning)
• UI: Material Design 3

WEB ADMIN PANEL (MediAdmin):
-----------------------------
• Framework: Flutter Web
• State Management: GetX
• Backend: Firebase
  - Firestore
  - Authentication
  - Storage
• UI: Custom admin theme
• Charts: (For dashboard analytics)
• Export: excel package

BACKEND (Firebase):
-------------------
• Authentication: Firebase Auth
• Database: Cloud Firestore
• File Storage: Firebase Storage
• Cloud Functions: (If needed for backend logic)
• Hosting: Firebase Hosting (for admin panel)

DEVELOPMENT TOOLS:
------------------
• IDE: Visual Studio Code / Android Studio
• Version Control: Git
• Package Manager: pub (Flutter)
• Build System: Flutter build tools


═══════════════════════════════════════════════════════════════════════════════
9. KEY FEATURES SUMMARY
═══════════════════════════════════════════════════════════════════════════════

MOBILE APP (Customer Features):
--------------------------------
✅ E-Commerce Store
   • Browse medicines by category, brand, subcategory
   • Search and filter products
   • View product details with images and reviews
   • Shopping cart with quantity controls
   • Wishlist for saving products
   • Checkout with address selection and coupon codes
   • Order tracking and history
   • Product reviews and ratings

✅ Medicine Reminder System
   • Add medicines manually or via OCR prescription scan
   • Set multiple alarms per medicine
   • Full-screen alarm notifications
   • Snooze and dismiss functionality
   • Automatic stock decrement on medicine intake
   • Support for chronic and non-chronic medicines

✅ Stock Management
   • Real-time stock level monitoring
   • Color-coded stock status (out of stock, low stock, normal)
   • Configurable low stock alerts (alert_before_days)
   • Background stock checking
   • Merge medicines with same name for clarity
   • Manual stock updates

✅ Offline-First Architecture
   • SQLite for local medicine data
   • Works completely offline for critical health features
   • Automatic sync when connection restored
   • Offline operation queue with retry logic
   • Conflict resolution with timestamps

✅ AI Chatbot
   • Health consultation
   • Medicine recommendations
   • Symptom analysis

✅ User Profile
   • Personal information management
   • Multiple shipping addresses
   • Order history
   • Points and loyalty tracking
   • Email verification

✅ Notifications
   • Medicine reminders with full-screen alerts
   • Low stock warnings
   • Out of stock alerts
   • Order status updates


ADMIN PANEL (Administrator Features):
--------------------------------------
✅ Dashboard
   • Real-time sales metrics
   • Order status charts
   • Low stock alerts
   • Recent orders overview
   • Export to Excel

✅ Product Management
   • Create, edit, delete products
   • Stock level management with color coding
   • Price and sale price settings
   • Multiple image uploads
   • Featured and recommended product flags
   • Triple filter system (search, category, brand)

✅ Catalog Management
   • Categories with featured flags
   • Subcategories with parent linking
   • Brands with multi-category support
   • Active/Inactive toggles

✅ Order Processing
   • View all customer orders
   • Update order status (Pending → Processing → Shipped → Delivered)
   • Update payment status
   • Auto-payment on COD delivery
   • Order search and filtering

✅ Customer Management
   • View customer profiles
   • Order history per customer
   • Points and loyalty tracking
   • Delete customer accounts

✅ Promotions
   • Banner management with redirect targets
   • Date range and visibility controls
   • View and click tracking
   • Coupon creation with FLAT or PERCENTAGE discounts
   • Usage limits and expiry dates

✅ Admin Management
   • Create admin accounts (without logout)
   • Role assignment (Admin, Super Admin, Manager, Staff)
   • Active/Inactive status
   • Auto-registration of current admin

✅ Security
   • Role-based access control
   • Firebase authentication
   • Firestore security rules
   • Admin-only panel access


BACKGROUND SERVICES:
--------------------
✅ Notification Service
   • Schedule local notifications
   • Full-screen alarm alerts
   • Custom alarm sounds
   • Background execution

✅ Sync Service
   • Push local changes to Firebase
   • Pull remote changes to SQLite
   • Conflict resolution
   • Bidirectional synchronization

✅ Connectivity Service
   • Network monitoring
   • Auto-trigger sync on connection
   • Offline mode detection

✅ Stock Alert Service
   • Periodic background checks
   • Smart stock calculation for chronic/non-chronic medicines
   • Configurable alert thresholds
   • Deduplication to avoid spam

✅ Offline Queue Service
   • Queue CRUD operations when offline
   • Automatic retry when online
   • Operation coalescing to prevent duplicates


═══════════════════════════════════════════════════════════════════════════════
                                  END OF DOCUMENTATION
═══════════════════════════════════════════════════════════════════════════════

For any questions or clarifications about this project, please refer to the actual
source code in the respective folders:
- MediAI/lib/ (Mobile App)
- MediAI/MediAdmin/lib/ (Admin Panel)

Last Updated: April 21, 2026
