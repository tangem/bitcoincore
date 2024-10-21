import Foundation

class InputSigner {
    enum SignError: Error {
        case noPreviousOutput
        case noPreviousOutputAddress
        case noPrivateKey
    }

    let network: INetwork

    init(network: INetwork) {
        self.network = network
    }

}

extension InputSigner: IInputSigner {
    func sigScriptData(transaction: Transaction, inputsToSign: [InputToSign], outputs: [Output], index: Int, inputSignature: Data) throws -> [Data] {
        let input = inputsToSign[index]
        let previousOutput = input.previousOutput
        let pubKey = input.previousOutputPublicKey
        let publicKey = pubKey.raw

		let witness = previousOutput.scriptType == .p2wpkh || previousOutput.scriptType == .p2wpkhSh || previousOutput.scriptType == .p2wsh

        var serializedTransaction = try TransactionSerializer.serializedForSignature(transaction: transaction, inputsToSign: inputsToSign, outputs: outputs, inputIndex: index, forked: witness || network.sigHash.forked)
        serializedTransaction += UInt32(network.sigHash.value)
        let signature = inputSignature + Data([network.sigHash.value])

        switch previousOutput.scriptType {
		case .p2pk, .p2wsh, .p2sh: return [signature]
        default: return [signature, publicKey]
        }
    }
    
    func sigScriptHashToSign(transaction: Transaction, inputsToSign: [InputToSign], outputs: [Output], index: Int) throws -> Data {
        let input = inputsToSign[index]
        let previousOutput = input.previousOutput
		let witness = previousOutput.scriptType == .p2wpkh || previousOutput.scriptType == .p2wpkhSh || previousOutput.scriptType == .p2wsh

        var serializedTransaction = try TransactionSerializer.serializedForSignature(transaction: transaction, inputsToSign: inputsToSign, outputs: outputs, inputIndex: index, forked: witness || network.sigHash.forked)
        serializedTransaction += UInt32(network.sigHash.value)
        let signatureHash = serializedTransaction.doubleSha256()
        return signatureHash
    }

}
