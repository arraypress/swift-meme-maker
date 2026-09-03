//
//  BoxStyle.swift
//  MemeMaker
//

import Foundation

/// How a template wants its text cased.
public enum BoxStyle: String, Sendable, Codable {
    /// SHOUTED, which is the classic look and what most templates ask for.
    case upper
    /// As typed.
    case `default`
    /// As typed, and some templates use this to mean "leave it alone".
    case none
    /// aLtErNaTiNg — one template asks for it, and it is the whole joke.
    case mock
    /// A lighter face, used by a couple of templates.
    case thin

    public func apply(to text: String) -> String {
        switch self {
        case .upper: return text.uppercased()
        case .mock: return String(text.enumerated().map { $0.offset.isMultiple(of: 2)
            ? Character($0.element.lowercased()) : Character($0.element.uppercased()) })
        case .default, .none, .thin: return text
        }
    }
}

/// The typeface a template asks for.
public enum BoxFont: String, Sendable, Codable {
    case thick, thin, comic

    /// The macOS font that matches.
    ///
    /// Impact is what a meme is set in, and it ships with macOS — under
    /// `/System/Library/Fonts/Supplemental`, along with Comic Sans MS.
    public var familyName: String {
        switch self {
        case .thick: return "Impact"
        case .thin: return "Helvetica Neue"
        case .comic: return "Comic Sans MS"
        }
    }
}

/// Where the text sits inside its box.
public enum BoxAlign: String, Sendable, Codable {
    case center, left, right
}
