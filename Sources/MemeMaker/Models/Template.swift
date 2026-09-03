//
//  Template.swift
//  MemeMaker
//

import Foundation

/// One meme template: its name, and where its words go.
public struct Template: Sendable, Codable, Identifiable, Equatable {

    public let id: String
    public let name: String
    /// Where the meme came from, usually Know Your Meme.
    public let source: String?
    public let keywords: [String]
    /// The wording the catalogue ships as an illustration.
    public let example: [String]
    /// One per line of text the template takes, in order.
    public let boxes: [TextBox]

    /// How many lines this template expects.
    public var lines: Int { boxes.count }

    /// The background, served by memegen.link and cached on first use.
    public var backgroundURL: URL {
        URL(string: "https://api.memegen.link/images/\(id).png")!
    }
}

/// Where one line of text goes, in fractions of the image.
///
/// Fractions rather than pixels so the same geometry works whatever size the
/// background turns out to be — memegen serves several.
public struct TextBox: Sendable, Codable, Equatable {

    /// Left edge, 0–1.
    public let anchorX: Double
    /// Top edge, 0–1.
    public let anchorY: Double
    /// Width, 0–1.
    public let scaleX: Double
    /// Height, 0–1.
    public let scaleY: Double
    public let align: BoxAlign
    /// A colour name or `#rrggbb`.
    public let color: String
    public let font: BoxFont
    public let style: BoxStyle
    /// Degrees, clockwise. Most are zero; a few are deliberately askew.
    public let angle: Double

    public init(anchorX: Double, anchorY: Double, scaleX: Double, scaleY: Double,
                align: BoxAlign = .center, color: String = "white",
                font: BoxFont = .thick, style: BoxStyle = .upper, angle: Double = 0) {
        self.anchorX = anchorX
        self.anchorY = anchorY
        self.scaleX = scaleX
        self.scaleY = scaleY
        self.align = align
        self.color = color
        self.font = font
        self.style = style
        self.angle = angle
    }

    /// The classic pair: shouted across the top and the bottom, for an image
    /// that came from somewhere other than the catalogue.
    public static let topAndBottom = [
        TextBox(anchorX: 0.03, anchorY: 0.02, scaleX: 0.94, scaleY: 0.22),
        TextBox(anchorX: 0.03, anchorY: 0.76, scaleX: 0.94, scaleY: 0.22),
    ]

    /// The rectangle this box covers in an image of a given size.
    public func rect(in size: CGSize) -> CGRect {
        CGRect(x: anchorX * size.width, y: anchorY * size.height,
               width: scaleX * size.width, height: scaleY * size.height)
    }
}
