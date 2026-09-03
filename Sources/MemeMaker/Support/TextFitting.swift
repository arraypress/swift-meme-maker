//
//  TextFitting.swift
//  MemeMaker
//
//  Breaking a line of text so it fills its box and no more.
//

import CoreGraphics
import CoreText
import Foundation

/// Wrapping and shrinking text to fit a rectangle.
///
/// Pure and separated from the drawing so the awkward cases — a word longer
/// than the box, an empty line, text that cannot fit at any size — can be
/// tested without rendering anything.
public enum TextFitting {

    /// The lines and the point size that fill `box` as fully as possible.
    ///
    /// The search runs downwards from a size the box could not possibly hold,
    /// which is how a meme is set: as big as it goes. It stops at 8 points
    /// rather than shrinking to nothing, because text too small to read is
    /// not a better outcome than text that slightly overflows.
    public static func fit(
        _ text: String,
        in box: CGSize,
        font: CTFont,
        maximum: Double? = nil,
        minimum: Double = 8
    ) -> (lines: [String], size: Double) {

        let words = text.split(whereSeparator: \.isWhitespace).map(String.init)
        guard !words.isEmpty else { return ([], minimum) }

        var size = maximum ?? box.height
        while size > minimum {
            let sized = CTFontCreateCopyWithAttributes(font, size, nil, nil)
            let lines = wrap(words, into: box.width, font: sized)
            /// The font's own ascent and descent, not a fraction of the point
            /// size. Impact's ascent is 0.89 em where a naive 0.8 would put
            /// the first line three pixels above the box and shear the tops
            /// off every capital — which is exactly what it did.
            if Double(lines.count) * lineHeight(sized) <= box.height,
               lines.allSatisfy({ width(of: $0, font: sized) <= box.width }) {
                return (lines, size)
            }
            size -= max(1, (size * 0.06).rounded())
        }
        let sized = CTFontCreateCopyWithAttributes(font, minimum, nil, nil)
        return (wrap(words, into: box.width, font: sized), minimum)
    }

    /// Greedy word wrap. A word wider than the box gets a line to itself
    /// rather than being cut in half — the shrink loop deals with it.
    static func wrap(_ words: [String], into width: Double, font: CTFont) -> [String] {
        var lines: [String] = []
        var current = ""
        for word in words {
            let candidate = current.isEmpty ? word : current + " " + word
            if current.isEmpty || self.width(of: candidate, font: font) <= width {
                current = candidate
            } else {
                lines.append(current)
                current = word
            }
        }
        if !current.isEmpty { lines.append(current) }
        return lines
    }

    /// Ascent plus descent: the space one line actually occupies.
    ///
    /// The font's own leading is left out — Impact reports enough of it to
    /// open a gap that reads as a missing line in a two-line caption.
    public static func lineHeight(_ font: CTFont) -> Double {
        CTFontGetAscent(font) + CTFontGetDescent(font)
    }

    /// The width of a string set in a font.
    public static func width(of text: String, font: CTFont) -> Double {
        let line = CTLineCreateWithAttributedString(
            CFAttributedStringCreate(nil, text as CFString,
                                     [kCTFontAttributeName: font] as CFDictionary)!)
        return CTLineGetTypographicBounds(line, nil, nil, nil)
    }
}
