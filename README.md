# Todow

A fast, offline-first productivity canvas that keeps all your student work in one place.

## The Problem
You have assignments in a web portal, tasks in a to-do app, schedules in a calendar, and files buried on your hard drive. Every time you sit down to study, you spend ten minutes just gathering your context across five different tabs. That friction kills focus before you even start working.

## The Solution
Todow replaces the scattered tabs with a single, unified local application. No cloud subscriptions required, no forced logins. Your data lives on your device, and the app works perfectly whether you have a connection in a lecture hall or are completely offline in the library.

## Project Status

### ✅ Feature 1: Advanced Task Management (Complete)
Managing your workload should feel fluid and instant. We built tactile interactions directly into the active task list so you can organize your day without opening a single menu.
* **Drag to reorder:** Grab any row and move it to the exact spot you want.
* **Swipe to act:** Swipe right to complete a task. Swipe left to delete it. One smooth gesture clears out finished work instantly.
* **Double tap to insert:** Double tap the space between any two tasks to drop a text field exactly there. Type and hit Enter. Your flow stays unbroken.
* **Splash screen skip:** A tailored greeting that lets returning users bypass the intro and get straight to work.

### 🚧 Feature 2: Local Attachments (In Progress)
Work requires context. We are currently building local file attachment support so you can pin PDFs, images, and lecture notes directly to the tasks they belong to. When you sit down to start an assignment, the exact file you need is already waiting for you.

## Technical Architecture
The application follows a clean, feature-first layered architecture designed for maintainability and offline reliability.

* **Presentation:** Flutter UI, Riverpod state management, and `ChangeNotifier` controllers.
* **Domain:** Pure Dart models, services, and repository interfaces. Contains core business logic and is completely independent of the Flutter framework.
* **Data:** SQLite persistence via `sqflite`.

For in-depth documentation, see the `docs/` directory:
* [Product Scope](docs/PRODUCT.md)
* [Architecture Details](docs/ARCHITECTURE.md)
* [Design Specifications](docs/DESIGN_SPEC.md)
* [Core Flows](docs/FLOWS.md)
* [Roadmap](docs/ROADMAP.md)

## Development Setup

1. Install dependencies:
   ```bash
   flutter pub get
   ```

2. Run the application:
   ```bash
   flutter run
   ```

3. Run the test suite:
   ```bash
   flutter test
   ```

4. Verify static analysis:
   ```bash
   flutter analyze
   ```
