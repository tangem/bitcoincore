//
//  SignedHash.swift
//  BitcoinCore
//
//  Created by Sergey Balashov on 29.05.2023.
//

import Foundation

public struct HashForSign: Hashable {
    public let hash: Data
    public let publicKey: PublicKey
    
    public init(hash: Data, publicKey: PublicKey) {
        self.hash = hash
        self.publicKey = publicKey
    }
}
