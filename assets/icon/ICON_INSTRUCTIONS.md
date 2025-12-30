# App Icon Instructions

## Required Files

Place the following PNG files in this directory:

### 1. `app_icon.png` (1024x1024 pixels)
- Main app icon shown on home screen
- Should have NHS Blue (#005EB8) background
- White medical/radiology symbol (e.g., simplified CT scanner or medical cross)
- Square with rounded corners handled by the OS

### 2. `app_icon_foreground.png` (1024x1024 pixels)
- For Android adaptive icons (Android 8.0+)
- Transparent background with white icon in center
- Keep important content within center 66% (safe zone)

### 3. `splash_logo.png` (512x512 pixels)
- Logo shown on splash screen during app launch
- White icon on transparent background
- Will be displayed on NHS Blue (#005EB8) background

## Suggested Design

Simple medical cross or stylized "SM" monogram in white:
- Clean, modern, accessible design
- High contrast for visibility
- Works at small sizes (app icon on phone)

## Generating Icons

After placing the PNG files, run:

```bash
# Generate app icons for iOS and Android
flutter pub run flutter_launcher_icons

# Generate native splash screens
flutter pub run flutter_native_splash:create
```

## Temporary Placeholder

Until you have custom icons, the app will use default Flutter icons.
You can use online tools like:
- Canva (canva.com)
- Figma (figma.com)
- App Icon Generator (appicon.co)
