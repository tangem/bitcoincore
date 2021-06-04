class TransactionBuilder {
    private let recipientSetter: IRecipientSetter
    private let inputSetter: IInputSetter
    private let outputSetter: IOutputSetter
    private let signer: TransactionSigner

    init(recipientSetter: IRecipientSetter, inputSetter: IInputSetter, outputSetter: IOutputSetter, signer: TransactionSigner) {
        self.recipientSetter = recipientSetter
        self.inputSetter = inputSetter
        self.outputSetter = outputSetter
        self.signer = signer
    }

}

extension TransactionBuilder: ITransactionBuilder {
    func buildTransaction(toAddress: String, value: Int, feeRate: Int, senderPay: Bool, sortType: TransactionDataSortType, signatures: [Data], changeScript: Data?, sequence: Int, pluginData: [UInt8: IPluginData]) throws -> FullTransaction {
        let mutableTransaction = MutableTransaction()

        try recipientSetter.setRecipient(to: mutableTransaction, toAddress: toAddress, value: value, pluginData: pluginData, skipChecks: false)
        try inputSetter.setInputs(to: mutableTransaction, feeRate: feeRate, senderPay: senderPay, sortType: sortType, changeScript: changeScript, sequence: sequence, feeCalculation: false)

        outputSetter.setOutputs(to: mutableTransaction, sortType: sortType)
        try signer.sign(mutableTransaction: mutableTransaction, signatures: signatures)

        return mutableTransaction.build()
    }
    
    func buildTransactionToSign(toAddress: String, value: Int, feeRate: Int, senderPay: Bool, sortType: TransactionDataSortType, changeScript: Data?, sequence: Int, pluginData: [UInt8 : IPluginData]) throws -> [Data] {
        let mutableTransaction = MutableTransaction()

        try recipientSetter.setRecipient(to: mutableTransaction, toAddress: toAddress, value: value, pluginData: pluginData, skipChecks: false)
        try inputSetter.setInputs(to: mutableTransaction, feeRate: feeRate, senderPay: senderPay, sortType: sortType, changeScript: changeScript, sequence: sequence, feeCalculation: false)

        outputSetter.setOutputs(to: mutableTransaction, sortType: sortType)
        let hashes = try signer.hashesToSign(mutableTransaction:mutableTransaction)
        return hashes
    }

}
