# Unite the Kingdoms - Setup Instructions

## Firebase Configuration

1. **Create Firebase Project**
   - Go to https://console.firebase.google.com/
   - Create a new project named "unite-kingdoms-game"
   - Enable Google Analytics (optional)

2. **Configure Authentication**
   - In Firebase Console, go to Authentication > Sign-in method
   - Enable Email/Password and Google sign-in
   - For Google sign-in, add your app's SHA-1 fingerprint

3. **Configure Firestore Database**
   - Go to Firestore Database > Create database
   - Start in test mode for development
   - Set up the following collections:
     - `users` (user profiles)
     - `gameStates` (player progress)

4. **Add Firebase Apps**
   - Add Android app with package name: `com.example.unite_kingdoms`
   - Download `google-services.json` and place in `android/app/`
   - Add iOS app with bundle ID: `com.example.unite_kingdoms`
   - Download `GoogleService-Info.plist` and place in `ios/Runner/`

5. **Configure AdMob**
   - Create AdMob account and link to Firebase
   - Create rewarded ad units
   - Replace test ad unit IDs in `ads_service.dart`

## Development Setup

1. **Install Dependencies**
   ```bash
   flutter pub get
   ```

2. **Run on Device/Emulator**
   ```bash
   flutter run
   ```

3. **Build for Release**
   ```bash
   flutter build apk --release  # Android
   flutter build ios --release  # iOS
   ```

## Game Configuration

The game is fully configurable through JSON files in `assets/config/`:

- `unit_stats.json` - Unit properties and characteristics
- `tower_stats.json` - Tower costs, damage, and abilities  
- `map_sections.json` - All 100 campaign levels
- `costs.json` - Economy balance and monetization

## Production Considerations

1. **Security Rules**: Update Firestore security rules for production
2. **Analytics**: Configure Firebase Analytics events
3. **Crash Reporting**: Enable Firebase Crashlytics
4. **Performance**: Test on low-end devices
5. **Monetization**: Replace test ad unit IDs with production IDs

## Architecture Overview

- **Models**: Game entities (Tower, Unit, GameState)
- **Services**: Firebase integration, game logic, ads
- **Screens**: UI for authentication, menus, and gameplay
- **Widgets**: Reusable game components
- **Config**: JSON-driven game balance and content

The app follows clean architecture principles with separation of concerns and dependency injection through Provider.
