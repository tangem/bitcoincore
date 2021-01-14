enum BlockValidatorType { case header, bits, legacy, testNet, EDA, DAA, DGW }


protocol IHDWallet {
    var gapLimit: Int { get }
    func publicKey(account: Int, index: Int, external: Bool) throws -> PublicKey
    func publicKeys(account: Int, indices: Range<UInt32>, external: Bool) throws -> [PublicKey]
    func privateKeyData(account: Int, index: Int, external: Bool) throws -> Data
}

public protocol IRestoreKeyConverter {
    func keysForApiRestore(publicKey: PublicKey) -> [String]
    func bloomFilterElements(publicKey: PublicKey) -> [Data]
}

public protocol IPublicKeyManager {
    func changePublicKey() throws -> PublicKey
    func receivePublicKey() throws -> PublicKey
    func fillGap() throws
    func addKeys(keys: [PublicKey])
    func gapShifts() -> Bool
    func publicKey(byPath: String) throws -> PublicKey
}


public protocol IHasher {
    func hash(data: Data) -> Data
}

protocol IInitialSyncerDelegate: class {
    func onSyncSuccess()
    func onSyncFailed(error: Error)
}

protocol IPaymentAddressParser {
    func parse(paymentAddress: String) -> BitcoinPaymentData
}

public protocol IAddressConverter {
    func convert(address: String) throws -> Address
    func convert(keyHash: Data, type: ScriptType) throws -> Address
    func convert(publicKey: PublicKey, type: ScriptType) throws -> Address
}

public protocol IScriptConverter {
    func decode(data: Data) throws -> Script
}

protocol IScriptExtractor: class {
    var type: ScriptType { get }
    func extract(from data: Data, converter: IScriptConverter) throws -> Data?
}

protocol ITransactionLinker {
    func handle(transaction: FullTransaction)
}

protocol ITransactionPublicKeySetter {
    func set(output: Output) -> Bool
}

public protocol ITransactionSyncer: class {
    func newTransactions() -> [FullTransaction]
    func handleRelayed(transactions: [FullTransaction])
    func handleInvalid(fullTransaction: FullTransaction)
    func shouldRequestTransaction(hash: Data) -> Bool
}

public protocol ITransactionCreator {
    func createRawTransaction(to address: String, value: Int, feeRate: Int, senderPay: Bool, sortType: TransactionDataSortType, signatures: [Data], changeScript: Data?, isReplacedByFee: Bool, pluginData: [UInt8: IPluginData]) throws -> Data
    func createRawHashesToSign(to address: String, value: Int, feeRate: Int, senderPay: Bool, sortType: TransactionDataSortType, changeScript: Data?, isReplacedByFee: Bool, pluginData: [UInt8: IPluginData]) throws -> [Data]
}

protocol ITransactionBuilder {
    func buildTransaction(toAddress: String, value: Int, feeRate: Int, senderPay: Bool, sortType: TransactionDataSortType, signatures: [Data], changeScript: Data?, isReplacedByFee: Bool, pluginData: [UInt8: IPluginData]) throws -> FullTransaction
    
    func buildTransactionToSign(toAddress: String, value: Int, feeRate: Int, senderPay: Bool, sortType: TransactionDataSortType, changeScript: Data?, isReplacedByFee: Bool, pluginData: [UInt8: IPluginData]) throws -> [Data]
}

protocol ITransactionFeeCalculator {
    func fee(for value: Int, feeRate: Int, senderPay: Bool, toAddress: String?, changeScript: Data?, isReplacedByFee: Bool, pluginData: [UInt8: IPluginData]) throws -> Int
}

protocol IInputSigner {
    func sigScriptData(transaction: Transaction, inputsToSign: [InputToSign], outputs: [Output], index: Int, inputSignature: Data) throws -> [Data]
    func sigScriptHashToSign(transaction: Transaction, inputsToSign: [InputToSign], outputs: [Output], index: Int) throws -> Data
}

public protocol ITransactionSizeCalculator {
    func transactionSize(previousOutputs: [Output], outputScriptTypes: [ScriptType]) -> Int
    func transactionSize(previousOutputs: [Output], outputScriptTypes: [ScriptType], pluginDataOutputSize: Int) -> Int
    func outputSize(type: ScriptType) -> Int
    func inputSize(type: ScriptType) -> Int
    func witnessSize(type: ScriptType) -> Int
    func toBytes(fee: Int) -> Int
}

public protocol IDustCalculator {
    func dust(type: ScriptType) -> Int
}

public protocol IUnspentOutputSelector {
    func select(value: Int, feeRate: Int, outputScriptType: ScriptType, changeType: ScriptType, senderPay: Bool, pluginDataOutputSize: Int, feeCalculation: Bool) throws -> SelectedUnspentOutputInfo
}

public protocol IUnspentOutputProvider {
    var spendableUtxo: [UnspentOutput] { get }
}

public protocol IUnspentOutputsSetter {
    func setSpendableUtxos(_ utxos: [UnspentOutput])
}


public protocol INetwork: class {
    var pubKeyHash: UInt8 { get }
    var privateKey: UInt8 { get }
    var scriptHash: UInt8 { get }
    var bech32PrefixPattern: String { get }
    var xPubKey: UInt32 { get }
    var xPrivKey: UInt32 { get }
    var magic: UInt32 { get }
    var port: UInt32 { get }
    var dnsSeeds: [String] { get }
    var dustRelayTxFee: Int { get }
    var coinType: UInt32 { get }
    var sigHash: SigHashType { get }
}

protocol IIrregularOutputFinder {
    func hasIrregularOutput(outputs: [Output]) -> Bool
}

public protocol IPlugin {
    var id: UInt8 { get }
    var maxSpendLimit: Int? { get }
    func validate(address: Address) throws
    func processOutputs(mutableTransaction: MutableTransaction, pluginData: IPluginData, skipChecks: Bool) throws
    func processTransactionWithNullData(transaction: FullTransaction, nullDataChunks: inout IndexingIterator<[Chunk]>) throws
    func isSpendable(unspentOutput: UnspentOutput) throws -> Bool
    func inputSequenceNumber(output: Output) throws -> Int
    func parsePluginData(from: String, transactionTimestamp: Int) throws -> IPluginOutputData
    func keysForApiRestore(publicKey: PublicKey) throws -> [String]
}

public protocol IPluginManager {
    func validate(address: Address, pluginData: [UInt8: IPluginData]) throws
    func maxSpendLimit(pluginData: [UInt8: IPluginData]) throws -> Int?
    func add(plugin: IPlugin)
    func processOutputs(mutableTransaction: MutableTransaction, pluginData: [UInt8: IPluginData], skipChecks: Bool) throws
    func processInputs(mutableTransaction: MutableTransaction) throws
    func processTransactionWithNullData(transaction: FullTransaction, nullDataOutput: Output) throws
    func isSpendable(unspentOutput: UnspentOutput) -> Bool
    func parsePluginData(fromPlugin: UInt8, pluginDataString: String, transactionTimestamp: Int) -> IPluginOutputData?
}

protocol IRecipientSetter {
    func setRecipient(to mutableTransaction: MutableTransaction, toAddress: String, value: Int, pluginData: [UInt8: IPluginData], skipChecks: Bool) throws
}

protocol IOutputSetter {
    func setOutputs(to mutableTransaction: MutableTransaction, sortType: TransactionDataSortType)
}

protocol IInputSetter {
    func setInputs(to mutableTransaction: MutableTransaction, feeRate: Int, senderPay: Bool, sortType: TransactionDataSortType, changeScript: Data?, isReplacedByFee: Bool, feeCalculation: Bool) throws
    func setInputs(to mutableTransaction: MutableTransaction, fromUnspentOutput unspentOutput: UnspentOutput, feeRate: Int, isReplacedByFee: Bool) throws
}

protocol ITransactionSigner {
    func sign(mutableTransaction: MutableTransaction, signatures: [Data]) throws
    func hashesToSign(mutableTransaction: MutableTransaction) throws -> [Data]
}

public protocol IPluginData {
}

public protocol IPluginOutputData {
}

public enum TransactionDataSortType { case none, shuffle, bip69 }


protocol ITransactionDataSorterFactory {
    func sorter(for type: TransactionDataSortType) -> ITransactionDataSorter
}

protocol ITransactionDataSorter {
    func sort(outputs: [Output]) -> [Output]
    func sort(unspentOutputs: [UnspentOutput]) -> [UnspentOutput]
}

protocol IFactory {
    func transaction(version: Int, lockTime: Int) -> Transaction
    func inputToSign(withPreviousOutput: UnspentOutput, script: Data, sequence: Int) -> InputToSign
    func output(withIndex index: Int, address: Address, value: Int, publicKey: PublicKey?) -> Output
    func nullDataOutput(data: Data) -> Output
}
