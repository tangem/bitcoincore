import Foundation
public enum TransactionStatus: Int, Codable { case new, relayed, invalid }

public class Transaction {
    public var uid: String
    public var dataHash: Data
    public var version: Int
    public var lockTime: Int
    public var timestamp: Int
    public var order: Int
    public var blockHash: Data? = nil
    public var isMine: Bool = false
    public var isOutgoing: Bool = false
    public var status: TransactionStatus = .relayed
    public var segWit: Bool = false
    public var conflictingTxHash: Data? = nil
    public var transactionInfoJson: Data = Data()
    public var rawTransaction: String? = nil

    public init(version: Int = 0, lockTime: Int = 0, timestamp: Int? = nil) {
        self.version = version
        self.lockTime = lockTime
        self.timestamp = timestamp ?? Int(Date().timeIntervalSince1970)
        self.order = 0
        self.dataHash = Data()
        self.uid = UUID().uuidString
    }
}
