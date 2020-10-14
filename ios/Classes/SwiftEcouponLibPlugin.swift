import Flutter
import UIKit

private enum Method: String {
    case load
    case store
    case getPlatformVersion
}

private enum FlutterErrorCode: Int {
    case internalError = -1
    case methodNotImplemented = -2
    case loadWrongArguments = -3
    case storeWrongArguments = -4
    case keychainAuthError = -5
}

public class SwiftEcouponLibPlugin: NSObject, FlutterPlugin {
    
    private let storage: SecureStorage
    
    public override init() {
        storage = SecureStorage(tag: "ecoupon_storage".data(using: .utf8)!)
        super.init()
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let method = Method(rawValue: call.method) else {
            result(FlutterError(code: "\(FlutterErrorCode.methodNotImplemented.rawValue)", message: "Method \(call.method) not implemented", details: nil))
            return
        }
        switch method {
        case .load:
            guard let arguments: [String] = extractArguments(named: ["key"], from: call.arguments) else {
                result(FlutterError(code: "\(FlutterErrorCode.loadWrongArguments.rawValue)", message: "Wrong arguments for \(call.method)", details: nil))
                return
            }
            load(key: arguments[0], completion: result)
        case .store:
            guard let arguments: [String] = extractArguments(named: ["key", "value"], from: call.arguments) else {
                result(FlutterError(code: "\(FlutterErrorCode.storeWrongArguments.rawValue)", message: "Wrong arguments for \(call.method)", details: nil))
                return
            }
            store(key: arguments[0], value: arguments[1], completion: result)
        case .getPlatformVersion:
            result(UIDevice.current.systemVersion)
        }
    }
    
    private func extractArguments<T>(named: [String], from arguments: Any?) -> [T]? {
        guard let arguments = arguments as? [String:T] else {
            return nil
        }
        let extracted = named.compactMap { arguments[$0] }
        guard extracted.count == named.count else {
            return nil
        }
        return extracted
    }
    
    private func store(key: String, value: String, completion: @escaping FlutterResult) {
        storage.store(key: key, value: value) { error in
            guard let error = error else {
                completion(nil)
                return
            }
            if error.isKeychainAuthError {
                completion(FlutterError(code: "\(FlutterErrorCode.keychainAuthError.rawValue)", message: error.localizedDescription, details: nil))
            } else {
                completion(FlutterError(code: "\(FlutterErrorCode.internalError.rawValue)", message: error.localizedDescription, details: nil))
            }
        }
    }
    
    private func load(key: String, completion: @escaping FlutterResult) {
        storage.retrieve(key: key) { result in
            switch result {
            case let .success(value):
                completion(value)
            case let .failure(error):
                if error.isKeychainAuthError {
                    completion(FlutterError(code: "\(FlutterErrorCode.keychainAuthError.rawValue)", message: error.localizedDescription, details: nil))
                } else {
                    completion(FlutterError(code: "\(FlutterErrorCode.internalError.rawValue)", message: error.localizedDescription, details: nil))
                }
            }
        }
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "ecoupon_lib", binaryMessenger: registrar.messenger())
        let instance = SwiftEcouponLibPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
}
