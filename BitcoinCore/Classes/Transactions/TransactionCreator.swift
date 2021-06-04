class TransactionCreator {
    enum CreationError: Error {
        case transactionAlreadyExists
    }
    
    private let transactionBuilder: ITransactionBuilder

    init(transactionBuilder: ITransactionBuilder) {
        self.transactionBuilder = transactionBuilder
    }
}

extension TransactionCreator: ITransactionCreator {
    func createRawTransaction(to address: String, value: Int, feeRate: Int, senderPay: Bool, sortType: TransactionDataSortType, signatures: [Data], changeScript: Data?, sequence: Int, pluginData: [UInt8: IPluginData] = [:]) throws -> Data {
        let transaction = try transactionBuilder.buildTransaction(
            toAddress: address,
            value: value,
            feeRate: feeRate,
            senderPay: senderPay,
            sortType: sortType,
            signatures: signatures,
            changeScript: changeScript,
            sequence: sequence,
            pluginData: pluginData
        )

        return TransactionSerializer.serialize(transaction: transaction)
    }
    
    func createRawHashesToSign(to address: String, value: Int, feeRate: Int, senderPay: Bool, sortType: TransactionDataSortType, changeScript: Data?, sequence: Int, pluginData: [UInt8 : IPluginData]) throws -> [Data] {
        let hashes = try transactionBuilder.buildTransactionToSign(
            toAddress: address,
            value: value,
            feeRate: feeRate,
            senderPay: senderPay,
            sortType: sortType,
            changeScript: changeScript,
            sequence: sequence,
            pluginData: pluginData
        )
        
        return hashes
    }
}


