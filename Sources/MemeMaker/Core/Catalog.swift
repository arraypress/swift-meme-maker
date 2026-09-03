//
//  Catalog.swift
//  MemeMaker
//
//  The 211 templates, and where their words go — bundled, so listing and
//  matching need no network at all.
//

import Foundation

/// The template catalogue.
///
/// The geometry ships **inside the library**, generated from memegen's own
/// `config.yml` files (MIT, © Jace Browning). That is 103 KB, and it means
/// `templates` and `find` work offline and instantly; only a background
/// image is fetched, once, the first time a template is actually used.
public enum Catalog {

    /// Every template, in id order.
    public static let all: [Template] = {
        guard let url = Bundle.module.url(forResource: "templates", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let templates = try? JSONDecoder().decode([Template].self, from: data) else {
            return []
        }
        return templates
    }()

    /// A template by its exact id.
    public static func template(_ id: String) throws -> Template {
        guard let found = all.first(where: { $0.id == id.lowercased() }) else {
            throw MemeError.unknownTemplate(id)
        }
        return found
    }

    /// Templates whose id, name or keywords contain the text.
    ///
    /// An exact id match comes first: searching `db` should give Distracted
    /// Boyfriend before every template with `db` somewhere in its name.
    public static func find(_ text: String) -> [Template] {
        let needle = text.lowercased().trimmingCharacters(in: .whitespaces)
        guard !needle.isEmpty else { return all }
        let matches = all.filter {
            $0.id.contains(needle)
            || $0.name.lowercased().contains(needle)
            || $0.keywords.contains { $0.lowercased().contains(needle) }
        }
        guard let exact = matches.firstIndex(where: { $0.id == needle }) else { return matches }
        var ordered = matches
        ordered.insert(ordered.remove(at: exact), at: 0)
        return ordered
    }
}
