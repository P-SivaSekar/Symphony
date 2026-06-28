# Symphony App — Manual Setup Instructions

This file covers everything you need to set up manually before the app is fully functional.

---

## 1. Firebase Project Setup (One-time)

### 1.1 Enable Email/Password Authentication
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project → **Authentication** → **Sign-in method** tab
3. Click **Email/Password**
4. Toggle the **first switch** to ON
5. Click **Save**

### 1.2 Create Firestore Database
1. In Firebase Console → **Firestore Database** → **Create database**
2. Choose **Start in production mode** (or test mode for development)
3. Pick a region close to you (e.g., `asia-south1` for India)

### 1.3 Set Firestore Security Rules (for development)
Paste these rules in **Firestore → Rules**:
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### 1.4 Add SHA-1 Fingerprint to Firebase (REQUIRED for Android auth)

> This is the most common cause of the "unknown" error on Create Account / Login.

Your debug SHA-1 fingerprint is:
```
F3:39:C5:D1:F9:D5:90:4E:67:AF:38:77:94:97:78:C2:8D:1B:9F:13
```

Steps to add it:
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your Symphony project
3. Click the **gear icon** (Project Settings) at the top left
4. Scroll down to **Your apps** section
5. Click your **Android app** (com.example.symphony.symphony)
6. Under **SHA certificate fingerprints**, click **Add fingerprint**
7. Paste: `F3:39:C5:D1:F9:D5:90:4E:67:AF:38:77:94:97:78:C2:8D:1B:9F:13`
8. Click **Save**
9. Download the updated `google-services.json` and replace the one in `android/app/google-services.json`

After this, rebuild and run the app — account creation will work.

---

## 2. Cloudinary Setup (One-time)

### 2.1 Create an Upload Preset
1. Go to [Cloudinary Console](https://cloudinary.com/console)
2. Navigate to **Settings → Upload → Upload presets**
3. Click **Add upload preset**
4. Set the following:
   - **Preset name**: `symphony_preset`  <- Must match exactly
   - **Signing mode**: `Unsigned`
   - **Folder**: `symphony_audio` (optional, for organization)
   - **Resource type**: `video` (Cloudinary treats audio as video type)
5. Click **Save**

> The preset name must be `symphony_preset` — this is hardcoded in `admin_upload_service.dart`.

---

## 3. How to Login as Admin and Upload Songs

### Step 1 — Create a Regular User Account
When you first open the app, you will land on the **Sign Up** screen.
Enter any email + password (min 6 characters) and tap **Create Account**.

### Step 2 — Access the Admin Dashboard
Once logged in on the Home screen:
1. **Long-press the "Symphony" title** at the top center of the screen
2. This opens the hidden **Admin Dashboard**

### Step 3 — Upload a Song
In the Admin Dashboard:
1. Enter the **Song Title**
2. Enter the **Artist Name**
3. Paste a **Cover Image URL** (e.g., from Unsplash)
4. Tap **Select Audio** to pick an .mp3 file from your device
5. (Optional) Check **Mark as Trending**
6. Tap **Upload and Save**

The audio file will be uploaded to Cloudinary and the song metadata will be saved to Firestore automatically.

---

## 4. Cloudinary Credentials in Code

| Field | Value |
|---|---|
| Cloud Name | dx02qjcqn |
| Upload Preset | symphony_preset |
| Upload Endpoint | https://api.cloudinary.com/v1_1/dx02qjcqn/video/upload |

The API Key is not needed for unsigned uploads.

---

## 5. Song Structure in Firestore

Each document in the `songs` collection has these fields:

| Field | Type | Description |
|---|---|---|
| title | String | Song title |
| artist | String | Artist name |
| coverUrl | String | Direct image URL |
| audioUrl | String | Cloudinary secure_url |
| isTrending | Boolean | Show in Trending section |
| createdAt | Timestamp | Auto-set on upload |

---

## 6. Known Behavior

- If Firestore has no songs yet, the app shows 3 built-in demo songs so the UI is not empty.
- Once you upload songs via Admin, they will replace the demo songs on next login.
- The Admin Dashboard is intentionally hidden (long-press the title). Any logged-in user who knows the gesture can access it.
