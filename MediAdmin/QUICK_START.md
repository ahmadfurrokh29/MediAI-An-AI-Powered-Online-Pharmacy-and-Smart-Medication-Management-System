# 🔐 Quick Start - Firebase Authentication

## ⚡ 3-Step Setup (5 Minutes)

### Step 1: Enable Authentication (1 min)
1. Open [Firebase Console](https://console.firebase.google.com/project/medi-ai-6bcb2/authentication)
2. Click **Sign-in method** → **Email/Password** → **Enable** → **Save**

### Step 2: Create Admin User (2 min)

**A. Create in Authentication:**
- Go to **Authentication** → **Users** → **Add user**
- Email: `ibbihymes@gmail.com`
- Password: `Admin123!` (change this!)
- **Copy the UID** (looks like: `kQhL7xABqY...`)

**B. Create in Firestore:**
- Go to **Firestore Database** → **Start collection**
- Collection ID: `Users`
- Document ID: *[Paste UID from above]*
- Add fields:

```
Email: ibbihymes@gmail.com
FirstName: Ibrahim
LastName: farooq
Username: ibbi
PhoneNumber: 03325807144
ProfilePicture: (leave empty)
role: admin  ← IMPORTANT!
```

### Step 3: Deploy Security Rules (2 min)
- Go to **Firestore** → **Rules** tab
- Copy content from `firestore.rules` file
- Paste → **Publish**

## ✅ Done! Now Test:

```bash
flutter run -d chrome
```

Login with:
- Email: `ibbihymes@gmail.com`
- Password: `Admin123!` (or whatever you set)

---

## 🎯 That's It!

Your admin panel is now secure! Check `AUTHENTICATION_SUMMARY.md` for details.
