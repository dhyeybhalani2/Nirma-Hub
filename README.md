<div align="center">
  <img src="LOGO.jpeg" width="110" height="110" style="border-radius: 24px;" alt="Nirma Hub Logo" />
  
  # 🎓 Nirma Hub
  **The All-in-One Student Companion App for Nirma University**

  <p align="center">
    <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.10+-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" /></a>
    <a href="https://dart.dev"><img src="https://img.shields.io/badge/Dart-3.0+-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart" /></a>
    <a href="https://supabase.com"><img src="https://img.shields.io/badge/Supabase-Backend-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white" alt="Supabase" /></a>
    <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge" alt="License: MIT" /></a>
    <a href="#"><img src="https://img.shields.io/badge/Platform-Android-3DDC84?style=for-the-badge&logo=android&logoColor=white" alt="Platform" /></a>
  </p>

  <p align="center">
    <b>Nirma Hub</b> brings essential academic utilities, smart class reminders, exam score targets, past papers, and campus community into one unified, lightning-fast application.
  </p>
</div>

---

## ✨ Key Features

- 🔔 **Smart Timetable & Pre-Class Alarms**:
  - Automatically customized for your Branch, Academic Year, Division, and Batch.
  - Background lecture alarms with classroom location, professor details, and gap detection.
- 🎯 **SGPA & SEE Target Calculator**:
  - Predict exact marks needed in your Semester End Exams (SEE) to secure your target SGPA (10.0, 9.0, 8.0).
  - Component-based internal calculation (Assignments, Mid-terms, LPWs, Labs).
- 💻 **Campus Coding Leaderboards**:
  - Live LeetCode & Codeforces rankings to track ratings, contest performance, and compete with college peers.
- 📚 **Previous Year Question Papers (PYQs) & Notes**:
  - Comprehensive Mid-Sem & End-Sem past papers organized by semester and subject with a built-in offline PDF reader.
- 🔍 **Campus Lost & Found Hub**:
  - Connect with fellow students to report and recover lost ID cards, calculators, electronics, and keys.
- 🗓️ **Academic Calendar & University Notices**:
  - Real-time university circulars, exam dates, college fests, and holiday countdowns.

---

## 🛠️ Tech Stack & Architecture

- **Frontend**: [Flutter](https://flutter.dev) (Dart)
- **State Management**: [Riverpod](https://riverpod.dev)
- **Backend & Database**: [Supabase](https://supabase.com) (PostgreSQL, Row Level Security, Auth, Storage)
- **Notifications**: [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications) & Firebase Cloud Messaging (FCM)
- **Monetization & Ads**: Google Mobile Ads SDK (AdMob)
- **Design System**: Modern Material 3 Design, Custom Haptic Feedback, Glassmorphic & Skeleton loaders

---

## 📁 Project Structure

```text
lib/
├── features/
│   ├── auth/              # Authentication & User Profiles
│   ├── notifications/     # Timetable Notification Settings & Alerts
│   └── ...
├── models/                # Timetable, Events, PYQs, and User data models
├── services/
│   ├── ad_service.dart          # AdMob integration & monetization logic
│   ├── notification_service.dart# Local notification scheduling & holiday checks
│   ├── events_service.dart      # Academic calendar & events
│   └── supabase_service.dart    # Supabase client wrapper
├── screens/               # Feature screens (Timetable, SGPA, PYQs, Lost & Found, Profile)
├── widgets/               # Reusable UI components & custom animated buttons
└── main.dart              # Application entry point & theme initialization
```

---

## 🚀 Getting Started (Local Setup)

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (version `^3.10.4` or higher)
- [Android Studio](https://developer.android.com/studio) or VS Code with Flutter extension
- An Android Device or Emulator (Android 8.0+ / API 26+)

### Installation Steps

1. **Clone the repository**:
   ```bash
   git clone https://github.com/YOUR_USERNAME/nirma-hub.git
   cd nirma-hub
   ```

2. **Set up Environment Variables**:
   Copy the example environment template:
   ```bash
   cp .env.example .env
   ```
   Add your test Supabase credentials inside `.env`.

3. **Install dependencies**:
   ```bash
   flutter pub get
   ```

4. **Run the app**:
   ```bash
   flutter run
   ```

---

## 🤝 Contributing

Contributions make the open-source community an incredible place to learn, inspire, and create. Any contributions you make are **greatly appreciated**!

Please see our [**CONTRIBUTING.md**](CONTRIBUTING.md) for detailed guidelines on:
- Branch naming conventions
- Coding standards & formatting (`dart format` & `dart analyze`)
- Submitting a Pull Request

---

## 🔒 Security

For security vulnerability disclosures or reporting sensitive issues, please refer to our [**SECURITY.md**](SECURITY.md).
> ⚠️ **Note**: Never commit production keystores (`*.jks`), `key.properties`, or Supabase `service_role` secret keys.

---

## 📄 License

Distributed under the **MIT License**. See [`LICENSE`](LICENSE) for more information.

---

<div align="center">
  <sub>Built with ❤️ by the <b>Nirma Hub Team</b> & Open Source Contributors.</sub>
</div>
