//
//  TextBox.swift
//  MemeMaker
//

//

import CoreGraphics
import Foundation

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
    /// How the line sits across its box.
    public let align: BoxAlign
    /// A colour name or `#rrggbb`.
    public let color: String
    /// Which face it is set in.
    public let font: BoxFont
    /// Casing applied before drawing — most memes are upper case.
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
