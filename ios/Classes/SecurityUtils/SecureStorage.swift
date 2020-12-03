//
//  SecureStorage.swift
//  SecureStorage
//
//  Created by Alessandro De Carli on 23.02.18.
//  Copyright © 2018 ___Alessandro De Carli___. All rights reserved.
//

import Foundation
import Security
import LocalAuthentication
import CryptoTokenKit

public class SecureStorage {

    let tag: Data
    let paranoiaMode: Bool
    var accessControlFlags: SecAccessControlCreateFlags {
        var flags: SecAccessControlCreateFlags = LocalAuthentication.defaultAccessFlags()
        flags.insert(.privateKeyUsage)
        if (paranoiaMode){
            flags.insert(.applicationPassword)
        }
        return flags
    }

    public init(tag: Data, paranoiaMode: Bool = false){
        self.tag = tag
        self.paranoiaMode = paranoiaMode
    }

    private func generateNewBiometricSecuredKey() throws -> Keychain.PrivateKey {
        return try Keychain.PrivateKey(tag: tag, accessControl: accessControlFlags)
    }

    private func fetchSecretKey(with context: LAContext, completion: @escaping (Result<Keychain.PrivateKey, Error>) -> ()) -> Bool {
        let authentication = Keychain.Authentication(context: context, ui: .allow)
        do {
            let key = try Keychain.PrivateKey.load(tag: self.tag, authentication: authentication)
            completion(.success(key))
            return true
        } catch {
            DispatchQueue.global(qos: .default).async {
                do {
                    let key = try self.generateNewBiometricSecuredKey()
                    completion(.success(key))
                } catch {
                    completion(.failure(Error(error)))
                }
            }
            return false
        }
    }

    @inline(__always) private func fetchBiometricSecuredKey(completion: @escaping (Result<Keychain.PrivateKey, Error>) -> ()) {
        LocalAuthentication.shared.fetchContextForAccessAuthentication { context -> Bool in
            return self.fetchSecretKey(with: context, completion: completion)
        }
    }
    
    public func dropSecuredKey() -> Bool {
        return Keychain.PrivateKey.delete(tag: tag)
    }

    public func store(key: String, value: String, completion: @escaping (Error?) -> ()) {
        fetchBiometricSecuredKey { result in
            switch result {
            case let .success(secretKey):
                do {
                    try self.store(key: key, value: value, using: secretKey)
                    completion(nil)
                } catch {
                    completion(Error(error))
                }
            case let .failure(error):
                completion(Error(error))
            }
        }
    }

    private func store(key: String, value: String, using secretKey: Keychain.PrivateKey) throws {
        guard let messageData = value.data(using: .utf8) else {
            throw Error.dataConversionFailure
        }
        let encryptedData = try secretKey.encrypt(data: messageData)
        let item = Keychain.Password(data: encryptedData, account: key)
        try item.save()
    }

    public func retrieve(key: String, completion: @escaping (Result<String, Error>) -> ()) {
        fetchBiometricSecuredKey { result in
            switch result {
            case let .success(secretKey):
                do {
                    let value = try self.retrieve(key: key, using: secretKey)
                    completion(.success(value))
                } catch {
                    if
                        let error = error as? Keychain.Error,
                        case let .internal(internalError) = error,
                        let tkError = internalError as? TKError, tkError.code == .corruptedData {
                        
                        if (self.dropSecuredKey()) {
                            self.retrieve(key: key, completion: completion)
                        } else {
                            completion(.failure(Error(error)))
                        }
                    } else {
                        completion(.failure(Error(error)))
                    }
                }
            case let .failure(error):
                completion(.failure(Error(error)))
            }
        }
    }
    
    private func retrieve(key: String, using secretKey: Keychain.PrivateKey) throws -> String {
        let item = try Keychain.Password.load(account: key)
        let decryptedData = try secretKey.decrypt(data: item.data)
        guard let result = String(data: decryptedData as Data, encoding: .utf8) else {
            throw Error.stringConversionFailure
        }
        return result
    }

    public func delete(key: String) throws {
        try Keychain.Password.delete(account: key)
    }

    public enum Error: Swift.Error {
        
        case unknown
        case `internal`(Swift.Error)
        case dataConversionFailure
        case stringConversionFailure
        
        var isKeychainAuthError: Bool {
            if case let .internal(error) = self, let keychainError = error as? Keychain.Error {
                return keychainError.isAuthError
            }
            return false
        }
        
        var isKeychainAuthCancelled: Bool {
            if case let .internal(error) = self,
               let keychainError = error as? Keychain.Error,
               case let .internal(internalError) = keychainError,
               let laError = internalError as? LAError {
                
                return laError.isCancelled
            }
            return false
        }

        init(_ error: Swift.Error?) {
            if let error = error as? Error {
                self = error
            } else if let error = error {
                self = .internal(error)
            } else {
                self = .unknown
            }
        }
    }
}

extension LAError {
    
    var isCancelled: Bool {
        errorCode == LAError.Code.appCancel.rawValue || errorCode == LAError.Code.userCancel.rawValue || errorCode == LAError.Code.systemCancel.rawValue
    }
}
