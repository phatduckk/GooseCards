import Foundation

struct RemoteCardFile: Identifiable, Decodable, Hashable {
    let name: String
    let path: String
    let sha: String
    let size: Int
    let downloadURL: String?

    var id: String { path }
    var displayName: String {
        name.hasSuffix(".csv") ? String(name.dropLast(4)) : name
    }

    enum CodingKeys: String, CodingKey {
        case name, path, sha, size
        case downloadURL = "download_url"
    }
}

enum ImportError: LocalizedError {
    case badResponse

    var errorDescription: String? {
        "Couldn't reach GitHub right now. Check your connection and try again."
    }
}

enum GitHubCardsService {
    private static let owner = "phatduckk"
    private static let repo = "GooseCards"
    private static let path = "Cards"

    static func listCardFiles() async throws -> [RemoteCardFile] {
        let url = URL(string: "https://api.github.com/repos/\(owner)/\(repo)/contents/\(path)")!
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ImportError.badResponse
        }

        let files = try JSONDecoder().decode([RemoteCardFile].self, from: data)
        return files
            .filter { $0.name.lowercased().hasSuffix(".csv") }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    static func downloadCSV(_ file: RemoteCardFile) async throws -> String {
        guard let urlString = file.downloadURL, let url = URL(string: urlString) else {
            throw ImportError.badResponse
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let text = String(data: data, encoding: .utf8) else {
            throw ImportError.badResponse
        }
        return text
    }

    static func downloadImageData(from urlString: String) async -> Data? {
        guard let url = URL(string: urlString) else { return nil }
        return try? await URLSession.shared.data(from: url).0
    }
}
