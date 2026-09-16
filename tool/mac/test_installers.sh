#!/usr/bin/env bash
# shellcheck disable=SC2016  # the fakes are written with literal $vars on purpose
# Runs the Mac installers end to end on any Linux/macOS box against FAKE
# flutter / adb / xcrun / keytool, and checks what they would have done.
#   bash tool/mac/test_installers.sh
set -uo pipefail
SRC="$(cd "$(dirname "$0")/../.." && pwd)"
fails=0
pass() { printf '  ok    %s\n' "$*"; }
fail() { printf '  FAIL  %s\n' "$*"; fails=$((fails + 1)); }
has()  { grep -qF -- "$2" "$1" && pass "$3" || { fail "$3"; sed 's/^/        | /' "$1" | tail -15; }; }
hasnt(){ grep -qF -- "$2" "$1" && fail "$3" || pass "$3"; }

# $1 = devices JSON; creates a fresh fixture in $T and sets $APP.
setup() {
  T=$(mktemp -d); APP="$T/guidy-app-main"; LOG="$T/log"; : > "$LOG"
  mkdir -p "$APP/tool" "$APP/android/app" "$APP/ios/Runner.xcodeproj" "$APP/ios/Pods" "$APP/ios/Flutter" \
           "$T/guidy-backend-main" "$T/bin" "$T/home/Library/Android/sdk/platform-tools" \
           "$T/home/Desktop" "$T/home/.gradle"
  cp -R "$SRC/tool/mac" "$SRC/tool/secrets_to_defines.py" "$APP/tool/"
  cp "$SRC"/Guidy*.command "$APP/"
  printf 'API_BASE_URL=http://192.168.1.9:8000/api\nMAPS_API_KEY_ANDROID=k\nANDROID_CERT_SHA1=PCSHA\n' > "$APP/secrets.properties"
  printf 'storeFile=x.jks\n' > "$APP/android/key.properties"
  printf 'DEVELOPMENT_TEAM = ABC;\n' > "$APP/ios/Runner.xcodeproj/project.pbxproj"
  touch "$T/guidy-backend-main/main.py"
  printf 'org.gradle.java.home=/jdk\n' > "$T/home/.gradle/gradle.properties"
  printf '%s' "$1" > "$T/devices.json"
  cat > "$T/bin/flutter" <<'F'
#!/bin/bash
echo "flutter $*" >> "$MOCKLOG"
case "$1" in
  devices) cat "$MOCKDIR/devices.json" ;;
  emulators) [ "${2:-}" = --launch ] || printf 'Id • Name • Manufacturer • Platform\n\npixel_emu • Pixel • Google • android\n' ;;
  build) [ -f build/dart_defines.json ] && sed 's/^/defines: /' build/dart_defines.json >> "$MOCKLOG"
         mkdir -p build/app/outputs/flutter-apk && echo apk > build/app/outputs/flutter-apk/app-release.apk ;;
esac
exit 0
F
  cat > "$T/home/Library/Android/sdk/platform-tools/adb" <<'F'
#!/bin/bash
echo "adb $*" >> "$MOCKLOG"; case "$*" in *" install "*) echo "${MOCK_ADB_INSTALL:-Success}" ;; esac
F
  printf '#!/bin/bash\necho "xcrun $*" >> "$MOCKLOG"\nexit "${MOCK_XCRUN_RC:-0}"\n' > "$T/bin/xcrun"
  printf '#!/bin/bash\necho "   interface: en0"\n' > "$T/bin/route"
  printf '#!/bin/bash\necho 10.0.0.5\n' > "$T/bin/ipconfig"
  printf '#!/bin/bash\nexit "${MOCK_CURL_RC:-0}"\n' > "$T/bin/curl"
  printf '#!/bin/bash\necho "open $*" >> "$MOCKLOG"\n' > "$T/bin/open"
  for c in xcodebuild pod keytool; do printf '#!/bin/bash\necho "%s $*" >> "$MOCKLOG"\n' "$c" > "$T/bin/$c"; done
  chmod +x "$T"/bin/* "$T/home/Library/Android/sdk/platform-tools/adb" "$APP"/*.command
}
run() { # $1 = launcher, $2 = stdin answers; extra env via ENV array
  (cd "$APP" && printf '%b' "$2" | env -i HOME="$T/home" PATH="$T/bin:/usr/bin:/bin" \
     MOCKLOG="$LOG" MOCKDIR="$T" "${ENV[@]+"${ENV[@]}"}" bash "$1" > "$T/out" 2>&1)
  RC=$?
}
PHONE='[{"name":"Pixel 7","id":"andr1","isSupported":true,"targetPlatform":"android-arm64","emulator":false},{"name":"My iPhone","id":"ios1","targetPlatform":"ios","emulator":false}]'
EMU='[{"name":"sdk phone","id":"emulator-5554","targetPlatform":"android-x64","emulator":true}]'
TWO_ANDROID='[{"name":"Pixel A","id":"a1","targetPlatform":"android-arm64","emulator":false},{"name":"Pixel B","id":"b2","targetPlatform":"android-arm64","emulator":false}]'
NONE='[]'

echo "== Android phone, backend on this Mac"
setup "$PHONE"; ENV=(); run "Guidy - 4 Install on Android.command" '1\n'
[ $RC = 0 ] && pass "exit 0" || { fail "exit $RC"; tail -20 "$T/out"; }
has "$LOG" '"API_BASE_URL": "http://10.0.0.5:8000/api"' "Mac IP baked into the build"
has "$LOG" '"ANDROID_CERT_SHA1": "PCSHA"' "cert SHA-1 from secrets.properties kept"
has "$LOG" 'flutter build apk --release --dart-define-from-file=build/dart_defines.json' "release APK built"
hasnt "$LOG" 'allowDebugSigningFallback' "real signing used when key.properties exists"
has "$LOG" 'adb -s andr1 reverse tcp:8000 tcp:8000' "USB tunnel set"
has "$LOG" 'adb -s andr1 install -r build/app/outputs/flutter-apk/app-release.apk' "APK installed on the phone"
has "$LOG" 'monkey -p com.guidy.guidy_app' "app launched"
[ -f "$T/home/Desktop/Guidy.apk" ] && pass "APK copied to Desktop" || fail "no Desktop copy"
rm -rf "$T"

echo "== Android emulator, backend not running yet"
setup "$EMU"; ENV=(MOCK_CURL_RC=0); run "Guidy - 4 Install on Android.command" '\n'
has "$LOG" '"API_BASE_URL": "http://10.0.2.2:8000/api"' "emulator uses 10.0.2.2"
hasnt "$LOG" 'reverse' "no USB tunnel for an emulator"
rm -rf "$T"
setup "$PHONE"; ENV=(MOCK_CURL_RC=7); ( sleep 2; sed -i 's/exit "${MOCK_CURL_RC:-0}"/exit 0/' "$T/bin/curl" ) &
run "Guidy - 4 Install on Android.command" '1\n'; wait
has "$LOG" 'open -a Terminal' "backend window opened when it was down"
has "$LOG" "guidy-backend-main/Start Backend.command" "the backend launcher is the one opened"
[ $RC = 0 ] && pass "continued once the backend answered" || fail "exit $RC"
rm -rf "$T"

echo "== Android: backend choices 2 and 3, device menu"
setup "$TWO_ANDROID"; ENV=(); run "Guidy - 4 Install on Android.command" '2\n2\n'
has "$LOG" '"API_BASE_URL": "http://192.168.1.9:8000/api"' "option 2 keeps the secrets.properties URL"
has "$LOG" 'adb -s b2 install' "second device picked from the menu"
rm -rf "$T"
setup "$PHONE"; ENV=(); run "Guidy - 4 Install on Android.command" '3\nhttps://api.example.com/api\n'
has "$LOG" '"API_BASE_URL": "https://api.example.com/api"' "option 3 uses the typed URL"
rm -rf "$T"
setup "$PHONE"; ENV=(); run "Guidy - 4 Install on Android.command" '3\nnot-a-url\n'
[ $RC != 0 ] && pass "a non-http URL is rejected" || fail "bad URL accepted"
hasnt "$LOG" 'flutter build' "nothing built after a bad URL"
rm -rf "$T"

echo "== Android: no key.properties, signature clash"
setup "$PHONE"; rm "$APP/android/key.properties"; ENV=(MOCK_ADB_INSTALL="Failure [INSTALL_FAILED_UPDATE_INCOMPATIBLE]")
run "Guidy - 4 Install on Android.command" '1\nn\n'
has "$LOG" '--android-project-arg=allowDebugSigningFallback=true' "debug-signing fallback requested"
[ $RC != 0 ] && pass "stops when the user declines the uninstall" || fail "exit $RC"
hasnt "$LOG" 'uninstall' "nothing uninstalled without consent"
rm -rf "$T"

echo "== Android: no device and no emulator"
setup "$NONE"; printf '#!/bin/bash\necho "flutter $*" >> "$MOCKLOG"; [ "$1" = devices ] && echo "[]"; exit 0\n' > "$T/bin/flutter"
ENV=(); run "Guidy - 4 Install on Android.command" '\n'
[ $RC != 0 ] && pass "exits non-zero" || fail "exit 0"
has "$T/out" "USB debugging" "tells the user how to enable USB debugging"
rm -rf "$T"

echo "== iPhone, backend on this Mac"
setup "$PHONE"; ENV=(); run "Guidy - 3 Install on iPhone.command" '1\n'
[ $RC = 0 ] && pass "exit 0" || { fail "exit $RC"; tail -20 "$T/out"; }
has "$LOG" 'flutter config --no-enable-swift-package-manager' "SPM disabled"
has "$LOG" 'flutter build ios --release --dart-define-from-file=build/dart_defines.json' "release build"
has "$LOG" '"API_BASE_URL": "http://10.0.0.5:8000/api"' "Mac IP baked into the build"
has "$LOG" 'xcrun devicectl device install app --device ios1 build/ios/iphoneos/Runner.app' "installed with devicectl"
has "$LOG" 'xcrun devicectl device process launch --device ios1 com.guidy.guidyApp' "launched"
hasnt "$LOG" 'flutter run' "no flutter run fallback needed"
rm -rf "$T"

echo "== iPhone: devicectl fails -> flutter run fallback"
setup "$PHONE"; ENV=(MOCK_XCRUN_RC=1); run "Guidy - 3 Install on iPhone.command" '1\n'
has "$LOG" 'flutter run --release -d ios1' "falls back to flutter run --release"
rm -rf "$T"

echo "== iPhone: no signing team"
setup "$PHONE"; : > "$APP/ios/Runner.xcodeproj/project.pbxproj"; ENV=(); run "Guidy - 3 Install on iPhone.command" '\n'
has "$LOG" 'open ios/Runner.xcworkspace' "Xcode opened for signing"
[ $RC != 0 ] && pass "stops while no team is saved" || fail "exit $RC"
hasnt "$LOG" 'flutter build' "nothing built without a team"
rm -rf "$T"

echo "== iPhone: none connected"
setup '[{"name":"Pixel 7","id":"andr1","targetPlatform":"android-arm64","emulator":false}]'
ENV=(); run "Guidy - 3 Install on iPhone.command" '\n'
[ $RC != 0 ] && pass "exits non-zero" || fail "exit 0"
has "$T/out" "Developer Mode" "tells the user about Developer Mode"
rm -rf "$T"

echo "== Start Backend launcher finds the sibling folder"
setup "$NONE"; printf '#!/bin/bash\necho ran-backend >> "$MOCKLOG"\n' > "$T/guidy-backend-main/run_backend.sh"
ENV=(); run "Guidy - 2 Start Backend.command" ''
has "$LOG" 'ran-backend' "backend run_backend.sh started"
rm -rf "$T"

echo
[ $fails = 0 ] && echo "all passed" || { echo "$fails failed"; exit 1; }
