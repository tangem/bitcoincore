import Foundation

class TransactionFeeCalculator {

    private let recipientSetter: IRecipientSetter
    private let inputSetter: IInputSetter
    private let addressConverter: IAddressConverter
    private let publicKeyManager: IPublicKeyManager
    private let changeScriptType: ScriptType

    init(recipientSetter: IRecipientSetter, inputSetter: IInputSetter, addressConverter: IAddressConverter, publicKeyManager: IPublicKeyManager, changeScriptType: ScriptType) {
        self.recipientSetter = recipientSetter
        self.inputSetter = inputSetter
        self.addressConverter = addressConverter
        self.publicKeyManager = publicKeyManager
        self.changeScriptType = changeScriptType
    }

    private func sampleAddress() throws -> String {
        try addressConverter.convert(publicKey: try publicKeyManager.changePublicKey(), type: changeScriptType).stringValue
    }
}

extension TransactionFeeCalculator: ITransactionFeeCalculator {

    func fee(for value: Int, feeRate: Int, senderPay: Bool, toAddress: String?, changeScript: Data?, sequence: Int, pluginData: [UInt8: IPluginData] = [:]) throws -> Int {
        let mutableTransaction = MutableTransaction()

        try recipientSetter.setRecipient(to: mutableTransaction, toAddress: toAddress ?? (try sampleAddress()), value: value, pluginData: pluginData, skipChecks: true)
        try inputSetter.setInputs(to: mutableTransaction, feeRate: feeRate, senderPay: senderPay, sortType: .none, changeScript: changeScript, sequence: sequence, feeCalculation: true)

        let inputsTotalValue = mutableTransaction.inputsToSign.reduce(0) { total, input in total + input.previousOutput.value }
        let outputsTotalValue = mutableTransaction.recipientValue + mutableTransaction.changeValue

        return abs(inputsTotalValue - outputsTotalValue)
    }

}
