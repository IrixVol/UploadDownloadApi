//
//  SwiftError.swift
//  UploadDownload
//
//  Created by Volochaeva Tatiana on 17.03.2024.
//

import Foundation

public enum SwiftError: LocalizedError {
    
    case description(String)
    
    public var errorDescription: String? {
        switch self {
        case .description(let text):
            return text
        }
    }
}
