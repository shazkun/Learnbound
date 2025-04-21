# LearnBound Mobile/Windows

**LearnBound** is an interactive, LAN-based educational quiz application built with Flutter. It is designed as a collaborative tool for classrooms, study groups, or remote learning environments.

## ✨ Features

- **📡 Local Host/Join System**  
  Create or join quiz sessions over a local network with no need for internet access.

- **🧠 Quiz Management (CRUD)**  
  Import, create, update, and delete quizzes with full control over your educational content.

- **📤 Import/Export Quizzes**  
  Easily share quizzes via files or through local peer-to-peer connections.

- **📲 Real-time Interactivity**  
  Participate in quizzes in real-time, with support for peer-to-peer LAN communication.

- **🔒 Offline & Secure**  
  All interactions stay within the local network, ensuring a secure and internet-independent environment.

- **🔔 Sound Effects**  
  Integrated audio feedback using the `audioplayers` package to make learning more engaging.

## 🧩 Use Cases

- Classroom quiz games and exercises  
- Study group challenges  
- Review sessions with real-time feedback  
- Local training tools without internet

## 🚀 Getting Started

### Prerequisites

- Flutter SDK
- Dart SDK
- Android Studio or VSCode with Flutter extensions

### Setup

📂 Folder Structure
bash
Copy
Edit
lib/
│
├── main.dart              # Entry point
├── screens/               # UI screens (host, join, quiz management, etc.)
├── models/                # Quiz and user data models
├── services/              # LAN socket handling, data sync, quiz logic
├── providers/             # State management (e.g., using Provider)
└── utils/                 # Helpers, constants, and utilities
```bash
git clone https://github.com/yourusername/learnbound_flutter.git
cd learnbound_flutter
flutter pub get
flutter run


📚 Resources
Flutter Docs

LAN Communication in Flutter

State Management: Provider

Audio Feedback: audioplayers

