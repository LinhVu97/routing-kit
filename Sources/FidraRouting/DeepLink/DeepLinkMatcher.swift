//
//  DeepLinkMatcher.swift
//  FidraRouting
//

import Foundation

enum DeepLinkMatcher {

    private enum PathSegment: Equatable {
        case literal(String)
        case placeholder(String)
    }

    private struct ParsedPattern {
        let scheme: String?
        let host: String?
        let pathSegments: [PathSegment]
        let queryParams: [String: String]
    }

    static func match(url: URL, pattern: String) -> DeepLinkArguments? {
        guard let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let parsed = parsePattern(pattern) else {
            return nil
        }

        if let scheme = parsed.scheme {
            guard url.scheme?.caseInsensitiveCompare(scheme) == .orderedSame else { return nil }
        }

        if let host = parsed.host {
            guard urlComponents.host?.caseInsensitiveCompare(host) == .orderedSame else { return nil }
        }

        let urlPathSegments = urlComponents.path
            .split(separator: "/")
            .map(String.init)
            .filter { !$0.isEmpty }

        guard urlPathSegments.count == parsed.pathSegments.count else { return nil }

        var pathArguments: [String: String] = [:]

        for (urlSegment, patternSegment) in zip(urlPathSegments, parsed.pathSegments) {
            switch patternSegment {
            case .literal(let literal):
                guard urlSegment == literal else { return nil }
            case .placeholder(let name):
                pathArguments[name] = urlSegment
            }
        }

        let urlQueryItems = Dictionary(
            uniqueKeysWithValues: (urlComponents.queryItems ?? []).map { ($0.name, $0.value ?? "") }
        )

        var queryArguments: [String: String] = [:]

        for (key, patternValue) in parsed.queryParams {
            guard let actualValue = urlQueryItems[key] else { return nil }

            if patternValue.hasPrefix("{"), patternValue.hasSuffix("}"), patternValue.count > 2 {
                let name = String(patternValue.dropFirst().dropLast())
                queryArguments[name] = actualValue
            } else if actualValue != patternValue {
                return nil
            }
        }

        return DeepLinkArguments(path: pathArguments, query: queryArguments)
    }

    private static func parsePattern(_ pattern: String) -> ParsedPattern? {
        var remaining = pattern.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !remaining.isEmpty else { return nil }

        var scheme: String?
        var host: String?
        var pathSegments: [PathSegment] = []
        var queryParams: [String: String] = [:]

        if let schemeRange = remaining.range(of: "://") {
            scheme = String(remaining[..<schemeRange.lowerBound])
            remaining = String(remaining[schemeRange.upperBound...])
        }

        if let queryIndex = remaining.firstIndex(of: "?") {
            let queryString = String(remaining[remaining.index(after: queryIndex)...])
            remaining = String(remaining[..<queryIndex])
            queryParams = parseQueryString(queryString)
        }

        let parts = remaining
            .split(separator: "/")
            .map(String.init)
            .filter { !$0.isEmpty }

        if scheme != nil {
            if let first = parts.first {
                host = first
                pathSegments = parts.dropFirst().map(parseSegment)
            }
        } else if !parts.isEmpty {
            pathSegments = parts.map(parseSegment)
        }

        return ParsedPattern(
            scheme: scheme,
            host: host,
            pathSegments: pathSegments,
            queryParams: queryParams
        )
    }

    private static func parseSegment(_ segment: String) -> PathSegment {
        if segment.hasPrefix("{"), segment.hasSuffix("}"), segment.count > 2 {
            return .placeholder(String(segment.dropFirst().dropLast()))
        }
        return .literal(segment)
    }

    private static func parseQueryString(_ queryString: String) -> [String: String] {
        queryString
            .split(separator: "&")
            .reduce(into: [:]) { result, pair in
                let components = pair.split(separator: "=", maxSplits: 1).map(String.init)
                guard let key = components.first else { return }
                result[key] = components.count > 1 ? components[1] : ""
            }
    }
}
