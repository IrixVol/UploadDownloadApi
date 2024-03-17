//
//  MultipartDataChunk.swift
//  UploadDownload
//
//  Created by Volochaeva Tatiana on 17.02.2024.
//

import Foundation

/// Building part of body for `multipart/form-data` request
public struct MultipartDataChunk {
    
    public var encoding: String.Encoding = .utf8
    public var name: String
    public var fileName: String?
    public var body: Data
    
    private var contentDispositonString: String {
        if let fileName {
            return "Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(fileName)\"\r\n"
        } else {
            return "Content-Disposition: form-data; name=\"\(name)\"\r\n"
        }
    }
    
    private var contentLengthString: String {
        "Content-Length: \(body.count)\r\n\r\n"
    }
    
    public init(name: String = "file", fileName: String? = nil, body: Data) {
        self.name = name
        self.fileName = fileName
        self.body = body
    }

    public func build() throws -> Data {
        
        guard let metaData = (contentDispositonString + contentLengthString).data(using: encoding) else {
            throw SwiftError.description("Impossible build body")
        }
        
        return metaData + body
    }
}
