//
//  MemeRenderer.swift
//  MemeMaker
//
//  Impact, white, black outline. Drawn here, on this machine.
//

import CoreGraphics
import CoreText
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Setting text into an image the way a meme is set.
public enum MemeRenderer {

    /// Draws the lines into their boxes.
    ///
    /// - Parameter boxes: one per line. Extra lines are refused rather than
    ///   dropped, because silently losing the punchline is worse than
    ///   refusing to draw it.
    public static func render(
        _ background: CGImage,
        lines: [String],
        boxes: [TextBox],
        outlineWidth: Double = 1.0
    ) throws -> CGImage {

        guard lines.count <= boxes.count else {
            throw MemeError.tooManyLines(given: lines.count, template: "this image", takes: boxes.count)
        }

        let width = background.width, height = background.height
        guard let context = CGContext(
            data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            throw MemeError.cannotWrite("the canvas")
        }
        context.draw(background, in: CGRect(x: 0, y: 0, width: width, height: height))

        let size = CGSize(width: width, height: height)
        for (text, box) in zip(lines, boxes) where !text.trimmingCharacters(in: .whitespaces).isEmpty {
            try draw(box.style.apply(to: text), in: box, on: context,
                     imageSize: size, outlineWidth: outlineWidth)
        }

        guard let image = context.makeImage() else { throw MemeError.cannotWrite("the meme") }
        return image
    }

    private static func draw(_ text: String, in box: TextBox, on context: CGContext,
                             imageSize: CGSize, outlineWidth: Double) throws {

        guard let font = font(named: box.font.familyName) else {
            throw MemeError.noFont(box.font.familyName)
        }
        let rect = box.rect(in: imageSize)
        let (lines, size) = TextFitting.fit(text, in: rect.size, font: font)
        guard !lines.isEmpty else { return }

        let sized = CTFontCreateCopyWithAttributes(font, size, nil, nil)
        let lineHeight = TextFitting.lineHeight(sized)
        let ascent = CTFontGetAscent(sized)
        let block = lineHeight * Double(lines.count)

        context.saveGState()
        defer { context.restoreGState() }

        if box.angle != 0 {
            let centre = CGPoint(x: rect.midX, y: imageSize.height - rect.midY)
            context.translateBy(x: centre.x, y: centre.y)
            /// Negated: the catalogue measures clockwise, CoreGraphics does
            /// not, and a tilted caption leaning the wrong way is obvious.
            context.rotate(by: -box.angle * .pi / 180)
            context.translateBy(x: -centre.x, y: -centre.y)
        }

        /// The colours go in the attributed string, NOT on the context.
        /// `CTLineDraw` ignores `setFillColor` and defaults to black, which
        /// is how the first version of this drew solid black letters with a
        /// black outline and looked, at a glance, like a font problem.
        ///
        /// A negative `kCTStrokeWidthAttributeName` means fill *and* stroke
        /// in one pass, as a percentage of the point size — so the outline
        /// stays proportional however far the text has been shrunk.
        let attributes: [CFString: Any] = [
            kCTFontAttributeName: sized,
            kCTForegroundColorAttributeName: Palette.color(box.color),
            kCTStrokeColorAttributeName: Palette.outline(for: box.color),
            kCTStrokeWidthAttributeName: -5.0 * outlineWidth,
        ]

        /// The block is centred vertically in the box, which is what stops a
        /// one-line caption sitting against the top edge of a two-line box.
        let top = rect.minY + (rect.height - block) / 2

        for (index, line) in lines.enumerated() {
            let attributed = CFAttributedStringCreate(
                nil, line as CFString, attributes as CFDictionary)!
            let typeset = CTLineCreateWithAttributedString(attributed)
            let lineWidth = CTLineGetTypographicBounds(typeset, nil, nil, nil)

            let x: Double
            switch box.align {
            case .center: x = rect.minX + (rect.width - lineWidth) / 2
            case .left: x = rect.minX
            case .right: x = rect.maxX - lineWidth
            }
            /// Flipped: the catalogue counts down from the top, CoreGraphics
            /// counts up from the bottom. The baseline sits an ascent below
            /// the line's top edge, measured from the font rather than
            /// guessed from the point size.
            let y = imageSize.height - (top + Double(index) * lineHeight + ascent)

            context.textPosition = CGPoint(x: x, y: y)
            CTLineDraw(typeset, context)
        }
    }

    /// Impact and Comic Sans MS ship with macOS but are not always registered
    /// by family name alone, so the file is loaded directly as a fallback.
    static func font(named family: String) -> CTFont? {
        let descriptor = CTFontDescriptorCreateWithAttributes(
            [kCTFontFamilyNameAttribute: family as CFString] as CFDictionary)
        let font = CTFontCreateWithFontDescriptor(descriptor, 100, nil)
        if (CTFontCopyFamilyName(font) as String) == family { return font }

        for name in ["\(family).ttf", "\(family) Bold.ttf"] {
            let url = URL(fileURLWithPath: "/System/Library/Fonts/Supplemental/\(name)")
            guard FileManager.default.fileExists(atPath: url.path),
                  let descriptors = CTFontManagerCreateFontDescriptorsFromURL(url as CFURL)
                    as? [CTFontDescriptor], let first = descriptors.first else { continue }
            return CTFontCreateWithFontDescriptor(first, 100, nil)
        }
        return nil
    }

    // MARK: - Files

    /// Reads an image off disk.
    public static func image(at url: URL) throws -> CGImage {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw MemeError.unreadableImage(url.path)
        }
        return image
    }

    /// Writes one, PNG or JPEG by the extension.
    public static func write(_ image: CGImage, to url: URL, quality: Double = 0.92) throws {
        let type: UTType = ["jpg", "jpeg"].contains(url.pathExtension.lowercased()) ? .jpeg : .png
        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL, type.identifier as CFString, 1, nil) else {
            throw MemeError.cannotWrite(url.path)
        }
        CGImageDestinationAddImage(destination, image,
                                   [kCGImageDestinationLossyCompressionQuality: quality] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { throw MemeError.cannotWrite(url.path) }
    }
}
