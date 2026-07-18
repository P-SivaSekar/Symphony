# 🎵 Symphony

<p align="center">
  <img src="https://raw.githubusercontent.com/P-SivaSekar/Symphony/main/assets/app_icon.png" alt="Symphony Logo" width="120"/>
</p>

<p align="center">
  A modern, elegant, and feature-rich Tamil music player built with Flutter.
</p>

<p align="center">
  <a href="https://github.com/P-SivaSekar/Symphony/releases/download/v1.0.0.3/Symphony.apk">
    <img src="https://img.shields.io/badge/Download-v1.0.0.3-brightgreen?style=for-the-badge&logo=android" alt="Download APK"/>
  </a>
  <img src="https://img.shields.io/badge/Platform-Android-blue?style=for-the-badge&logo=android" alt="Platform"/>
  <img src="https://img.shields.io/badge/Built%20With-Flutter-02569B?style=for-the-badge&logo=flutter" alt="Flutter"/>
</p>

---

## ✨ Features

| Feature | Description |
|---|---|
| 🎵 **Stream Tamil Songs** | Browse & play Tamil songs powered by JioSaavn |
| 🏠 **For You Page** | Personalized song recommendations |
| 🔍 **Smart Search** | Find songs, artists, and movies instantly |
| 💾 **Offline Downloads** | Download songs with cover art for offline listening |
| 🎨 **Beautiful UI** | Glassmorphism design with smooth animations |
| 🎤 **Explore Playlists** | Curated playlists — Ilayaraja, A.R. Rahman, Harris Jayaraj, Anirudh & more |
| ☁️ **Cloud Sync** | Firebase integration for favorites and history |
| 📱 **Mini Player** | Always-on mini player while browsing |

---

## 🐛 Known Issues & Bugs

- [ ] **Liked Songs Playlist Sync:** Liked songs are not showing up inside the Liked Playlist.
- [ ] **Explore Page Playlist Duplication:** The explore page has redundant playlists (e.g., two Anirudh playlists containing similar songs).

---

## 🚀 Roadmap & Planned Enhancements

### 🎶 Content & Curation
- **Trending & New Releases:** Add sections/playlists dedicated to trending songs and new releases.
- **Explore Page Revamp:** Redesign the explore page to showcase a diverse set of categories, genres, top charts, and search highlights (rather than displaying only playlists).

### 🎨 User Interface (UI) Revamps
- **Profile UI:** Revamp the user profile screen to look modern, clean, and interactive.
- **Settings UI:** Redesign the settings interface for a more intuitive and visually appealing layout.

### 📱 Mobile Features & Permissions
- **Push Notification Permission:** Implement a prompt/permission request for push notifications on mobile devices, triggered during the first-time application launch after installation.

---

## 📱 Android Installation

1. **Download the APK directly:**
   👉 [**Symphony v1.0.0.3 APK**](https://github.com/P-SivaSekar/Symphony/releases/download/v1.0.0.3/Symphony.apk)

2. Transfer the APK to your Android device (if downloaded on a PC).

3. Open a **File Manager** on your device and tap `Symphony.apk` to install.
   > **Note:** You may need to enable **"Install from Unknown Sources"** in your Android settings.

4. Launch Symphony and enjoy your music! 🎶

---

## 🌐 Web App

Access Symphony directly from your browser — no installation needed!

👉 [**Open Symphony Web App**](https://symphony-music-app-6eddc.web.app/)

---

## 🗂️ Project Structure

```
Symphony/
├── lib/              # Flutter app source code
│   ├── models/       # Data models
│   ├── services/     # API & backend services
│   └── ui/           # UI screens and widgets
├── android/          # Android platform code
├── assets/           # Images, fonts, icons
├── web/              # Web platform code
├── test/             # Tests & API test scripts
├── scripts/          # Utility & release scripts
├── docs/             # Additional documentation
└── pubspec.yaml      # Flutter project config
```

---

## 🛠️ Built With

- [Flutter](https://flutter.dev) — Cross-platform UI framework
- [Firebase](https://firebase.google.com) — Auth, Firestore, Storage
- [Just Audio](https://pub.dev/packages/just_audio) — Audio playback
- [JioSaavn API](https://saavn.dev) — Tamil music streaming

---

## 📄 License

This project is for personal and educational use.
