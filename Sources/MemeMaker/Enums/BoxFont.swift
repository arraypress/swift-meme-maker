//
//  BoxFont.swift
//  MemeMaker
//

//

import Foundation

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
