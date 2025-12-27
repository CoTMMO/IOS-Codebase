//
//  AppError.swift
//  CountriesSwiftUI
//
//  Enhanced error handling for the application
//

import Foundation

enum AppError: Error {
    case network(NetworkError)
    case database(DatabaseError)
    case validation(ValidationError)
    case system(SystemError)
}

enum NetworkError: Error {
    case invalidURL
    case httpCode(HTTPCode, message: String?)
    case unexpectedResponse
    case noConnection
    case timeout
    case cancelled
    
    var statusCode: HTTPCode? {
        if case .httpCode(let code, _) = self {
            return code
        }
        return nil
    }
}

enum DatabaseError: Error {
    case fetchFailed(underlying: Error)
    case saveFailed(underlying: Error)
    case deleteFailed(underlying: Error)
    case notFound
    case corruptedData
}

enum ValidationError: Error {
    case missingData
    case invalidFormat
    case emptyResult
}

enum SystemError: Error {
    case permissionDenied
    case featureUnavailable
    case unknown(Error)
}

extension AppError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .network(let error):
            return error.errorDescription
        case .database(let error):
            return error.errorDescription
        case .validation(let error):
            return error.errorDescription
        case .system(let error):
            return error.errorDescription
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .network(.noConnection):
            return "Please check your internet connection and try again."
        case .network(.timeout):
            return "The request took too long. Please try again."
        case .database:
            return "There was an issue accessing local data. Please restart the app."
        case .validation(.missingData):
            return "Some required information is missing."
        default:
            return "Please try again later."
        }
    }
}

extension NetworkError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .httpCode(let code, let message):
            return message ?? "Unexpected HTTP code: \(code)"
        case .unexpectedResponse:
            return "Unexpected response from the server"
        case .noConnection:
            return "No internet connection"
        case .timeout:
            return "Request timed out"
        case .cancelled:
            return "Request was cancelled"
        }
    }
}

extension DatabaseError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .fetchFailed(let error):
            return "Failed to fetch data: \(error.localizedDescription)"
        case .saveFailed(let error):
            return "Failed to save data: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete data: \(error.localizedDescription)"
        case .notFound:
            return "Data not found"
        case .corruptedData:
            return "Data is corrupted or invalid"
        }
    }
}

extension ValidationError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .missingData:
            return "Data is missing"
        case .invalidFormat:
            return "Data format is invalid"
        case .emptyResult:
            return "No results found"
        }
    }
}

extension SystemError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Permission denied"
        case .featureUnavailable:
            return "Feature is not available"
        case .unknown(let error):
            return "An unexpected error occurred: \(error.localizedDescription)"
        }
    }
}
