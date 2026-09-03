//
//  Palette.swift
//  MemeMaker
//
//  The handful of colour names the templates actually use, plus hex.
//

import CoreGraphics
import Foundation

/// Turning a template's colour into a drawable one.
enum Palette {

    /// Only the names that appear in the catalogue, rather than all 148 CSS
    /// colours — everything else falls back to white, which is what a meme
    /// is set in and never looks like a bug.
    private static let named: [String: (Double, Double, Double)] = [
        "white": (1, 1, 1),
        "black": (0, 0, 0),
        "khaki": (0.941, 0.902, 0.549),
        "palegoldenrod": (0.933, 0.910, 0.667),
        "gray": (0.5, 0.5, 0.5),
        "grey": (0.5, 0.5, 0.5),
        "red": (1, 0, 0),
        "yellow": (1, 1, 0),
    ]

    static func color(_ value: String) -> CGColor {
        let text = value.trimmingCharacters(in: CharacterSet(charactersIn: " '\"")).lowercased()
        if text.hasPrefix("#"), let rgb = hex(text) {
            return CGColor(red: rgb.0, green: rgb.1, blue: rgb.2, alpha: 1)
        }
        let rgb = named[text] ?? (1, 1, 1)
        return CGColor(red: rgb.0, green: rgb.1, blue: rgb.2, alpha: 1)
    }

    /// The outline. Black on light text, white on dark — because a black
    /// outline around black letters is just a fatter black letter.
    static func outline(for value: String) -> CGColor {
        let text = value.trimmingCharacters(in: CharacterSet(charactersIn: " '\"")).lowercased()
        let rgb = text.hasPrefix("#") ? (hex(text) ?? (1, 1, 1)) : (named[text] ?? (1, 1, 1))
        let brightness = 0.299 * rgb.0 + 0.587 * rgb.1 + 0.114 * rgb.2
        return brightness < 0.4 ? CGColor(red: 1, green: 1, blue: 1, alpha: 1)
                                : CGColor(red: 0, green: 0, blue: 0, alpha: 1)
    }

    static func hex(_ text: String) -> (Double, Double, Double)? {
        var digits = text.dropFirst()
        if digits.count == 3 {
            digits = Substring(digits.flatMap { [$0, $0] })
        }
        guard digits.count == 6, let value = UInt32(digits, radix: 16) else { return nil }
        return (Double((value >> 16) & 0xff) / 255,
                Double((value >> 8) & 0xff) / 255,
                Double(value & 0xff) / 255)
    }
}
