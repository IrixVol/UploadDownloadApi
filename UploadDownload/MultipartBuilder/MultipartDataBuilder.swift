//
//  MultipartDataBuilder.swift
//  UploadDownload
//
//  Created by Volochaeva Tatiana on 17.02.2024.
//

import Foundation

/// Building body for `multipart/form-data` request  from parts of `MultipartDataChun`
public struct MultipartDataBuilder {
    
    public var encoding: String.Encoding = .utf8
    public var boundary: String
    public var chuncks = [MultipartDataChunk]()
    
    public init(boundary: String = UUID().uuidString) {
        self.boundary = boundary
    }
    
    public func get() throws -> (Data, String) {
        try (build(), boundary)
    }
    
    public func build() throws -> Data {

        guard let openningData = "--\(boundary)\r\n".data(using: encoding),
              let closingData = "\r\n--\(boundary)--".data(using: encoding),
              let separatingData = "\r\n--\(boundary)\r\n".data(using: .utf8) else {
            throw SwiftError.description("Impossible build body")
        }
        
        return try openningData
        + joinedChunksData(separatingTokenData: separatingData)
        + closingData
    }
    
    /// Building body for `multipart/form-data` request  from parts of `MultipartDataChun` with separator `separatingTokenData`
    private func joinedChunksData(separatingTokenData: Data) throws -> Data {
        
        try chuncks.map { try $0.build() }.reduce(into: Data()) { partialResult, data in
            if !partialResult.isEmpty {
                partialResult.append(separatingTokenData)
            }
            partialResult.append(data)
        }
    }
    
    public func appendingChunk(_ chunk: MultipartDataChunk) -> Self {
        var copy = self
        copy.chuncks.append(chunk)
        return copy
    }
}
