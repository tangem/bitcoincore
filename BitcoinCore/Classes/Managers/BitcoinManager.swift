//
//  BitcoinCore.swift
//  BitcoinCore
//
//  Created by Alexander Osokin on 04.12.2020.
//

import Foundation
import HsToolKit
import OpenSslKit

public class BitcoinManager {
    private let kit: BitcoinCore
    private let coinRate: Decimal = pow(10, 8)
	private let networkParams: INetwork
    private let walletPublicKey: Data
    private let compressedWalletPublicKey: Data
	private var spendingScripts: [Script] = []
    
    public init(networkParams: INetwork, walletPublicKey: Data, compressedWalletPublicKey: Data, bip: Bip = .bip84) {
        self.walletPublicKey = walletPublicKey
        self.compressedWalletPublicKey = compressedWalletPublicKey
		self.networkParams = networkParams
        let key = bip == .bip44 ? walletPublicKey : compressedWalletPublicKey
        let logger = Logger(minLogLevel: .verbose)
        let paymentAddressParser = PaymentAddressParser(validScheme: "bitcoin", removeScheme: true)
        let scriptConverter = ScriptConverter()
        let bech32AddressConverter = SegWitBech32AddressConverter(prefix: networkParams.bech32PrefixPattern, scriptConverter: scriptConverter)
        let base58AddressConverter = Base58AddressConverter(addressVersion: networkParams.pubKeyHash, addressScriptVersion: networkParams.scriptHash)
        
        let bitcoinCoreBuilder = BitcoinCoreBuilder(logger: logger)
        
        let bitcoinCore = try! bitcoinCoreBuilder
            .set(network: networkParams)
            .set(pubKey: key)
            .set(bip: bip)
            .set(paymentAddressParser: paymentAddressParser)
            .build()
    
        bitcoinCore.prepend(addressConverter: bech32AddressConverter)
        
        switch bip {
        case .bip44:
            bitcoinCore.add(restoreKeyConverter: Bip44RestoreKeyConverter(addressConverter: base58AddressConverter))
            bitcoinCore.add(restoreKeyConverter: Bip49RestoreKeyConverter(addressConverter: base58AddressConverter))
            bitcoinCore.add(restoreKeyConverter: Bip84RestoreKeyConverter(addressConverter: bech32AddressConverter))
        case .bip49:
            bitcoinCore.add(restoreKeyConverter: Bip49RestoreKeyConverter(addressConverter: base58AddressConverter))
        case .bip84:
            bitcoinCore.add(restoreKeyConverter: Bip84RestoreKeyConverter(addressConverter: bech32AddressConverter))
        case .bip141:
            bitcoinCore.add(restoreKeyConverter: Bip84RestoreKeyConverter(addressConverter: bech32AddressConverter))
        }
        
        kit = bitcoinCore
    }
    
	public func fillBlockchainData(unspentOutputs: [UtxoDTO], spendingScripts: [Script]) {
		self.spendingScripts = spendingScripts
		let scriptConverted = ScriptConverter()
        let utxos: [UnspentOutput] = unspentOutputs.map { unspent in
            let output = Output(withValue: unspent.value, index: unspent.index, lockingScript: unspent.script, transactionHash: unspent.hash)
            TransactionOutputExtractor.processOutput(output)
            let tx = Transaction()
			
            let pubKey: PublicKey
            switch output.scriptType {
            case .p2pkh:
                pubKey = PublicKey(withAccount: 0, index: 0, external: true, hdPublicKeyData: walletPublicKey)
			case .p2wpkh:
				if let keyHash = output.keyHash {
					// TODO: Create script builder
					let script = OpCode.push(Data([OpCode.dup]) + Data([OpCode.hash160]) + OpCode.push(keyHash) + Data([OpCode.equalVerify]) + Data([OpCode.checkSig]))
					output.redeemScript = script
				}
                
				pubKey = PublicKey(withAccount: 0, index: 0, external: true, hdPublicKeyData: compressedWalletPublicKey)
			case .p2wsh, .p2sh:
                var scriptForChange: Data?
				if let script = try? scriptConverted.decode(data: unspent.script),
				   let redeemScript = self.findSpendingScript(for: script) {
					output.redeemScript = redeemScript.scriptData
                    scriptForChange = redeemScript.scriptData
				}
				
				pubKey = PublicKey(withAccount: 0, index: 0, external: true, hdPublicKeyData: scriptForChange ?? Data())
            default:
                fatalError("Unsupported output script")
            }
            return UnspentOutput(output: output, publicKey: pubKey , transaction: tx)
        }
      
        kit.setUnspents(utxos)
    }
    
    public func buildForSign(target: String, amount: Decimal, feeRate: Int, changeScript: Data?) throws -> [Data] {
        let amount = convertToSatoshi(value: amount)
        return try kit.createRawHashesToSign(to: target, value: amount, feeRate: feeRate, sortType: .none, changeScript: changeScript)
    }
    
    public func buildForSend(target: String, amount: Decimal, feeRate: Int, derSignatures: [Data], changeScript: Data?) throws -> Data {
        let amount = convertToSatoshi(value: amount)
        return try kit.createRawTransaction(to: target, value: amount, feeRate: feeRate, sortType: .none, signatures: derSignatures, changeScript: changeScript)
    }
    
    public func fee(for value: Decimal, address: String?, feeRate: Int, senderPay: Bool, changeScript: Data?) -> Decimal {
        let amount = convertToSatoshi(value: value)
        var fee: Int = 0
        do {
            fee = try kit.fee(for: amount, toAddress: address, feeRate: feeRate, senderPay: senderPay, changeScript: changeScript)
        } catch {
            fee = (try? kit.fee(for: amount, toAddress: address, feeRate: feeRate, senderPay: false, changeScript: changeScript)) ?? 0
            print(error)
        }
        
        return Decimal(fee) / coinRate
    }
    
    public func receiveAddress(for scriptType: ScriptType) -> String {
        kit.receiveAddress(for: scriptType)
    }
    
    private func convertToSatoshi(value: Decimal) -> Int {
        let coinValue: Decimal = value * coinRate

        let handler = NSDecimalNumberHandler(roundingMode: .plain, scale: 0, raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false)
        return NSDecimalNumber(decimal: coinValue).rounding(accordingToBehavior: handler).intValue
    }
	
	private func findSpendingScript(for searchingScript: Script) -> Script? {
		guard
			searchingScript.chunks.count > 1,
			let searchingScriptHash = searchingScript.chunks[1].data
		else { return nil }
		switch searchingScriptHash.count {
		case 20:
			return spendingScripts.first(where: { Kit.sha256ripemd160($0.scriptData) == searchingScriptHash })
		case 32:
			return spendingScripts.first(where: { Kit.sha256($0.scriptData) == searchingScriptHash })
		default:
			return nil
		}
	}
}


public class SimplePublicKeyManager: IPublicKeyManager {
    private let pubKey: PublicKey
    private let restoreKeyConverter: IRestoreKeyConverter

    public init (compressedPublicKey: Data, restoreKeyConverter: IRestoreKeyConverter) {
        pubKey = PublicKey(withAccount: 0, index: 0, external: true, hdPublicKeyData: compressedPublicKey)
        self.restoreKeyConverter = restoreKeyConverter
    }
    
    public func changePublicKey() throws -> PublicKey {
        return pubKey
    }
    
    public func receivePublicKey() throws -> PublicKey {
        return pubKey
    }
    
    public func fillGap() throws {
        fatalError("unsupported")
    }
    
    public func addKeys(keys: [PublicKey]) {
        fatalError("unsupported")
    }
    
    public func gapShifts() -> Bool {
        fatalError("unsupported")
    }
    
    public func publicKey(byPath: String) throws -> PublicKey {
        return pubKey
    }
}


class SimpleUnspentOutputProvider {
    let pluginManager: IPluginManager

    private var confirmedUtxo: [UnspentOutput] = []
    
    private var unspendableUtxo: [UnspentOutput] {
        confirmedUtxo.filter { !pluginManager.isSpendable(unspentOutput: $0) }
    }

    init(pluginManager: IPluginManager) {
        self.pluginManager = pluginManager
    }
}

extension SimpleUnspentOutputProvider: IUnspentOutputProvider {

    var spendableUtxo: [UnspentOutput] {
        confirmedUtxo.filter { pluginManager.isSpendable(unspentOutput: $0) }
    }

}

extension SimpleUnspentOutputProvider: IUnspentOutputsSetter {
    func setSpendableUtxos(_ utxos: [UnspentOutput]) {
        confirmedUtxo = utxos
    }
}


public struct UtxoDTO {
    public let hash: Data
    public let index: Int
    public let value: Int
    public let script: Data
    
    public init(hash: Data, index: Int, value: Int, script: Data) {
        self.hash = hash
        self.index = index
        self.value = value
        self.script = script
    }
}

public enum BitcoinNetwork {
    case mainnet
    case testnet
    
    public var networkParams: INetwork {
        switch self {
        case .mainnet:
            return MainNet()
        case .testnet:
            return TestNet()
        }
    }
}
