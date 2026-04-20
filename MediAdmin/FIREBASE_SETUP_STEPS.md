# Firebase Setup Instructions

## Step 1: Enable Email/Password Authentication

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **medi-ai-6bcb2**
3. Click on **Authentication** in the left sidebar
4. Go to **Sign-in method** tab
5. Click on **Email/Password**
6. Toggle **Enable**
7. Click **Save**

## Step 2: Create Your First Admin User

### Using Firebase Console:

1. **Create Authentication User:**
   - Go to **Authentication** → **Users** tab
   - Click **Add user**
   - Email: `ibbihymes@gmail.com`
   - Password: `YourSecurePassword123!` (choose a strong password)
   - Click **Add user**
   - **Copy the User UID** (you'll need this)

2. **Create Firestore User Document:**
   - Go to **Firestore Database**
   - Click **Start collection**
   - Collection ID: `Users`
   - Click **Next**
   - Document ID: **Paste the User UID from step 1**
   - Add these fields:

   | Field | Type | Value |
   |-------|------|-------|
   | Email | string | ibbihymes@gmail.com |
   | FirstName | string | Ibrahim |
   | LastName | string | farooq |
   | Username | string | ibbi |
   | PhoneNumber | string | 03325807144 |
   | ProfilePicture | string | (leave empty) |
   | role | string | admin |

   - Click **Save**

## Step 3: Deploy Firestore Security Rules

### Option A: Using Firebase Console
1. Go to **Firestore Database** → **Rules** tab
2. Copy the content from `firestore.rules` file
3. Paste it into the rules editor
4. Click **Publish**

### Option B: Using Firebase CLI
```bash
# Make sure you're in the project directory
cd c:\Users\HP\med\admin\MediAdmin

# Deploy rules
firebase deploy --only firestore:rules
```

## Step 4: Test Your Setup

1. Run your Flutter app:
   ```bash
   flutter run -d chrome
   ```

2. Try logging in with:
   - **Email**: ibbihymes@gmail.com
   - **Password**: (the password you set in Step 2)

3. You should be redirected to the admin panel!

## Step 5: Add More Admin Users (Optional)

Repeat Step 2 for each admin user you want to add. Make sure:
- ✅ User exists in **Authentication**
- ✅ User document exists in **Firestore** with same UID
- ✅ User document has `role: "admin"`

## Troubleshooting

### Can't login?
- Check if email/password authentication is enabled
- Verify the password is correct
- Check browser console for errors

### "Access Denied" message?
- Verify the user document exists in Firestore
- Check that `role` field is set to `"admin"` (lowercase)
- Make sure the Firestore document ID matches the Auth UID

### "User data not found"?
- The user exists in Authentication but not in Firestore
- Create the Firestore document with the same UID

## Security Checklist

- [ ] Email/Password authentication enabled
- [ ] Firestore security rules deployed
- [ ] Admin user created with correct role
- [ ] Test login working
- [ ] Firebase credentials not committed to git
- [ ] Strong passwords used for admin accounts

---

**Once all steps are complete, your authentication system is ready to use! 🚀**
