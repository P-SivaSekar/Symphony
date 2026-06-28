const fs = require('fs');

// 1. Update settings.gradle.kts
let settingsCode = fs.readFileSync('android/settings.gradle.kts', 'utf8');
if (!settingsCode.includes('com.google.gms.google-services')) {
    settingsCode = settingsCode.replace(
        'id("org.jetbrains.kotlin.android") version "2.2.20" apply false',
        'id("org.jetbrains.kotlin.android") version "2.2.20" apply false\n    id("com.google.gms.google-services") version "4.4.2" apply false'
    );
    fs.writeFileSync('android/settings.gradle.kts', settingsCode, 'utf8');
}

// 2. Update app/build.gradle.kts
let buildCode = fs.readFileSync('android/app/build.gradle.kts', 'utf8');
if (!buildCode.includes('com.google.gms.google-services')) {
    buildCode = buildCode.replace(
        'id("dev.flutter.flutter-gradle-plugin")',
        'id("dev.flutter.flutter-gradle-plugin")\n    id("com.google.gms.google-services")'
    );
    fs.writeFileSync('android/app/build.gradle.kts', buildCode, 'utf8');
}
