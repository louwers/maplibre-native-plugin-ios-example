# MapLibre Native iOS plugin example

A small UIKit app that builds the copied ngon C++ plugin and registers it with
the public C API in a locally built `MapLibreWithPlugins.xcframework`.
The bundled style draws an orange triangle, a cyan pentagon, and a pink octagon
on a dark background. It needs no network connection or API key.

## Build the XCFramework

Use Xcode and Bazelisk on macOS. The native checkout must include the
`MapLibre.dynamic.plugins` target, plugin entry-point retention, and Darwin
style-layer wrapper fixes on `codex/ios-plugin-distribution` (tested at commit
`bfd26e3feabd2227a32c634814396539979a7110`). Initialize its submodules before building:

```sh
git -C /path/to/maplibre-native submodule update --init --recursive
./scripts/build-xcframework.sh /path/to/maplibre-native
```

The script uses the release workflow's Metal, plugins, optimization, stripping,
and ThinLTO options. It checks the public header and exported registration symbol
for iOS arm64 and simulator arm64/x86_64 before installing the framework into
`Frameworks/`. The source revision, local changes, and archive checksum are
recorded alongside it. Framework binaries are ignored by Git.

## Run the app

Open `NgonExample.xcodeproj`, select the `NgonExample` scheme and an iOS simulator,
then Run. For a device, choose your development team in Signing & Capabilities.
The app reports `Plugin registered` followed by `Map rendered`; all three
polygons should be visible.

The Xcode project compiles `Ngon/shared/cpp/ngon_layer.cpp` directly into the app
and embeds the local XCFramework. `App/main.mm` calls
`mln_ngon_layer_register(&mln_plugin_register_v1, ...)` before creating a map.
The small `Support/mln/plugin/plugin_api.h` shim forwards the original plugin
include path to the XCFramework's public header. No MapLibre core source or
private headers are used to build the app.

## Verify end to end

```sh
xcrun simctl list devices available
./scripts/test.sh SIMULATOR_UDID
```

The UI test checks registration, waits for rendering, and requires pixels from
each of the three polygons. It retains a screenshot in `build/*.xcresult`.
The test fails if registration succeeds but the custom layer does not draw.

## Copied plugin source

`Ngon/shared/cpp/ngon_layer.cpp`, `Ngon/shared/include/ngon_layer.hpp`, and
`Ngon/scripts/generate-shaders.mjs` are unchanged copies from
`maplibre/maplibre-native` at commit
`307f59b8883c52f270b9039d61ee1a33bf7d339f`, under `plugins/ngon-layer/`.
The generated shader header is checked in so building the app needs only Xcode.
Regenerate it after changing the shader generator:

```sh
node Ngon/scripts/generate-shaders.mjs --output Ngon/generated/ngon_shader_sources.hpp
```

The Xcode project is checked in. To regenerate it, install the `xcodeproj` Ruby
gem and run `ruby scripts/generate-project.rb`.

## Validation status

Verified with Xcode 27.0 (27A266a), the iOS 27.0 SDK, and an iPhone 17 Pro
simulator running iOS 26.4:

- Built the complete release XCFramework with plugins, Metal, ThinLTO, and stripping.
- Verified the public plugin header and registration export for device arm64
  and simulator arm64/x86_64.
- Built the app for both an iOS device (Release, without signing) and the
  simulator, using only that XCFramework and the copied plugin source.
- Passed `testPluginRegistersAndRendersAllThreePolygons`: registration, completed
  map rendering, and visible pixels from all three polygon colors.

The SDK also wraps runtime plugin layers for the Objective-C style interface,
so accessibility can enumerate the map's layers without a nil-layer exception.

![The simulator app rendering an orange triangle, cyan pentagon, and pink octagon](docs/ngon-simulator.png)
