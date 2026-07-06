import Foundation

struct APIError: LocalizedError {
    let message: String
    let statusCode: Int?

    var errorDescription: String? { message }
}

enum APIClientError: LocalizedError {
    case unauthorized
    case invalidResponse
    case server(String)

    var errorDescription: String? {
        switch self {
        case .unauthorized: return "Neplatná session"
        case .invalidResponse: return "Neplatná odpoveď servera"
        case .server(let message): return message
        }
    }
}

@MainActor
final class APIClient {
    static let shared = APIClient()

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    private init() {}

    func request<T: Decodable>(
        _ path: String,
        method: String = "GET",
        body: (any Encodable)? = nil,
        authorized: Bool = true
    ) async throws -> T {
        let data = try await send(path, method: method, body: body, authorized: authorized)
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIClientError.invalidResponse
        }
    }

    func send(
        _ path: String,
        method: String = "GET",
        body: (any Encodable)? = nil,
        authorized: Bool = true
    ) async throws -> Data {
        guard let url = URL(string: AppConfig.apiBaseURL + path) else {
            throw APIClientError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if authorized {
            guard let token = KeychainHelper.load(for: AuthKeys.accessToken) else {
                throw APIClientError.unauthorized
            }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            request.httpBody = try encoder.encode(AnyEncodable(body))
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw APIClientError.invalidResponse
        }

        if http.statusCode == 401 && authorized {
            let refreshed = try await BackendAuthService.shared.refreshSession()
            if refreshed {
                return try await send(path, method: method, body: body, authorized: authorized)
            }
            throw APIClientError.unauthorized
        }

        guard (200...299).contains(http.statusCode) else {
            if let apiError = try? decoder.decode(ErrorResponse.self, from: data) {
                throw APIClientError.server(apiError.error)
            }
            throw APIClientError.server("HTTP \(http.statusCode)")
        }

        return data
    }
}

private struct ErrorResponse: Decodable {
    let error: String
}

private struct AnyEncodable: Encodable {
    private let encodeFunc: (Encoder) throws -> Void

    init(_ value: any Encodable) {
        encodeFunc = value.encode
    }

    func encode(to encoder: Encoder) throws {
        try encodeFunc(encoder)
    }
}
