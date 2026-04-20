# MediAI — Backend Project Documentation

> **Project:** MediAI Admin Panel + Customer App  
> **Backend:** Firebase (Firestore + Firebase Auth + Firebase Storage)  
> **Admin App:** Flutter Web (`med_admin`)  
> **Customer App:** Flutter Mobile (`MediAI`)  
> **Firebase Project ID:** `medi-ai-6bcb2`  
> **Date:** March 2026

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Firebase Services Used](#2-firebase-services-used)
3. [Authentication](#3-authentication)
4. [Firestore Database — Collections & Schema](#4-firestore-database--collections--schema)
5. [Firebase Storage](#5-firebase-storage)
6. [Security Rules](#6-security-rules)
7. [Data Models](#7-data-models)
8. [Controllers (Business Logic)](#8-controllers-business-logic)
9. [Admin Panel Features](#9-admin-panel-features)
10. [Dependencies](#10-dependencies)
11. [Known Setup Requirements](#11-known-setup-requirements)

---

## 1. Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│                   FIREBASE BACKEND                  │
│                                                     │
│  ┌─────────────┐  ┌──────────────┐  ┌───────────┐  │
│  │  Firestore  │  │ Firebase Auth│  │  Storage  │  │
│  │  (Database) │  │ (Users/Auth) │  │ (Images)  │  │
│  └─────────────┘  └──────────────┘  └───────────┘  │
└───────────────────────┬─────────────────────────────┘
                        │
          ┌─────────────┴──────────────┐
          │                            │
  ┌───────▼──────────┐      ┌──────────▼──────────┐
  │  Admin Panel     │      │   Customer App       │
  │  (Flutter Web)   │      │   (Flutter Mobile)   │
  │  med_admin       │      │   MediAI             │
  │                  │      │                      │
  │ - Manages all    │      │ - Browses products   │
  │   Firestore data │      │ - Places orders      │
  │ - Uploads images │      │ - Views banners      │
  │   to Storage     │      │ - Uses coupons       │
  └──────────────────┘      └──────────────────────┘
```

**State Management:** GetX (`get: ^4.7.3`) used in both apps for controllers, routing, and reactive state.

---

## 2. Firebase Services Used

| Service            | Purpose                                                  | Status         |
|--------------------|----------------------------------------------------------|----------------|
| Firebase Auth      | Admin login / customer registration & login              | ✅ Active       |
| Cloud Firestore    | All structured data (products, orders, banners, etc.)    | ✅ Active       |
| Firebase Storage   | Image uploads (banners, products, categories, brands)    | ⚠️ Must enable at console.firebase.google.com/project/medi-ai-6bcb2/storage |

### Firebase Configuration Files
| App          | Config File                              |
|--------------|------------------------------------------|
| Admin (Web)  | `MediAdmin/lib/firebase_options.dart`    |
| Customer     | `lib/firebase_options.dart`              |
| Android      | `android/app/google-services.json`       |

---

## 3. Authentication

### Service: `AuthService` (Admin App)
**File:** `MediAdmin/lib/features/auth/services/auth_service.dart`

| Method                         | Description                                       |
|--------------------------------|---------------------------------------------------|
| `loginWithEmailAndPassword()`  | Signs in admin using Firebase Auth email/password |
| `getUserDetails(uid)`          | Fetches user document from `Users` collection     |
| `signOut()`                    | Signs out current user                            |
| `isUserAdmin(uid)`             | Checks `role` field in `Users` collection         |
| `authStateChanges`             | Stream of auth state for reactive UI              |

### Controller: `AuthController`
**File:** `MediAdmin/lib/features/auth/controllers/auth_controller.dart`

- Listens to `authStateChanges` stream
- On login: fetches user details → checks `role == 'admin'`
- Redirects to `/admin` if admin role confirmed, else signs out
- Uses `Get.offAllNamed()` for navigation

### Admin Role Check Logic
```
User logs in → Firebase Auth → fetch Users/{uid} → check role field
  ├── role == 'admin'  →  Navigate to Admin Dashboard ✅
  └── role != 'admin'  →  Sign out + show "Access Denied" ❌
```

### User Model Fields (stored in `Users` collection)
| Field            | Type   | Notes                           |
|------------------|--------|---------------------------------|
| `FirstName`      | String |                                 |
| `LastName`       | String |                                 |
| `Email`          | String |                                 |
| `Username`       | String | lowercase `firstname.lastname`  |
| `PhoneNumber`    | String |                                 |
| `ProfilePicture` | String | URL from Firebase Storage       |
| `role`           | String | `"admin"` or `"user"`           |

---

## 4. Firestore Database — Collections & Schema

### 4.1 `Banners`
**Purpose:** Promotional slider banners shown in the customer app home screen.

| Field        | Type      | Firestore Key  | Notes                          |
|--------------|-----------|----------------|--------------------------------|
| id           | String    | (document ID)  | Auto-generated                 |
| imageUrl     | String    | `image`        | Firebase Storage download URL  |
| title        | String    | `title`        |                                |
| description  | String    | `description`  |                                |
| redirect     | String    | `redirect`     | Deep-link or URL on tap        |
| isActive     | bool      | `isActive`     | Whether shown in app           |
| isFeatured   | bool      | `isFeatured`   |                                |
| views        | int       | `views`        |                                |
| clicks       | int       | `clicks`       |                                |
| startDate    | String    | `startDate`    | Format: `d/M/yyyy`             |
| endDate      | String    | `endDate`      | Format: `d/M/yyyy`             |
| createdAt    | Timestamp | `CreatedAt`    |                                |
| updatedAt    | Timestamp | `UpdatedAt`    |                                |

**Storage path for banner images:** `banners/{timestamp}_{filename}`

---

### 4.2 `Products`
**Purpose:** Medicine and health product catalogue.

| Field           | Type      | Firestore Key      | Notes                              |
|-----------------|-----------|--------------------|------------------------------------|
| id              | String    | (document ID)      | Auto-generated                     |
| name            | String    | `Name`             | Product/medicine name              |
| formulaName     | String    | `FormulaName`      | Generic/formula name               |
| description     | String    | `Description`      |                                    |
| price           | double    | `Price`            | Regular price                      |
| salePrice       | double    | `SalePrice`        | Discounted price (0 = no discount) |
| stock           | int       | `Stock`            |                                    |
| images          | List\<String\> | `Images`      | List of Firebase Storage URLs      |
| categoryId      | String    | `CategoryId`       | Reference to Categories doc        |
| categoryName    | String    | `CategoryName`     | Denormalized for display           |
| subcategoryId   | String    | `SubcategoryId`    |                                    |
| subcategoryName | String    | `SubcategoryName`  |                                    |
| brandId         | String    | `BrandId`          |                                    |
| brandName       | String    | `BrandName`        |                                    |
| isFeatured      | bool      | `IsFeatured`       | Shown in popular/featured section  |
| isRecommended   | bool      | `IsRecommended`    | Shown in recommended per category  |
| isActive        | bool      | `IsActive`         |                                    |
| createdAt       | Timestamp | `CreatedAt`        |                                    |
| updatedAt       | Timestamp | `UpdatedAt`        |                                    |

---

### 4.3 `Categories`
**Purpose:** Top-level product categories (e.g., Medicine, Vitamins, Equipment).

| Field     | Type      | Firestore Key | Notes                         |
|-----------|-----------|---------------|-------------------------------|
| id        | String    | (document ID) |                               |
| name      | String    | `Name`        |                               |
| image     | String    | `Image`       | Firebase Storage URL          |
| isFeatured| bool      | `IsFeatured`  | Shown in home categories row  |
| isActive  | bool      | `IsActive`    |                               |
| createdAt | Timestamp | `CreatedAt`   |                               |
| updatedAt | Timestamp | `UpdatedAt`   |                               |

---

### 4.4 `Subcategories`
**Purpose:** Sub-level product categories nested under Categories.

| Field       | Type      | Firestore Key  | Notes                   |
|-------------|-----------|----------------|-------------------------|
| id          | String    | (document ID)  |                         |
| name        | String    | `Name`         |                         |
| image       | String    | `Image`        | Firebase Storage URL    |
| categoryId  | String    | `CategoryId`   | Parent category ref     |
| isActive    | bool      | `IsActive`     |                         |
| createdAt   | Timestamp | `CreatedAt`    |                         |
| updatedAt   | Timestamp | `UpdatedAt`    |                         |

---

### 4.5 `Brands`
**Purpose:** Pharmaceutical/product brand information.

| Field        | Type           | Firestore Key  | Notes                        |
|--------------|----------------|----------------|------------------------------|
| id           | String         | (document ID)  |                              |
| name         | String         | `Name`         |                              |
| image        | String         | `Image`        | Firebase Storage URL         |
| categoryIds  | List\<String\> | `CategoryIds`  | Brands can span categories   |
| isFeatured   | bool           | `IsFeatured`   |                              |
| isActive     | bool           | `IsActive`     |                              |
| productCount | int            | `ProductCount` | Denormalized count           |
| createdAt    | Timestamp      | `CreatedAt`    |                              |
| updatedAt    | Timestamp      | `UpdatedAt`    |                              |

---

### 4.6 `Orders`
**Purpose:** Customer purchase orders.

| Field           | Type                   | Firestore Key     | Notes                             |
|-----------------|------------------------|-------------------|-----------------------------------|
| id              | String                 | (document ID)     |                                   |
| customerId      | String                 | `customerId`      | Firebase Auth UID                 |
| customerName    | String                 | `customerName`    |                                   |
| customerEmail   | String                 | `customerEmail`   |                                   |
| items           | List\<Map\>            | `items`           | See `OrderItemModel` below        |
| orderStatus     | String                 | `orderStatus`     | `pending`, `processing`, `shipped`, `delivered`, `cancelled` |
| paymentStatus   | String                 | `paymentStatus`   | `pending`, `paid`, `failed`       |
| totalAmount     | double                 | `totalAmount`     |                                   |
| subtotal        | double                 | `subtotal`        |                                   |
| couponCode      | String                 | `couponCode`      |                                   |
| couponDiscount  | double                 | `couponDiscount`  |                                   |
| shippingFee     | double                 | `shippingFee`     |                                   |
| shippingAddress | Map\<String, dynamic\> | `shippingAddress` |                                   |
| createdAt       | Timestamp              | `createdAt`       |                                   |

**Order Item sub-document fields:**
| Field       | Type   | Key           |
|-------------|--------|---------------|
| productId   | String | `productId`   |
| productName | String | `productName` |
| price       | double | `price`       |
| quantity    | int    | `quantity`    |

**Order Status Flow:**
```
pending → processing → shipped → delivered
                               ↘ cancelled
```

---

### 4.7 `Coupons`
**Purpose:** Discount coupons redeemable at checkout.

Managed via `MediAdmin/lib/features/coupons/pages/` (create, update, list pages).

| Typical Fields | Type   | Notes                                      |
|----------------|--------|--------------------------------------------|
| code           | String | Coupon code (unique)                       |
| discountType   | String | `percentage` or `fixed`                    |
| discountValue  | double | Percentage or fixed amount                 |
| minOrderAmount | double | Minimum cart value to apply                |
| maxUses        | int    | Maximum redemption count                   |
| usedCount      | int    | Times redeemed so far                      |
| isActive       | bool   |                                            |
| expiryDate     | String | Expiry date                                |
| createdAt      | Timestamp |                                         |

---

### 4.8 `Admins`
**Purpose:** Admin user profiles (separate from the `Users` collection).

| Field          | Type      | Firestore Key    | Notes                        |
|----------------|-----------|------------------|------------------------------|
| id             | String    | (document ID)    | = Firebase Auth UID          |
| firstName      | String    | `FirstName`      |                              |
| lastName       | String    | `LastName`       |                              |
| email          | String    | `Email`          |                              |
| phoneNumber    | String    | `PhoneNumber`    |                              |
| profilePicture | String    | `ProfilePicture` | Firebase Storage URL         |
| role           | String    | `role`           | Always `"admin"`             |
| isActive       | bool      | `IsActive`       |                              |
| createdAt      | Timestamp | `CreatedAt`      |                              |

> **Note:** When an admin is created, a mirrored document is also written to `Users/{uid}` so the auth role-check can find it.

---

### 4.9 `Users`
**Purpose:** All app users (customers + admins). The auth controller reads this to check `role`.

| Field          | Type   | Firestore Key    |
|----------------|--------|------------------|
| id             | String | (document ID)    |
| firstName      | String | `FirstName`      |
| lastName       | String | `LastName`       |
| email          | String | `Email`          |
| username       | String | `Username`       |
| phoneNumber    | String | `PhoneNumber`    |
| profilePicture | String | `ProfilePicture` |
| role           | String | `role`           |

---

### 4.10 `Customers` (Customer profiles)
**Purpose:** Enriched customer data including order count and loyalty points.

| Field           | Type                   | Notes                     |
|-----------------|------------------------|---------------------------|
| id              | String                 | = Firebase Auth UID       |
| firstName       | String                 |                           |
| lastName        | String                 |                           |
| email           | String                 |                           |
| phoneNumber     | String                 |                           |
| points          | int                    | Loyalty points            |
| orderCount      | int                    | Total orders placed       |
| shippingAddress | Map\<String, dynamic\> | Default shipping address  |
| createdAt       | Timestamp              |                           |
| isEmailVerified | bool                   |                           |

---

## 5. Firebase Storage

### Storage Bucket
```
medi-ai-6bcb2.firebasestorage.app
```

### ⚠️ Setup Required
Firebase Storage must be **manually enabled** in the Firebase Console before any image upload will work:
1. Go to: https://console.firebase.google.com/project/medi-ai-6bcb2/storage
2. Click **"Get Started"**
3. Choose region (recommended: `us-central1`)
4. Set rules to Production mode (rules file below handles permissions)
5. After enabling, deploy rules: `firebase deploy --only storage --project medi-ai-6bcb2`

### Storage Folder Structure
| Path                                  | Content                  |
|---------------------------------------|--------------------------|
| `banners/{timestamp}_{filename}`      | Banner images            |
| `categories/{timestamp}_{filename}`   | Category images          |
| `subcategories/{timestamp}_{filename}`| Subcategory images       |
| `brands/{timestamp}_{filename}`       | Brand logos              |
| `products/{timestamp}_{filename}`     | Product images           |
| `admins/{timestamp}_{filename}`       | Admin profile pictures   |

### Storage Rules File
**File:** `MediAdmin/storage.rules`
```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read: if true;                    // Public reads (app can display images)
      allow write: if request.auth != null;   // Only authenticated users can upload
    }
  }
}
```

### Image Upload Implementation (Admin Panel — Banner)
**Tech:** `dart:html` `FileUploadInputElement` → `FileReader.readAsDataUrl()` → `base64Decode()` → `FirebaseStorage.putData()`

**Flow:**
```
User clicks "Browse file"
  → html.FileUploadInputElement triggers native browser file picker
  → Filter: image/png, image/jpeg, image/jpg only
  → FileReader.readAsDataUrl() converts file to base64 data URL
  → base64Decode() converts to Uint8List bytes
  → setState() shows preview immediately via Image.memory(bytes)
  → ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'))
  → ref.getDownloadURL() → stored in _uploadedImageUrl
  → On form submit: imageUrl saved to Firestore Banner document
```

**Files:**
- `MediAdmin/lib/features/banners/pages/create_banner_page.dart`
- `MediAdmin/lib/features/banners/pages/update_banner_page.dart`

---

## 6. Security Rules

### Firestore Rules
**File:** `MediAdmin/firestore.rules`

| Collection      | Read            | Write                  |
|-----------------|-----------------|------------------------|
| `Users`         | Authenticated   | Authenticated          |
| `Categories`    | Public          | Authenticated          |
| `Subcategories` | Public          | Authenticated          |
| `Brands`        | Public          | Authenticated          |
| `Products`      | Public          | Authenticated          |
| `Orders`        | Authenticated   | Authenticated          |
| `Banners`       | Public          | Authenticated          |
| `Coupons`       | Authenticated   | Authenticated          |
| `Admins`        | Authenticated   | Authenticated          |
| `Customers`     | Authenticated   | Authenticated          |

### Deploy Commands
```bash
# Deploy Firestore rules
firebase deploy --only firestore:rules --project medi-ai-6bcb2

# Deploy Storage rules (after enabling Storage in console)
firebase deploy --only storage --project medi-ai-6bcb2

# Deploy both
firebase deploy --only firestore:rules,storage --project medi-ai-6bcb2
```

---

## 7. Data Models

### Summary Table

| Model          | File Path                                              | Firestore Collection |
|----------------|--------------------------------------------------------|----------------------|
| `BannerModel`  | `features/banners/models/banner_model.dart`            | `Banners`            |
| `ProductModel` | `features/products/models/product_model.dart`          | `Products`           |
| `CategoryModel`| `features/categories/models/category_model.dart`       | `Categories`         |
| `BrandModel`   | `features/brands/models/brand_model.dart`              | `Brands`             |
| `OrderModel`   | `features/orders/models/order_model.dart`              | `Orders`             |
| `AdminModel`   | `features/admins/models/admin_model.dart`              | `Admins`             |
| `CustomerModel`| `features/customers/models/customer_model.dart`        | `Customers`          |
| `UserModel`    | `features/auth/models/user_model.dart`                 | `Users`              |

> All models implement:
> - `toJson()` — Converts to Firestore map (for create/update)
> - `fromSnapshot()` — Parses Firestore `DocumentSnapshot`
> - `copyWith()` — Immutable update helper
> - `empty()` — Returns a blank default instance

---

## 8. Controllers (Business Logic)

All controllers use **GetX** and follow the pattern:
```dart
class XController extends GetxController {
  static XController get instance => Get.find();
  // ...
}
```

| Controller          | File                                                     | Responsibilities                                   |
|---------------------|----------------------------------------------------------|----------------------------------------------------|
| `AuthController`    | `features/auth/controllers/auth_controller.dart`         | Login, logout, role check, auth state stream        |
| `BannerController`  | `features/banners/controllers/banner_controller.dart`    | Fetch, create, update, delete, toggle active banners|
| `ProductController` | `features/products/controllers/product_controller.dart`  | Fetch, create, update, delete products              |
| `CategoryController`| `features/categories/controllers/category_controller.dart`| CRUD for categories                               |
| `OrderController`   | `features/orders/controllers/order_controller.dart`      | Fetch orders, update order/payment status           |
| `DashboardController`| `features/dashboard/controllers/`                       | Aggregated stats for dashboard overview             |

### BannerController Operations
| Method              | Firestore Action                                     |
|---------------------|------------------------------------------------------|
| `fetchBanners()`    | `collection('Banners').orderBy('CreatedAt', desc)`   |
| `createBanner()`    | `collection('Banners').add(banner.toJson())`         |
| `updateBanner()`    | `collection('Banners').doc(id).update(...)`          |
| `deleteBanner()`    | `collection('Banners').doc(id).delete()`             |
| `toggleActive()`    | `updateBanner(banner.copyWith(isActive: !isActive))` |

### OrderController Operations
| Method              | Firestore Action                                         |
|---------------------|----------------------------------------------------------|
| `fetchOrders()`     | `collection('Orders').orderBy('createdAt', desc)`        |
| `updateStatus()`    | `doc(id).update({orderStatus: newStatus})`               |
| `updatePayment()`   | `doc(id).update({paymentStatus: newStatus})`             |

---

## 9. Admin Panel Features

| Feature              | Route / Page                              | Backend Collection     |
|----------------------|-------------------------------------------|------------------------|
| Dashboard            | `/admin` → `dashboard_page.dart`          | All collections (stats)|
| Categories           | `categories/pages/`                       | `Categories`           |
| Subcategories        | `subcategories/pages/`                    | `Subcategories`        |
| Brands               | `brands/pages/`                           | `Brands`               |
| Products             | `products/pages/`                         | `Products`             |
| Recommended Products | `products/recommended_products_page.dart` | `Products`             |
| Orders               | `orders/orders_page.dart`                 | `Orders`               |
| Banners              | `banners/pages/`                          | `Banners` + Storage    |
| Coupons              | `coupons/pages/`                          | `Coupons`              |
| Customers            | `customers/pages/`                        | `Customers`            |
| Admins               | `admins/pages/`                           | `Admins` + `Users`     |

### Banner Image Upload UI
- **Container:** `AspectRatio(16/9)` — matches promo slider ratio in customer app
- **Accepted formats:** PNG, JPG, JPEG only
- **Empty state:** "Click to upload banner image" + "Browse file" button
- **Uploading state:** CircularProgressIndicator spinner
- **Preview state:** `Image.memory(bytes)` shown immediately after file selection
- **Uploaded state:** Green "Uploaded ✓" badge + filename overlay

---

## 10. Dependencies

### Admin App (`MediAdmin/pubspec.yaml`)

| Package              | Version    | Purpose                                    |
|----------------------|------------|--------------------------------------------|
| `get`                | ^4.7.3     | State management, routing, DI              |
| `firebase_core`      | ^3.8.1     | Firebase initialization                    |
| `firebase_auth`      | ^5.3.4     | Authentication                             |
| `cloud_firestore`    | ^5.6.0     | Database reads/writes                      |
| `firebase_storage`   | ^12.4.1    | Image file uploads                         |
| `image_picker`       | ^1.2.1     | (Legacy — superseded by dart:html on web)  |
| `file_picker`        | ^10.3.10   | (Added — superseded by dart:html on web)   |
| `fl_chart`           | ^1.1.1     | Dashboard charts                           |
| `flutter_quill`      | ^11.5.0    | Rich-text product descriptions             |
| `intl`               | ^0.20.2    | Date/number formatting                     |
| `excel`              | ^4.0.6     | Export data to Excel                       |
| `universal_html`     | ^2.3.0     | Cross-platform HTML utilities              |

> **Note on image picking on Flutter Web:** Neither `image_picker` nor `file_picker` reliably opens the file dialog on Flutter Web. The solution is to use `dart:html`'s `FileUploadInputElement` directly, appended to `document.body`, with `onChange` listener and `FileReader.readAsDataUrl()` for bytes conversion.

---

## 11. Known Setup Requirements

### ✅ Done
- Firebase Auth — enabled, email/password sign-in working
- Cloud Firestore — enabled, rules deployed
- Admin Panel — running on Flutter Web (Chrome/Edge)
- All CRUD operations for: Categories, Subcategories, Brands, Products, Orders, Banners, Coupons, Admins, Customers

### ⚠️ Action Required
1. **Enable Firebase Storage** in the Firebase Console:
   - URL: https://console.firebase.google.com/project/medi-ai-6bcb2/storage
   - Click **"Get Started"** → choose region → Done

2. **Deploy Storage Rules** after enabling:
   ```bash
   cd MediAdmin
   firebase deploy --only storage --project medi-ai-6bcb2
   ```

3. **Hot Restart** the admin app after deploying rules to pick up the new Storage configuration.

---

## Firestore Field Name Conventions

> ⚠️ The codebase uses **mixed casing** across collections — be careful when reading/writing:

| Collection   | Casing Style          | Example              |
|--------------|-----------------------|----------------------|
| `Banners`    | camelCase             | `image`, `isActive`  |
| `Products`   | PascalCase            | `Name`, `IsFeatured` |
| `Categories` | PascalCase            | `Name`, `Image`      |
| `Orders`     | camelCase             | `customerId`, `items`|
| `Admins`     | PascalCase + `role`   | `FirstName`, `role`  |
| `Users`      | PascalCase + `role`   | `FirstName`, `role`  |

All `fromSnapshot()` factories handle both casings with fallback (`data['name'] ?? data['Name'] ?? ''`).

---

*This document was generated on March 20, 2026 and reflects the current state of the MediAI backend implementation.*
