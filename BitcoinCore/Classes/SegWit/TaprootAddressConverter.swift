import Foundation

/// Current implementation is only capable of convert exisiting
/// string address to Address object, e.g. address validation.
/// Other functions are unused and only exist to safisfy protocol
/// requirements
public class TaprootAddressConverter: IAddressConverter {
    private let prefix: String
    private let scriptConverter: IScriptConverter

    public init(prefix: String, scriptConverter: IScriptConverter) {
        self.prefix = prefix
        self.scriptConverter = scriptConverter
    }

    public func convert(address: String) throws -> Address {
        if let data = try? SegWitBech32.decode(bech32: Bech32(variant: .bech32m), hrp: prefix, addr: address) {
            var type: AddressType = .pubKeyHash
            if data.version == 0 {
                switch data.program.count {
                    case 32: type = .scriptHash
                    default: break
                }
            }
            return SegWitAddress(type: type, keyHash: data.program, bech32: address, version: data.version)
        }
        throw BitcoinCoreErrors.AddressConversion.unknownAddressType
    }

    public func convert(keyHash: Data, type: ScriptType) throws -> Address {
        fatalError("not implemented")
    }

    public func convert(publicKey: PublicKey, type: ScriptType) throws -> Address {
        fatalError("not implemented")
    }
}
