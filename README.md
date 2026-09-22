<div align="center">
  <img src="LOGO.jpeg" width="110" height="110" style="border-radius: 24px;" alt="Nirma Hub Logo" />

  # 🎓 Nirma Hub
  **The All-in-One Student Companion App for Nirma University**

  <p align="center">
    <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.10+-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" /></a>
    <a href="https://dart.dev"><img src="https://img.shields.io/badge/Dart-3.10+-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart" /></a>
    <a href="https://supabase.com"><img src="https://img.shields.io/badge/Supabase-Backend-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white" alt="Supabase" /></a>
    <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge" alt="License: MIT" /></a>
    <a href="#"><img src="https://img.shields.io/badge/Platform-Android-3DDC84?style=for-the-badge&logo=android&logoColor=white" alt="Platform" /></a>
  </p>

  <p align="center">
    <b>Nirma Hub</b> brings timetables, exam score targets, past papers, notes and the campus community
    into one fast, offline-friendly app — now with a full light &amp; dark theme.
  </p>
</div>

---

## 👥 Team

- **Dhyey Bhalani** — UI/UX, Frontend Development, Project Coordination, Marketing & Play Store Deployment
- **Harshil Dhameliya** — UI/UX, Frontend Development, Agile Project Execution, Content Management & Testing
- **Monil Mangukiya** — UI/UX, Academic Resources & Content Management, Structure Design & Testing
- **Dhruv Bhalala** — Backend Development, Database & Authentication, Cloud Architecture, API Integration & Admin Panel Development

---

## ✨ Features

### Academics
- **Smart timetable & pre-class alarms** — tailored to your branch, year, division and batch. Background lecture alarms carry the classroom, the professor and gap detection between lectures.
- **SGPA target calculator** — work backwards from the grade you want to the marks you need in the Semester End Exam. Internal components (sessionals, assignments, labs, LPW) are configured per subject, so the maths matches your actual scheme.
- **Estimated CGPA** — enter the SGPA of each completed semester and see your running CGPA alongside the live estimate for the current one. Which semesters a year has to fill in is configured from the admin panel, so no app release is needed each term.
- **Notes, PYQs & Most IMP** — topper-verified notes, previous year papers by semester and subject, and curated high-yield question guides, all readable in a built-in PDF viewer with offline caching.

### Campus
- **Coding leaderboards** — live LeetCode and Codeforces rankings across the college.
- **Lost & Found** — report and recover ID cards, calculators, keys and electronics.
- **Peer to Peer** — a student marketplace for books, lab coats, drafters and equipment.
- **Academic calendar & announcements** — university circulars, exam dates, fests and holiday countdowns.

### Experience
- **Light & dark themes** — a true-black dark mode with a sun/moon switch in the home app bar. Your choice is remembered; until you pick one, the app follows the system setting.
- **Built for a phone in a lecture hall** — skeleton loaders, haptics, offline PDF cache and predictive-back navigation.

---

## 🛠 Tech Stack

| Layer | Choice |
| --- | --- |
| App | Flutter (Dart), Material 3 |
| State | [Riverpod](https://riverpod.dev) |
| Backend | [Supabase](https://supabase.com) — Postgres, Row Level Security, Auth, Storage, Edge Functions |
| Auth | Google Sign-In, restricted to `@nirmauni.ac.in` accounts |
| Push | Firebase Cloud Messaging + `flutter_local_notifications` |
| Theming | A single semantic palette (`lib/core/theme/app_theme.dart`) shared by every screen |

---

## 📁 Project Structure

```text
lib/
├── main.dart                     # Entry point, MaterialApp, auth gate, login/registration
├── home_screen.dart              # Dashboard, timetable carousel, calendar, semester progress
├── sgpa_calculator_screen.dart   # SGPA target calculator + estimated CGPA
├── notes_screen.dart             # Notes browser and the in-app PDF viewer
├── pyq_subjects_screen.dart      # PYQ subjects -> pyq_list_screen.dart
├── most_imp_screen.dart          # Curated high-yield question guides
├── lost_found_screen.dart        # Lost & Found
├── peer_to_peer_screen.dart      # Student marketplace
├── profile_screen.dart           # Profile, settings, account management
│
├── core/
│   ├── theme/app_theme.dart      # AppColors palette, light/dark ThemeData, ThemeController
│   └── utils/                    # Image compression and other helpers
│
├── features/                     # Feature modules: data / domain / presentation
│   ├── auth/                     # Profiles, session, Google Sign-In
│   ├── coding/                   # LeetCode & Codeforces leaderboards
│   ├── timetable/                # Timetable models, provider, full week view
│   ├── notifications/            # Notification preferences and scheduling
│   ├── events/  lost_and_found/  peer_to_peer/  moderation/
│
├── services/                     # Cross-cutting services (notifications, analytics, ratings)
└── widgets/                      # Shared UI: skeletons, theme toggle, sheets, buttons

supabase/
├── functions/                    # Edge Functions (account deletion, FCM push, coding sync)
└── sql/                          # SQL you run in the Supabase SQL editor
```

> The Flutter app in this repository is the student-facing client. The internal admin panel used to
> publish notes, papers, timetables and announcements is kept in a separate private repository,
> because it authenticates with a privileged Supabase key.

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) `^3.10.4` or newer
- Android Studio or VS Code with the Flutter extension
- An Android device or emulator (Android 8.0 / API 26+)
- A [Supabase](https://supabase.com) project and a [Firebase](https://firebase.google.com) project of your own

### Setup

1. **Clone**
   ```bash
   git clone https://github.com/dhyeybhalani2/Nirma-Hub.git
   cd Nirma-Hub
   ```

2. **Environment variables** — copy the template and fill in your own project:
   ```bash
   cp .env.example .env
   ```
   ```dotenv
   SUPABASE_URL=https://<your-project>.supabase.co
   SUPABASE_ANON_KEY=<your anon key>
   ```
   Use the **anon** key only. The `service_role` key must never appear in the app or in this repo.

3. **Firebase** — add your own `android/app/google-services.json` from the Firebase console.

4. **Run**
   ```bash
   flutter pub get
   flutter run
   ```

### Database

SQL that the app expects lives in [`supabase/sql/`](supabase/sql/). Run each file once in
**Supabase → SQL Editor**. For example, [`2026_cgpa_feature.sql`](supabase/sql/2026_cgpa_feature.sql)
creates the CGPA tables, their Row Level Security policies and some starter rows.

---

## 🎨 Theming

Every screen reads its colours from one semantic palette instead of hard-coding hex values, so light
and dark stay in step:

```dart
Container(
  color: context.c.card,                       // surface
  child: Text('Hello', style: TextStyle(color: context.c.text)),
)
```

Colours are named by role — `bg`, `card`, `fill`, `border`, `text`, `textMuted`, `accent`,
`accentFill`, `success`, `danger` and so on. Note the split between a **text tone** and a **fill
tone**: `accent` is for text, icons and borders, while `accentFill` is the deeper shade used behind
a white label. Using the text tone as a button background is the most common way to get unreadable
buttons in dark mode.

`ThemeController` in the same file holds the user's choice and persists it.

---

## 🤝 Contributing

Pull requests are welcome. See [**CONTRIBUTING.md**](CONTRIBUTING.md) for branch naming, coding
standards (`dart format` and `dart analyze` must be clean) and the PR process.

---

## 🔒 Security

Report vulnerabilities privately as described in [**SECURITY.md**](SECURITY.md).

Never commit:
- `.env` or any file containing a Supabase `service_role` key
- release keystores (`*.jks`, `*.keystore`) or `key.properties`
- `supabase/.temp/` — Supabase CLI local state, which records your project reference and account

---

## 📄 License

Distributed under the **MIT License**. See [`LICENSE`](LICENSE).

---

<div align="center">
  <sub>Built with ❤️ for Nirma University students.</sub>
</div>
