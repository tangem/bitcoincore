import Foundation
public enum ScriptType: Int {
    case unknown, p2pkh, p2pk, p2multi, p2sh, p2wsh, p2wpkh, p2wpkhSh, nullData

    var size: Int {
        switch self {
        case .p2pk: return 35
        case .p2pkh: return 25
        case .p2sh: return 23
        case .p2wsh: return 34
        case .p2wpkh: return 22
        case .p2wpkhSh: return 23
        default: return 0
        }
    }

    var witness: Bool {
        self == .p2wpkh || self == .p2wpkhSh || self == .p2wsh
    }

    var nativeSegwit: Bool {
        self == .p2wpkh || self == .p2wsh
    }

}

public class Output {
    public var value: Int
    public var lockingScript: Data
    public var index: Int
    public var transactionHash: Data
    var publicKeyPath: String? = nil
    private(set) var changeOutput: Bool = false
    public var scriptType: ScriptType = .unknown
    public var redeemScript: Data? = nil
    public var keyHash: Data? = nil
    var address: String? = nil

    public var pluginId: UInt8? = nil
    public var pluginData: String? = nil
    public var signatureScriptFunction: (([Data]) -> Data)? = nil

    public func set(publicKey: PublicKey) {
        self.publicKeyPath = publicKey.path
        self.changeOutput = !publicKey.external
    }

    public init(withValue value: Int, index: Int, lockingScript script: Data, transactionHash: Data = Data(), type: ScriptType = .unknown, redeemScript: Data? = nil, address: String? = nil, keyHash: Data? = nil, publicKey: PublicKey? = nil) {
        self.value = value
        self.lockingScript = script
        self.index = index
        self.transactionHash = transactionHash
        self.scriptType = type
        self.redeemScript = redeemScript
        self.address = address
        self.keyHash = keyHash
        
        if let publicKey = publicKey {
            set(publicKey: publicKey)
        }
    }
}
