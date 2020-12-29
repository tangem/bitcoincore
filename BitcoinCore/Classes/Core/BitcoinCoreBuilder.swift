import Foundation

public class BitcoinCoreBuilder {
    public enum BuildError: Error { case peerSizeLessThanRequired, noSeedData, noWalletId, noNetwork, noPaymentAddressParser, noAddressSelector, noStorage, noInitialSyncApi }

    // chains
    public let addressConverter = AddressConverterChain()

    // required parameters

    private var pubKey: Data?
    private var bip: Bip = .bip44
    private var network: INetwork?
    private var paymentAddressParser: IPaymentAddressParser?
    private var plugins = [IPlugin]()

    public func set(pubKey: Data) -> BitcoinCoreBuilder {
        self.pubKey = pubKey
        return self
    }
    
    public func set(bip: Bip) -> BitcoinCoreBuilder {
        self.bip = bip
        return self
    }

    public func set(network: INetwork) -> BitcoinCoreBuilder {
        self.network = network
        return self
    }

    public func set(paymentAddressParser: PaymentAddressParser) -> BitcoinCoreBuilder {
        self.paymentAddressParser = paymentAddressParser
        return self
    }

    public func add(plugin: IPlugin) -> BitcoinCoreBuilder {
        plugins.append(plugin)
        return self
    }

    public func build() throws -> BitcoinCore {
        let pubKey = self.pubKey ?? Data()
        
        guard let network = self.network else {
            throw BuildError.noNetwork
        }
        guard let paymentAddressParser = self.paymentAddressParser else {
            throw BuildError.noPaymentAddressParser
        }

        let scriptConverter = ScriptConverter()
        let restoreKeyConverterChain = RestoreKeyConverterChain()
        let pluginManager = PluginManager(scriptConverter: scriptConverter)

        plugins.forEach { pluginManager.add(plugin: $0) }
        restoreKeyConverterChain.add(converter: pluginManager)

        let unspentOutputProvider = SimpleUnspentOutputProvider(pluginManager: pluginManager)
        let factory = Factory()

        let publicKeyManager = SimplePublicKeyManager(compressedPublicKey: pubKey, restoreKeyConverter: restoreKeyConverterChain)
    
        let unspentOutputSelector = UnspentOutputSelectorChain()

        let transactionDataSorterFactory = TransactionDataSorterFactory()

        let inputSigner = InputSigner(network: network)
        let transactionSizeCalculator = TransactionSizeCalculator()
        let dustCalculator = DustCalculator(dustRelayTxFee: network.dustRelayTxFee, sizeCalculator: transactionSizeCalculator)
        let recipientSetter = RecipientSetter(addressConverter: addressConverter, pluginManager: pluginManager)
        let outputSetter = OutputSetter(outputSorterFactory: transactionDataSorterFactory, factory: factory)
        let inputSetter = InputSetter(unspentOutputSelector: unspentOutputSelector, transactionSizeCalculator: transactionSizeCalculator, addressConverter: addressConverter, publicKeyManager: publicKeyManager, factory: factory, pluginManager: pluginManager, dustCalculator: dustCalculator, changeScriptType: bip.scriptType, inputSorterFactory: transactionDataSorterFactory)
        let transactionSigner = TransactionSigner(inputSigner: inputSigner)
        let transactionBuilder = TransactionBuilder(recipientSetter: recipientSetter, inputSetter: inputSetter, outputSetter: outputSetter, signer: transactionSigner)
        let transactionFeeCalculator = TransactionFeeCalculator(recipientSetter: recipientSetter, inputSetter: inputSetter, addressConverter: addressConverter, publicKeyManager: publicKeyManager, changeScriptType: bip.scriptType)

        let transactionCreator = TransactionCreator(transactionBuilder: transactionBuilder)

        let bitcoinCore = BitcoinCore(
                publicKeyManager: publicKeyManager,
                addressConverter: addressConverter,
                restoreKeyConverterChain: restoreKeyConverterChain,
                unspentOutputSelector: unspentOutputSelector,
                transactionCreator: transactionCreator,
                transactionFeeCalculator: transactionFeeCalculator,
                dustCalculator: dustCalculator,
                paymentAddressParser: paymentAddressParser,
                pluginManager: pluginManager,
                bip: bip,
                unspentOutputsSetter: unspentOutputProvider,
                transactionSizeCalculator: transactionSizeCalculator)



        bitcoinCore.prepend(addressConverter: Base58AddressConverter(addressVersion: network.pubKeyHash, addressScriptVersion: network.scriptHash))
        bitcoinCore.prepend(unspentOutputSelector: UnspentOutputSelector(calculator: transactionSizeCalculator, provider: unspentOutputProvider, dustCalculator: dustCalculator))
        bitcoinCore.prepend(unspentOutputSelector: UnspentOutputSelectorSingleNoChange(calculator: transactionSizeCalculator, provider: unspentOutputProvider, dustCalculator: dustCalculator))

        return bitcoinCore
    }
}
