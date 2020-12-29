import Foundation
import CryptoKit
import CommonCrypto

extension Data {
    
    init?(hex: String) {
        let hex = hex.stripHexPrefix()
        
        let len = hex.count / 2
        var data = Data(capacity: len)
        for i in 0..<len {
            let j = hex.index(hex.startIndex, offsetBy: i * 2)
            let k = hex.index(j, offsetBy: 2)
            let bytes = hex[j..<k]
            if var num = UInt8(bytes, radix: 16) {
                data.append(&num, count: 1)
            } else {
                return nil
            }
        }
        self = data
    }
    
    var hex: String {
        reduce("") { $0 + String(format: "%02x", $1) }
    }
    
    var reversedHex: String {
        Data(self.reversed()).hex
    }
    
}


extension Data {
    var ripemd160: Data {
        _RIPEMD160.hash(message: self)
    }
    
    var sha256Ripemd160: Data {
        _RIPEMD160.hash(message: sha256())
    }
    
    func doubleSha256() -> Data {
        sha256().sha256()
    }
    
    func sha256() -> Data {
        if #available(iOS 13.0, *) {
            let digest = SHA256.hash(data: self)
            return Data(digest)
        } else {
            return sha256Old()
        }
    }
    
    private func sha256Old() -> Data {
        guard let res = NSMutableData(length: Int(CC_SHA256_DIGEST_LENGTH)) else {
            return Data()
        }
        CC_SHA256((self as NSData).bytes, CC_LONG(count), res.mutableBytes.assumingMemoryBound(to: UInt8.self))
        return res as Data
    }
}
