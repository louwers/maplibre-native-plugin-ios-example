#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ ! -d Frameworks/MapLibreWithPlugins.xcframework ]]; then
    echo 'First run scripts/build-xcframework.sh /path/to/maplibre-native' >&2
    exit 1
fi
if [[ $# != 1 ]]; then
    echo "Usage: $0 SIMULATOR_UDID (see: xcrun simctl list devices available)" >&2
    exit 2
fi
mkdir -p build
result="build/NgonExample-$(date +%Y%m%d-%H%M%S).xcresult"
xcodebuild test -project NgonExample.xcodeproj -scheme NgonExample \
    -destination "platform=iOS Simulator,id=$1" \
    -derivedDataPath build/DerivedData -resultBundlePath "$result" \
    CODE_SIGNING_ALLOWED=NO
echo "Registration checks and polygon screenshot: $result"
