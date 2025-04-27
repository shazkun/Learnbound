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
- Android SDK
- Windows SDK (preferable windows 10)
- Android Studio or VSCode with Flutter extensions

### Setup
📚 Resources

Flutter Docs

LAN Communication in Flutter

State Management: Provider

Audio Feedback: audioplayers
<details> <summary>📄 Question Format JSON (click to expand)</summary>
[
  {
    "id": "{id}",  
    "text": "{question_text}",  
    "type": "shortAnswer",  
    "correctAnswer": "{correct_answer}"  
  },

  

 {
  "id": "{id}",
  "text": "{question_text}",
  "type": "selectMultiple",
  "options": [
    { "text": "{option_1}", "isCorrect": true },
    { "text": "{option_2}", "isCorrect": false },
    { "text": "{option_3}", "isCorrect": true },
    { "text": "{option_4}", "isCorrect": false }
  ]
}


{
  "id": "{id}",
  "text": "{question_text}",
  "type": "selectMultiple",
  "options": [
    { "text": "{option_1}", "isCorrect": true },
    { "text": "{option_2}", "isCorrect": false },
    { "text": "{option_3}", "isCorrect": true },
    { "text": "{option_4}", "isCorrect": false }
  ]
}


]
  </details>


✅ Supported Question Types
"shortAnswer" – open-ended questions with a single correct answer

"multipleChoice" – one correct answer out of several options

"selectMultiple" – multiple correct answers allowed

bash
```bash
git clone https://github.com/shazkun/Learnbound
cd learnbound_flutter
flutter pub get
flutter run




