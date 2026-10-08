import XCTest

final class NgonExampleTests: XCTestCase {
    private let colors = [
        (231, 111, 81), (233, 196, 106), (42, 157, 143), (69, 123, 157),
        (144, 103, 198), (239, 71, 111), (17, 138, 178), (6, 214, 160)
    ]

    func testPluginRendersNativeExampleStyle() throws {
        let app = XCUIApplication()
        app.launch()
        // Visible polygon colors prove that registration and custom rendering work
        // without adding status text or test-only controls to the app.
        let rendered = NSPredicate { _, _ in
            guard let counts = try? self.polygonPixelCounts(in: app.screenshot()) else { return false }
            return counts.allSatisfy { $0 > 200 }
        }
        expectation(for: rendered, evaluatedWith: nil)
        waitForExpectations(timeout: 30)

        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "ngon polygons from the plugin-enabled MapLibre package"
        attachment.lifetime = .keepAlways
        add(attachment)
        let counts = try polygonPixelCounts(in: screenshot)
        for (color, count) in zip(colors, counts) {
            XCTAssertGreaterThan(count, 200, "Missing polygon color RGB\(color)")
        }
    }

    private func polygonPixelCounts(in screenshot: XCUIScreenshot) throws -> [Int] {
        let image = try XCTUnwrap(screenshot.image.cgImage)
        let width = image.width
        let height = image.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        try pixels.withUnsafeMutableBytes { buffer in
            let context = try XCTUnwrap(CGContext(
                data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8,
                bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
            ))
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        }
        return colors.map { red, green, blue in
            var count = 0
            for offset in stride(from: 0, to: pixels.count, by: 4) {
                if abs(Int(pixels[offset]) - red) < 15,
                   abs(Int(pixels[offset + 1]) - green) < 15,
                   abs(Int(pixels[offset + 2]) - blue) < 15 {
                    count += 1
                }
            }
            return count
        }
    }
}
