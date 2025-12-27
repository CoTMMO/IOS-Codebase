//
//  WebRepository.swift
//  CountriesSwiftUI
//
//  Created by Alexey Naumov on 23.10.2019.
//  Copyright © 2019 Alexey Naumov. All rights reserved.
//

import Foundation
import Combine

enum ApiModel { }

protocol WebRepository {
    var session: URLSession { get }
    var baseURL: String { get }
}

extension WebRepository {
    func call<Value, Decoder>(
        endpoint: APICall,
        decoder: Decoder = JSONDecoder(),
        httpCodes: HTTPCodes = .success
    ) async throws -> Value
    where Value: Decodable, Decoder: TopLevelDecoder, Decoder.Input == Data {

        let request = try endpoint.urlRequest(baseURL: baseURL)

        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.unexpectedResponse
            }
            guard httpCodes.contains(httpResponse.statusCode) else {
                throw APIError.httpCode(httpResponse.statusCode)
            }
            return try decoder.decode(Value.self, from: data)
        } catch let error as APIError {
            throw error
        } catch let error as URLError {
            throw mapURLError(error)
        } catch {
            throw APIError.unexpectedResponse
        }
    }

    private func mapURLError(_ error: URLError) -> APIError {
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost:
            return .networkError(.noConnection)
        case .timedOut:
            return .networkError(.timeout)
        case .cancelled:
            return .networkError(.cancelled)
        default:
            return .unexpectedResponse
        }
    }
}

// MARK: - APICall

protocol APICall {
    var path: String { get }
    var method: String { get }
    var headers: [String: String]? { get }
    func body() throws -> Data?
}

enum APIError: Swift.Error, Equatable {
    case invalidURL
    case httpCode(HTTPCode)
    case unexpectedResponse
    case imageDeserialization
    case networkError(NetworkErrorType)

    enum NetworkErrorType: Equatable {
        case noConnection
        case timeout
        case cancelled
    }
}

extension APIError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case let .httpCode(code):
            return "Unexpected HTTP code: \(code)"
        case .unexpectedResponse:
            return "Unexpected response from the server"
        case .imageDeserialization:
            return "Cannot deserialize image from Data"
        case .networkError(.noConnection):
            return "No internet connection"
        case .networkError(.timeout):
            return "Request timed out"
        case .networkError(.cancelled):
            return "Request was cancelled"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .networkError(.noConnection):
            return "Please check your internet connection and try again."
        case .networkError(.timeout):
            return "The request took too long. Please try again."
        case .httpCode(let code) where code >= 500:
            return "The server is experiencing issues. Please try again later."
        case .httpCode(let code) where code >= 400:
            return "The request was invalid. Please contact support if this persists."
        default:
            return "Please try again."
        }
    }
}

extension APICall {
    func urlRequest(baseURL: String) throws -> URLRequest {
        guard let url = URL(string: baseURL + path) else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.allHTTPHeaderFields = headers
        request.httpBody = try body()
        return request
    }
}

typealias HTTPCode = Int
typealias HTTPCodes = Range<HTTPCode>

extension HTTPCodes {
    static let success = 200 ..< 300
}
