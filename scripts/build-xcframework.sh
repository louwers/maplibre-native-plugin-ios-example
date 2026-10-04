#!/bin/bash
set -euo pipefail
if [[ $# != 1 ]]; then
    echo "Usage: $0 /path/to/maplibre-native" >&2
    exit 2
fi
example_root="$(cd "$(dirname "$0")/.." && pwd)"
native_root="$(cd "$1" && pwd)"
cd "$native_root"
options=(
    --compilation_mode=opt --features=dead_strip,thin_lto
    --objc_enable_binary_stripping --apple_generate_dsym
    --//:renderer=metal --//:plugins=true
    "--embed_label=maplibre_ios_$(cat platform/ios/VERSION)"
)
target=//platform/ios:MapLibre.dynamic.plugins
bazel build "${options[@]}" --output_groups=+dsyms "$target"
archive="$(bazel info execution_root)/$(bazel cquery "${options[@]}" --output=files "$target")"
staging="$(mktemp -d)"
trap 'rm -rf "$staging"' EXIT
unzip -q "$archive" -d "$staging"
python3 platform/ios/scripts/verify-plugin-xcframework.py "$staging/MapLibreWithPlugins.xcframework"
mkdir -p "$example_root/Frameworks"
rm -rf "$example_root/Frameworks/MapLibreWithPlugins.xcframework"
mv "$staging/MapLibreWithPlugins.xcframework" "$example_root/Frameworks/"
git rev-parse HEAD > "$example_root/Frameworks/native-revision.txt"
git diff --binary HEAD > "$example_root/Frameworks/native-changes.patch"
shasum -a 256 "$archive" > "$example_root/Frameworks/archive-sha256.txt"
echo "Installed locally built MapLibreWithPlugins.xcframework in $example_root/Frameworks"
