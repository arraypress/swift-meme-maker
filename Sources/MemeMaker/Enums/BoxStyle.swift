//
//  BoxStyle.swift
//  MemeMaker
//

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

    /// The text as this style writes it.
    public func apply(to text: String) -> String {
        switch self {
        case .upper: return text.uppercased()
        case .mock: return String(text.enumerated().map { $0.offset.isMultiple(of: 2)
            ? Character($0.element.lowercased()) : Character($0.element.uppercased()) })
        case .default, .none, .thin: return text
        }
    }
}
