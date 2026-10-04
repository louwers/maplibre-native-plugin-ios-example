import XCTest

final class NgonExampleTests: XCTestCase {
    func testPluginRegistersAndRendersAllThreePolygons() throws {
        let app = XCUIApplication()
        app.launch()
        let registered = app.staticTexts["registration-status"]
        XCTAssertTrue(registered.waitForExistence(timeout: 20))
        XCTAssertEqual(registered.label, "Plugin registered")
        let rendered = app.staticTexts["render-status"]
        let ready = NSPredicate(format: "label == %@", "Map rendered")
        expectation(for: ready, evaluatedWith: rendered)
        waitForExpectations(timeout: 30)

        // A successful style load alone cannot prove that a custom layer drew.
        // Require pixels from every polygon; no other UI uses these colors.
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "ngon polygons from local XCFramework"
        attachment.lifetime = .keepAlways
        add(attachment)
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
        let colors = [(249, 115, 22), (6, 182, 212), (236, 72, 153)]
        for (red, green, blue) in colors {
            var count = 0
            for offset in stride(from: 0, to: pixels.count, by: 4) {
                if abs(Int(pixels[offset]) - red) < 15,
                   abs(Int(pixels[offset + 1]) - green) < 15,
                   abs(Int(pixels[offset + 2]) - blue) < 15 {
                    count += 1
                }
            }
            XCTAssertGreaterThan(count, 200, "Missing polygon color RGB(\(red), \(green), \(blue))")
        }
    }
}
