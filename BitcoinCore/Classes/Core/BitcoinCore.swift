import Foundation
import HsToolKit

public class BitcoinCore {
    private let publicKeyManager: IPublicKeyManager
    private let addressConverter: AddressConverterChain
    private let restoreKeyConverterChain: RestoreKeyConverterChain
    private let unspentOutputSelector: UnspentOutputSelectorChain

    private let transactionCreator: ITransactionCreator
    private let transactionFeeCalculator: ITransactionFeeCalculator
    private let dustCalculator: IDustCalculator
    private let paymentAddressParser: IPaymentAddressParser

    private let pluginManager: IPluginManager

    private let bip: Bip


    private let unspentOutputsSetter: IUnspentOutputsSetter
    private let transactionSizeCalculator: ITransactionSizeCalculator
    // START: Extending

    public func add(restoreKeyConverter: IRestoreKeyConverter) {
        restoreKeyConverterChain.add(converter: restoreKeyConverter)
    }


    public func add(plugin: IPlugin) {
        pluginManager.add(plugin: plugin)
    }

    func publicKey(byPath path: String) throws -> PublicKey {
        try publicKeyManager.publicKey(byPath: path)
    }

    public func prepend(addressConverter: IAddressConverter) {
        self.addressConverter.prepend(addressConverter: addressConverter)
    }

    public func prepend(unspentOutputSelector: IUnspentOutputSelector) {
        self.unspentOutputSelector.prepend(unspentOutputSelector: unspentOutputSelector)
    }

    // END: Extending

    public var delegateQueue = DispatchQueue(label: "io.horizontalsystems.bitcoin-core.bitcoin-core-delegate-queue")

    init( publicKeyManager: IPublicKeyManager, addressConverter: AddressConverterChain, restoreKeyConverterChain: RestoreKeyConverterChain,
         unspentOutputSelector: UnspentOutputSelectorChain,
         transactionCreator: ITransactionCreator, transactionFeeCalculator: ITransactionFeeCalculator, dustCalculator: IDustCalculator,
         paymentAddressParser: IPaymentAddressParser,
        pluginManager: IPluginManager, bip: Bip, unspentOutputsSetter: IUnspentOutputsSetter, transactionSizeCalculator: ITransactionSizeCalculator) {
      
        self.publicKeyManager = publicKeyManager
        self.addressConverter = addressConverter
        self.restoreKeyConverterChain = restoreKeyConverterChain
        self.unspentOutputSelector = unspentOutputSelector
        self.transactionCreator = transactionCreator
        self.transactionFeeCalculator = transactionFeeCalculator
        self.dustCalculator = dustCalculator
        self.paymentAddressParser = paymentAddressParser

       // self.syncManager = syncManager
        self.pluginManager = pluginManager
        self.bip = bip
        
        self.unspentOutputsSetter = unspentOutputsSetter
        self.transactionSizeCalculator = transactionSizeCalculator
    }

}

extension BitcoinCore {
    public func createRawTransaction(to address: String, value: Int, feeRate: Int, sortType: TransactionDataSortType, signatures: [Data], changeScript: Data?, pluginData: [UInt8: IPluginData] = [:]) throws -> Data {
        try transactionCreator.createRawTransaction(to: address, value: value, feeRate: feeRate, senderPay: true, sortType: sortType, signatures: signatures, changeScript: changeScript, pluginData: pluginData)
    }
    
    public func createRawHashesToSign(to address: String, value: Int, feeRate: Int, sortType: TransactionDataSortType, changeScript: Data?, pluginData: [UInt8: IPluginData] = [:]) throws -> [Data] {
        try transactionCreator.createRawHashesToSign(to: address, value: value, feeRate: feeRate, senderPay: true, sortType: sortType, changeScript: changeScript, pluginData: pluginData)
    }

    public func validate(address: String, pluginData: [UInt8: IPluginData] = [:]) throws {
        try pluginManager.validate(address: try addressConverter.convert(address: address), pluginData: pluginData)
    }

    public func parse(paymentAddress: String) -> BitcoinPaymentData {
        paymentAddressParser.parse(paymentAddress: paymentAddress)
    }

    public func fee(for value: Int, toAddress: String? = nil, feeRate: Int, senderPay: Bool, changeScript: Data?, pluginData: [UInt8: IPluginData] = [:]) throws -> Int {
        try transactionFeeCalculator.fee(for: value, feeRate: feeRate, senderPay: senderPay, toAddress: toAddress, changeScript: changeScript, pluginData: pluginData)
    }
    
    public func setUnspents(_ unspents: [UnspentOutput]) {
        unspentOutputsSetter.setSpendableUtxos(unspents)
    }
    
//    public func maxSpendableValue(toAddress: String? = nil, feeRate: Int, changeScript: Data?, pluginData: [UInt8: IPluginData] = [:]) throws -> Int {
//        let sendAllFee = try transactionFeeCalculator.fee(for: balance.spendable, feeRate: feeRate, senderPay: false, toAddress: toAddress, changeScript: changeScript, pluginData: pluginData)
//        return max(0, balance.spendable - sendAllFee)
//    }

    public func minSpendableValue(toAddress: String? = nil) -> Int {
        var scriptType = ScriptType.p2pkh
        if let addressStr = toAddress, let address = try? addressConverter.convert(address: addressStr) {
            scriptType = address.scriptType
        }

        return dustCalculator.dust(type: scriptType)
    }

    public func maxSpendLimit(pluginData: [UInt8: IPluginData]) throws -> Int? {
        try pluginManager.maxSpendLimit(pluginData: pluginData)
    }

    public func receiveAddress() -> String {
        guard let publicKey = try? publicKeyManager.receivePublicKey(),
              let address = try? addressConverter.convert(publicKey: publicKey, type: bip.scriptType) else {
            return ""
        }

        return address.stringValue
    }
    
    public func receiveAddress(for scriptType: ScriptType) -> String {
        guard let publicKey = try? publicKeyManager.receivePublicKey(),
              let address = try? addressConverter.convert(publicKey: publicKey, type: scriptType) else {
            return ""
        }

        return address.stringValue
    }

    public func changePublicKey() throws -> PublicKey {
        try publicKeyManager.changePublicKey()
    }

    public func receivePublicKey() throws -> PublicKey {
        try publicKeyManager.receivePublicKey()
    }


}


extension BitcoinCore {
    public enum TransactionFilter {
        case p2shOutput(scriptHash: Data)
        case outpoint(transactionHash: Data, outputIndex: Int)
    }

}
