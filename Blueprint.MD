# 🐾 Loaf: Ultra-Sensory Kitten Gym
## Project Blueprint & AI Prompt (V7: "Iron-Build" Edition)

### 🎯 Identity
- **App Name**: Loaf
- **Package Name**: `com.rakin.loaf`
- **Objective**: Build a high-performance, Cross-Platform (Android, Web, Windows) sensory game for kittens.

---

### 🏗️ Environmental Specifications (Iron-Build)
Use these exact versions in your Android build configuration to ensure stability:
- **Gradle Version**: `8.14`
- **Android Gradle Plugin (AGP)**: `8.11.1`
- **Kotlin Version**: `2.2.20`
- **Google Services Plugin**: `4.4.2`
- **Flutter SDK**: `3.29.0` (or current stable)

---

### 📦 The "HydroSync" Dependency Stack
```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.1
  shared_preferences: ^2.2.2
  intl: ^0.19.0
  flutter_local_notifications: ^21.0.0
  google_fonts: ^6.2.1
  firebase_core: ^4.7.0
  firebase_auth: ^6.4.0
  cloud_firestore: ^6.3.0
  window_manager: ^0.5.1
  sensors_plus: ^7.0.0
  timezone: ^0.11.0
  flutter_dotenv: ^6.0.1
```

---

### 🎨 Design System: The "Dusty" Duo
- **Themes**: Dusty Midnight (Dark/Indigo) & Dusty Ocean (Slate/Teal).
- **Aesthetics**: Glassmorphism, Neumorphic inner shadows, and Natural textures (Wood/Grass/Sand).
- **Visibility**: Dichromatic Blue/Yellow focus for feline eyes.

---

### 🚀 Performance Engineering (Zero-Jank)
- **Engine**: Impeller (Android), CanvasKit (Web), Skia (Windows).
- **FPS**: 120fps target.
- **Rules**: `RepaintBoundary` for isolation, avoid `saveLayer()`, pre-cache all assets.

---

### 🕹️ Mini-Game Suite
- **Under the Rug** (Bump Physics)
- **Procedural Bug Swarm** (Boids AI)
- **Galactic Laser Path** (Physics)
- **Pond Skater** (Liquid Physics)
- **String & Feather** (Accelerometer/Mouse)

---

### 🚀 Bootstrapping Prompt (V7)
> "Create a new Flutter project called 'Loaf' (com.rakin.loaf) using the V7 'Iron-Build' Blueprint. 
> 1. Set the Android build to use Gradle 8.14, AGP 8.11.1, and Kotlin 2.2.20. 
> 2. Use the HydroSync dependency stack for architectural stability.
> 3. Implement the Multi-Cat Profile system and the 'Dusty' theme switcher.
> 4. Build the 5 core game modes at 120fps using Impeller/CanvasKit.
> 5. **TECHNICAL**: Mirror the clean Provider/Service architecture from HydroSync."

---

**Loaf V7 is locked, loaded, and ready for the oven. 🐾🍞🚀**
