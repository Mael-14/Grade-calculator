# GradeGenie: Grade Calculator App

GradeGenie is a premium Flutter application designed for educators to automate the grading process. It allows teachers to upload Excel/XLSX files containing student scores, automatically calculates letter grades based on a customisable scale, and generates a downloadable report with grade distributions.

## 🚀 Key Features

- **Automated Grading**: Instantly convert numeric scores (0-100) into letter grades.
- **Smart Detection**: Automatically identifies "Student Name" and "Score" columns.
- **Visual Insights**: Generates grade distribution charts (Bar charts).
- **Excel Export**: Generates a new Excel file with original data plus a "Calculated Grade" column.
- **Premium Design**: Modern, responsive UI with smooth transitions and micro-animations.

## 🎨 Frontend & UI Architecture

The frontend is built with Flutter, focusing on a premium, professor-centric user experience.

### UI Screens

- **`WelcomeScreen`**: The onboarding experience. Features a hero illustration with glassmorphism effects and a clear Call-to-Action (CTA). It uses `SafeArea` and `Column` for a balanced layout.
- **`GradeCalculatorScreen`**: The main workspace. It includes:
  - **Interactive Upload Area**: A customized card with shadow and border tokens.
  - **Live Processing State**: Uses an `AnimationController` for a "pulsing" magic icon effect during Excel processing.
  - **Result Visualization**:
    - **Summary Bar**: A high-contrast gradient bar showing completion status.
    - **Distribution Chart**: A dynamic horizontal bar chart showing grade frequency using custom `LinearProgressIndicator` widgets.
    - **Student Table**: A clean, scrollable list of processed students with color-coded grade badges.

### 💎 Design System (`AppTheme`)

The app uses a strict design system defined in `AppTheme` to ensure visual consistency:

- **Color Palette**: Uses a primary brand blue (`#4A6CF7`) and an accent purple (`#6C63FF`).
- **Gradients**: Implements `primaryGradient` (brand identity) and `softGradient` (subtle backgrounds).
- **Typography**: Integrated with **Google Fonts (Inter)**, providing a modern and legible academic feel.
- **Elevation & Depth**: Premium shadows (`cardShadow`, `softShadow`) are used to create layer hierarchy without looking cluttered.
- **Rounding**: Consistent corner radii from `radiusSm` (8px) to `radiusXl` (24px) for a soft, friendly interface.

---

## 🏗️ Project Architecture & Classes

The application follows a clean service-oriented architecture:

### Data Models

- **`StudentRecord`**: A lightweight immutable class holding `name`, `score`, and the assigned `grade`.
- **`GradingResult`**: Encapsulates the output of a grading session, including the file path of the generated Excel, total student count, and the grade distribution map.

### Logic Layer

- **`GradeService`**: The core engine of the app. It uses functional programming paradigms to process Excel bytes, parse data, and handle file system logic. It contains the grade scale definitions and core calculation logic.

---

## 🛠️ Functional Programming Concepts

GradeGenie leverages **Dart's functional features** to keep the codebase concise, readable, and less prone to side-effect bugs.

### 1. Lambda Functions (Anonymous Functions)

Lambda functions are used throughout the `GradeService` for quick expressions and data matching:

- **Grade Matching**:

    ```dart
    static String calculateGrade(double score) =>
        _scale
            .cast<MapEntry<double, String>?>()
            .firstWhere((e) => score >= e!.key, orElse: () => null) // Lambda (e) => ...
            ?.value ?? 'F';
    ```

- **Data Transformation**: Lambdas are used in `map` and `where` blocks to convert spreadsheet rows into `StudentRecord` objects on the fly.

### 2. Higher-Order Functions (HOFs)

Higher-order functions are functions that take other functions as arguments or return them. GradeGenie uses them extensively to process collections:

- **`.map()`**: Used to transform a list of spreadsheet rows into `StudentRecord` objects. It avoids manual `for` loops and makes the transformation logic declarative.
- **`.where()` & `.whereType()`**: Used to filter out empty rows or null records (e.g., rows that lack valid score data) before they reach the UI.
- **`.fold()`**: A powerful HOF used to calculate the **Grade Distribution**. It "folds" the list of students into a `Map<String, int>` by incrementing counts for each grade found.

    ```dart
    final distribution = students.fold<Map<String, int>>(
      {},
      (map, s) => map..update(s.grade, (v) => v + 1, ifAbsent: () => 1),
    );
    ```

- **`.firstWhere()`**: Used to locate the correct grade from the scale or to find the first non-empty sheet in an uploaded Excel workbook.

---

## 🛠️ Getting Started

1. **Dependencies**: Ensure `excel`, `file_picker`, `share_plus`, and `google_fonts` are in your `pubspec.yaml`.
2. **Run**: `flutter run`
3. **Template**: You can use the "Download Template" button in the app to see the expected Excel format.

---

*Developed with ❤️ for Professors.*
