//
//  Template.swift
//  MemeMaker
//

//

import Foundation

/// One meme template: its name, and where its words go.
public struct Template: Sendable, Codable, Identifiable, Equatable {

    /// The memegen slug — `drake`, `fry`.
    public let id: String
    /// What the template is called.
    public let name: String
    /// Where the meme came from, usually Know Your Meme.
    public let source: String?
    /// Other words that should find it in a search.
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
