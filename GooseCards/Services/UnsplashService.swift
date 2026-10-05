import Foundation

struct UnsplashPhoto: Identifiable, Decodable {
    let id: String
    let altDescription: String?
    let urls: Urls
    let user: User

    struct Urls: Decodable {
        let thumb: String
        let small: String
        let regular: String
    }

    struct User: Decodable {
        let name: String
    }

    enum CodingKeys: String, CodingKey {
        case id
        case altDescription = "alt_description"
        case urls
        case user
    }
}

private struct UnsplashSearchResponse: Decodable {
    let results: [UnsplashPhoto]
}

enum UnsplashError: LocalizedError {
    case missingKey
    case badResponse

    var errorDescription: String? {
        switch self {
        case .missingKey:
            return "No Unsplash API key configured. Add one to Services/Secrets.swift."
        case .badResponse:
            return "Couldn't load images right now. Try again in a bit."
        }
    }
}

enum UnsplashService {
    static var isConfigured: Bool {
        !Secrets.unsplashAccessKey.isEmpty && Secrets.unsplashAccessKey != "YOUR_UNSPLASH_ACCESS_KEY"
    }

    static func search(query: String) async throws -> [UnsplashPhoto] {
        guard isConfigured else { throw UnsplashError.missingKey }
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }

        var components = URLComponents(string: "https://api.unsplash.com/search/photos")!
        components.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "per_page", value: "24"),
            URLQueryItem(name: "orientation", value: "squarish"),
            URLQueryItem(name: "content_filter", value: "high"),
        ]

        var request = URLRequest(url: components.url!)
        request.setValue("Client-ID \(Secrets.unsplashAccessKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw UnsplashError.badResponse
        }

        let decoded = try JSONDecoder().decode(UnsplashSearchResponse.self, from: data)
        return decoded.results
    }

    static func downloadImageData(from urlString: String) async throws -> Data {
        guard let url = URL(string: urlString) else { throw UnsplashError.badResponse }
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    }
}
