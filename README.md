# MapLibre Native iOS plugin example

A small UIKit app that builds the copied ngon C++ plugin and registers it with
the public C API in the published `MapLibreWithPlugins` Swift package.
The bundled style draws an orange triangle, a cyan pentagon, and a pink octagon
on a dark background. Running the app needs no network connection or API key.

## Swift package dependency

The app uses the `MapLibreWithPlugins` product from the
[MapLibre package on Swift Package Index](https://swiftpackageindex.com/maplibre/maplibre-gl-native-distribution).
The Xcode project pins the published prerelease **`7.0.0-pre0`** from
`https://github.com/maplibre/maplibre-gl-native-distribution.git`.
`Package.resolved` records its source revision.

Xcode downloads and embeds the published XCFramework through Swift Package
Manager. Building requires Xcode on macOS and an internet connection for the
initial package download. No native SDK checkout or Bazel build is required.

## Run the app

Open `NgonExample.xcodeproj`, select the `NgonExample` scheme and an iOS simulator,
wait for package resolution, then Run. For a device, choose your development
team in Signing & Capabilities.
The app reports `Plugin registered` followed by `Map rendered`; all three
polygons should be visible.

The Xcode project compiles `Ngon/shared/cpp/ngon_layer.cpp` directly into the app
and links the `MapLibreWithPlugins` package product. `App/main.mm` calls
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

- Resolved the published `MapLibreWithPlugins` product at
  [`7.0.0-pre0`](https://github.com/maplibre/maplibre-gl-native-distribution/releases/tag/7.0.0-pre0)
  through Swift Package Manager using a fresh build directory.
- Built the app for the simulator and an iOS device (Release, without signing).
- Passed `testPluginRegistersAndRendersAllThreePolygons`: registration, completed
  map rendering, and visible pixels from all three polygon colors.

The SDK also wraps runtime plugin layers for the Objective-C style interface,
so accessibility can enumerate the map's layers without a nil-layer exception.

![The simulator app rendering an orange triangle, cyan pentagon, and pink octagon](docs/ngon-simulator.png)
