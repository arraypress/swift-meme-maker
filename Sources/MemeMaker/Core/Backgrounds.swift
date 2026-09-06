//
//  Backgrounds.swift
//  MemeMaker
//
//  The one thing that is not local: the picture itself, fetched once.
//

import CoreGraphics
import Foundation

/// Template backgrounds, cached on disk.
///
/// The images belong to whoever made the memes, so they are not bundled —
/// fetched from memegen.link the first time a template is used, and kept.
/// Everything after that first fetch is offline.
public struct Backgrounds: Sendable {

    /// Where downloaded backgrounds are cached.
    public let directory: URL

    public init(directory: URL) {
        self.directory = directory
    }

    /// Where a template's background lives once fetched.
    public func location(for template: Template) -> URL {
        directory.appendingPathComponent("\(template.id).png")
    }

    /// Whether it is already on disk.
    public func isCached(_ template: Template) -> Bool {
        FileManager.default.fileExists(atPath: location(for: template).path)
    }

    /// The background, from the cache or the network.
    public func image(
        for template: Template,
        session: URLSession = .shared,
        onFetch: (() -> Void)? = nil
    ) async throws -> CGImage {

        let file = location(for: template)
        if FileManager.default.fileExists(atPath: file.path),
           let cached = try? MemeRenderer.image(at: file) {
            return cached
        }

        onFetch?()
        let (data, response) = try await session.data(from: template.backgroundURL)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw MemeError.download("the \(template.name) background", code: http.statusCode)
        }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try data.write(to: file, options: .atomic)

        /// Read back rather than decoded from the bytes in hand, so a
        /// corrupt download fails here and not on the next run, when the
        /// cause would be nowhere in sight.
        guard let image = try? MemeRenderer.image(at: file) else {
            try? FileManager.default.removeItem(at: file)
            throw MemeError.unreadableImage(template.backgroundURL.absoluteString)
        }
        return image
    }
}
