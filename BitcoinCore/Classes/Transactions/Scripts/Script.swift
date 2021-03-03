import Foundation

public class Script {
    public let scriptData: Data
    public let chunks: [Chunk]

    public var length: Int { return scriptData.count }

    public func validate(opCodes: Data) throws {
        guard opCodes.count == chunks.count else {
            throw ScriptError.wrongScriptLength
        }
        try chunks.enumerated().forEach { (index, chunk) in
            if chunk.opCode != opCodes[index] {
                throw ScriptError.wrongSequence
            }
        }
    }

    public init(with data: Data, chunks: [Chunk]) {
        self.scriptData = data
        self.chunks = chunks
    }

}

public class ScriptBuilder {
    
    public static func createOutputScriptData(for address: Address) throws -> Data {
        let scriptData: Data
        if let segwit = address as? SegWitAddress {
            scriptData = segwit.lockingScript
        } else {
            switch address.scriptType {
            case .p2pkh:
                scriptData = OpCode.p2pkhStart + OpCode.push(address.keyHash) + OpCode.p2pkhFinish
            case .p2sh:
                scriptData = OpCode.p2shStart + OpCode.push(address.keyHash) + OpCode.p2shFinish
            default:
                throw ScriptError.wrongSequence
            }
        }
        return scriptData
    }
    
    public static func createOutputScript(for address: Address) throws -> Script {
        let converter = ScriptConverter()
        let scriptData = try createOutputScriptData(for: address)
        return try converter.decode(data: scriptData)
    }
}
