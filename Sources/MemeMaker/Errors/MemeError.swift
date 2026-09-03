//
//  MemeError.swift
//  MemeMaker
//

import Foundation

public enum MemeError: Error, LocalizedError, Equatable {

    case unknownTemplate(String)
    case tooManyLines(given: Int, template: String, takes: Int)
    case unreadableImage(String)
    case cannotWrite(String)
    case download(String, code: Int)
    case noFont(String)

    public var errorDescription: String? {
        switch self {
        case let .unknownTemplate(id):
            return "no template called \(id)"
        case let .tooManyLines(given, template, takes):
            return "\(template) takes \(takes) line\(takes == 1 ? "" : "s"), got \(given)"
        case let .unreadableImage(path):
            return "could not read \(path) as an image"
        case let .cannotWrite(path):
            return "could not write \(path)"
        case let .download(what, code):
            return "could not fetch \(what) — HTTP \(code)"
        case let .noFont(name):
            return "the font \(name) is not installed"
        }
    }
}
