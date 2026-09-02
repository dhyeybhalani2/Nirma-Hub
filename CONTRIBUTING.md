# Contributing to Nirma Hub 🚀

First off, thank you for considering contributing to **Nirma Hub**! 🎉
Whether you're fixing a bug, adding a new campus utility, improving UI/UX, or adding documentation, your contributions help make college life easier for thousands of students.

---

## 📋 Code of Conduct

- Be respectful, constructive, and collaborative.
- Focus on clean, readable code and student-first user experiences.
- Welcome contributors of all skill levels.

---

## 🛠️ How to Contribute

### 1. Fork & Clone
1. Fork the repository to your GitHub account by clicking **Fork** at the top right.
2. Clone your fork locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/nirma-hub.git
   cd nirma-hub
   ```

### 2. Set Up the Environment
1. Make sure you have **Flutter 3.10+** installed:
   ```bash
   flutter doctor
   ```
2. Copy the example environment variables:
   ```bash
   cp .env.example .env
   ```
   *(Add your Supabase test credentials if working on database features).*
3. Install dependencies:
   ```bash
   flutter pub get
   ```

### 3. Create a Feature Branch
Always create a new branch for your feature or bug fix:
```bash
# For a new feature:
git checkout -b feat/add-attendance-tracker

# For a bug fix:
git checkout -b fix/timetable-alarm-offset

# For documentation/UI polish:
git checkout -b docs/update-readme
```

### 4. Coding Standards & Lints
Before committing your changes, ensure there are no syntax issues or analyze warnings:
```bash
dart format lib/
dart analyze lib/
```

### 5. Commit Your Changes
Write clear, conventional commit messages:
- `feat: add filter for morning shifts in timetable`
- `fix: resolve SGPA calculation rounding error`
- `docs: improve contribution guide`

### 6. Push & Submit a Pull Request
1. Push your branch to your GitHub fork:
   ```bash
   git push origin feat/your-feature-name
   ```
2. Open GitHub, navigate to your fork, and click **Compare & pull request**.
3. Fill out the PR description template clearly explaining:
   - What changed
   - Screenshots/videos (if UI changes were made)
   - Testing steps performed

---

## 💡 Ideas for Contribution
- 📊 **New Calculators**: Attendance percentage required, minor degree credit tracker.
- 🎨 **UI/UX Themes**: Dark mode enhancements, festive themes, skeleton loading polish.
- ⚡ **Performance**: Cache optimization for offline PDF reading and notes viewer.
- 🧪 **Testing**: Unit tests and widget tests for core calculators and timetable parser.

---

Thank you for helping build **Nirma Hub**! 🎓
