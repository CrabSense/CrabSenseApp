# Inter Font Family

This directory should contain the Inter font family files for the CrabSense Mobile application.

## Required Font Files

Download the Inter font family from: https://fonts.google.com/specimen/Inter

You need the following font files:
- `Inter-Regular.ttf` (400 weight)
- `Inter-Medium.ttf` (500 weight)
- `Inter-SemiBold.ttf` (600 weight)
- `Inter-Bold.ttf` (700 weight)

## Installation Steps

1. Visit https://fonts.google.com/specimen/Inter
2. Click "Download family"
3. Extract the ZIP file
4. Copy the following files to this directory (`assets/fonts/`):
   - `Inter-Regular.ttf`
   - `Inter-Medium.ttf`
   - `Inter-SemiBold.ttf`
   - `Inter-Bold.ttf`
5. The fonts are already configured in `pubspec.yaml`

## Alternative: Using Google Fonts Package

If you prefer to use fonts from Google Fonts API:

1. Add dependency to `pubspec.yaml`:
   ```yaml
   dependencies:
     google_fonts: ^6.1.0
   ```

2. Update the theme in `lib/app/theme.dart` to use GoogleFonts:
   ```dart
   import 'package:google_fonts/google_fonts.dart';
   
   // In CrabSenseTheme.darkTheme, replace fontFamily:
   textTheme: GoogleFonts.interTextTheme(
     Theme.of(context).textTheme,
   ),
   ```

## License

Inter font is licensed under the SIL Open Font License 1.1
https://github.com/rsms/inter/blob/master/LICENSE.txt
