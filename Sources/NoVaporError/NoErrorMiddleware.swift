//
//  NoErrorMiddleware.swift
//  
//
//  Created by Guerson Perez on 9/23/23.
//

import Foundation
import Vapor

public class NoErrorMiddleware: Middleware {
    
    public static func `default`(environment: Environment) -> ErrorMiddleware {
        return .init { req, error in
            let status: HTTPResponseStatus
            let domain: String?
            let reason: String
            let headers: HTTPHeaders
            let code: NoError.Code
            let fields: [String]?
            
            switch error {
            case let abort as AbortError:
                domain = nil
                reason = abort.reason
                headers = abort.headers
                status = abort.status
                code = .unknown
                fields = nil
            case let noError as NoError:
                domain = noError.domain
                status = noError.status
                reason = noError.reason ?? "Something went wrong."
                headers = [:]
                code = noError.code
                fields = noError.fields
            default:
                status = .internalServerError
                domain = nil
                reason = environment.isRelease ?
                "Something went wrong."
                : String(describing: error)
                headers = [:]
                code = .unknown
                fields = nil
            }
            
            req.logger.report(error: error)
            
            let response = Response(status: status, headers: headers)
            
            do {
                let errorResponse = NoError(domain: domain, reason: reason, code: code, fields: fields)
                response.body = try .init(data: JSONEncoder().encode(errorResponse), byteBufferAllocator: req.byteBufferAllocator)
                response.headers.replaceOrAdd(name: .contentType, value: "application/json; charset=utf-8")
            } catch {
                response.body = .init(string: "Oops: \(error)", byteBufferAllocator: req.byteBufferAllocator)
                response.headers.replaceOrAdd(name: .contentType, value: "text/plain; charset=utf-8")
            }
            return response
        }
    }
    
    private let closure: (Request, Error) -> (Response)
    
    public init(_ closure: @escaping (Request, Error) -> (Response)) {
        self.closure = closure
    }
    
    public func respond(to request: Vapor.Request, chainingTo next: Vapor.Responder) -> NIOCore.EventLoopFuture<Vapor.Response> {
        next.respond(to: request).flatMapErrorThrowing { error in
            self.closure(request, error)
        }
    }
}
