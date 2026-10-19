#!/usr/bin/env bash
# Builds android/plugins/ImagePicker.aar without Gradle: compile against the Godot plugin API and the Android SDK, then pack.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ANDROID_JAR="${ANDROID_JAR:-$HOME/Android/Sdk/platforms/android-35/android.jar}"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/classes"
javac --release 17 -cp "$ANDROID_JAR:$HERE/lib/godot-plugin-api.jar" -d "$WORK/classes" "$HERE"/src/com/minhth/slidepuzzle/imagepicker/*.java
(cd "$WORK/classes" && jar cf "$WORK/classes.jar" .)
# Godot discovers local plugins through this manifest entry.
cat > "$WORK/AndroidManifest.xml" <<'XML'
<manifest xmlns:android="http://schemas.android.com/apk/res/android" package="com.minhth.slidepuzzle.imagepicker">
    <application>
        <meta-data android:name="org.godotengine.plugin.v2.ImagePicker" android:value="com.minhth.slidepuzzle.imagepicker.ImagePickerPlugin" />
    </application>
</manifest>
XML
(cd "$WORK" && jar cf "$HERE/../plugins/ImagePicker.aar" AndroidManifest.xml classes.jar)
echo "built $HERE/../plugins/ImagePicker.aar"
