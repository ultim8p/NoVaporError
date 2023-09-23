//
//  NoError.swift
//  
//
//  Created by Guerson Perez on 9/23/23.
//

import Foundation
import Vapor

public struct NoError: Error, Content {
    
    public var domain: String?
    
    public var status: HTTPResponseStatus {
        switch self.code {
        default:
            return .badRequest
        }
    }
    
    public var reason: String?
    
    public var code: Code
    
    public var fields: [String]?
    
    public enum Code: String, Content, UnknownCaseRepresentable {
        case unknown
        case creating
        case creation
        case duplicate
        case missingValues
        case limit
        case validation
        case notFound
        static public var unknownCase: NoError.Code = .unknown
    }
    
    public static func create(
        domain: String? = nil,
        reason: String? = nil,
        code: Code? = nil,
        fields: [String]? = nil
    ) -> NoError {
        NoError(
            domain: domain,
            reason: reason,
            code: code ?? .unknown,
            fields: fields
        )
    }
}
