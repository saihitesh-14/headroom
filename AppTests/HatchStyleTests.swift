import CoreGraphics
import SwiftUI
import Testing
@testable import Headroom

/// Gate 14b (docs/REDESIGN-SPEC.md 6.2 item 1): the below-floor fill is the 16% status tint
/// with a 1 pt line at 45 degrees in the tint, on a 6 x 6 pt tile rendered once.
@Suite("Hatch")
struct HatchStyleTests {
    /// Premultiplied RGBA8 pixels of an image, row by row from the top.
    private struct Pixels {
        let width: Int, height: Int
        let bytes: [UInt8]

        init(_ image: CGImage) {
            width = image.width
            height = image.height
            var bytes = [UInt8](repeating: 0, count: width * height * 4)
            bytes.withUnsafeMutableBytes { buffer in
                let context = CGContext(
                    data: buffer.baseAddress, width: image.width, height: image.height, bitsPerComponent: 8,
                    bytesPerRow: image.width * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                )!
                context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
            }
            self.bytes = bytes
        }

        /// Alpha from 0 to 1 at (x, y), with y counted from the top.
        func alpha(_ x: Int, _ y: Int) -> Double {
            Double(bytes[(y * width + x) * 4 + 3]) / 255
        }

        /// Unpremultiplied red, green and blue from 0 to 1 at (x, y).
        func rgb(_ x: Int, _ y: Int) -> [Double] {
            let i = (y * width + x) * 4, a = Double(bytes[i + 3])
            return (0..<3).map { Double(bytes[i + $0]) / a }
        }
    }

    private let orange = Color.Resolved(red: 1, green: 0.5, blue: 0)

    @Test("the tile is 6 x 6 pt at the display scale")
    func tileSize() {
        let tile = HatchStyle.tile(orange, scale: 3)
        #expect(tile.width == 18)
        #expect(tile.height == 18)
        #expect(HatchStyle.tile(orange, scale: 2).width == 12)
    }

    @Test("a solid 45 degree line crosses a 16% tint, across the clearance ticks")
    func lineOverFill() {
        let pixels = Pixels(HatchStyle.tile(orange, scale: 3))
        // On the diagonal from top leading to bottom trailing (x == y in pixel centers), so the
        // hatch runs across the dimension ticks (bottom leading to top trailing), never along them.
        #expect(pixels.alpha(9, 9) > 0.95)
        #expect(pixels.alpha(0, 0) > 0.6)
        #expect(pixels.alpha(17, 17) > 0.6)
        // Off the diagonal the other way, and well clear of every line: the flat 16% tint.
        #expect(abs(pixels.alpha(8, 9) - pixels.alpha(9, 9)) < 0.02)
        #expect(pixels.alpha(9, 8) > 0.95)
        #expect(abs(pixels.alpha(2, 12) - 0.16) < 0.02)
        #expect(abs(pixels.alpha(14, 5) - 0.16) < 0.02)
        #expect(abs(pixels.alpha(4, 13) - 0.16) < 0.02)
        // Both are the tint.
        for (x, y) in [(9, 9), (2, 12)] {
            let rgb = pixels.rgb(x, y)
            #expect(abs(rgb[0] - 1) < 0.05 && abs(rgb[1] - 0.5) < 0.05 && rgb[2] < 0.05)
        }
    }

    @Test("tiles join without a seam")
    func seamless() {
        let pixels = Pixels(HatchStyle.tile(orange, scale: 3))
        let n = pixels.width
        // Moving one pixel along the line direction, wrapping at the edges, changes nothing.
        for y in 0..<n {
            for x in 0..<n {
                let next = pixels.alpha((x + 1) % n, (y + 1) % n)
                #expect(abs(pixels.alpha(x, y) - next) < 0.02, "pixel \(x), \(y)")
            }
        }
        // The other two corners are covered by the neighboring tiles' lines.
        #expect(pixels.alpha(0, n - 1) > 0.6)
        #expect(pixels.alpha(n - 1, 0) > 0.6)
    }

    @Test("the tile is rendered once per color and scale")
    func cached() {
        #expect(HatchStyle.tile(orange, scale: 3) === HatchStyle.tile(orange, scale: 3))
        #expect(HatchStyle.tile(orange, scale: 3) !== HatchStyle.tile(orange, scale: 2))
    }

    @Test("the status tint is resolved for light and dark")
    @MainActor
    func followsAppearance() {
        var light = EnvironmentValues()
        light.colorScheme = .light
        light.displayScale = 3
        var dark = light
        dark.colorScheme = .dark
        let lightTile = Pixels(HatchStyle.tile(for: Theme.warning, in: light))
        let darkTile = Pixels(HatchStyle.tile(for: Theme.warning, in: dark))
        let lightInk = lightTile.rgb(9, 9), darkInk = darkTile.rgb(9, 9)
        let expectedLight = Theme.warning.resolve(in: light), expectedDark = Theme.warning.resolve(in: dark)
        #expect(abs(lightInk[0] - Double(expectedLight.red)) < 0.03)
        #expect(abs(darkInk[0] - Double(expectedDark.red)) < 0.03)
        #expect(abs(lightInk[0] - darkInk[0]) > 0.2)
    }
}
