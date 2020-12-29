import HsToolKit

class Factory: IFactory {
    init() {}

    func transaction(version: Int, lockTime: Int) -> Transaction {
        Transaction(version: version, lockTime: lockTime)
    }

    func inputToSign(withPreviousOutput previousOutput: UnspentOutput, script: Data, sequence: Int) -> InputToSign {
        let input = Input(
                withPreviousOutputTxHash: previousOutput.output.transactionHash, previousOutputIndex: previousOutput.output.index,
                script: script, sequence: sequence
        )

        return InputToSign(input: input, previousOutput: previousOutput.output, previousOutputPublicKey: previousOutput.publicKey)
    }

    func output(withIndex index: Int, address: Address, value: Int, publicKey: PublicKey?) -> Output {
        Output(withValue: value, index: index, lockingScript: address.lockingScript, type: address.scriptType, address: address.stringValue, keyHash: address.keyHash, publicKey: publicKey)
    }

    func nullDataOutput(data: Data) -> Output {
        Output(withValue: 0, index: 0, lockingScript: data, type: .nullData)
    }
}
