//
//  PaymentQueue.swift
//  Eraser
//
//  Created by 狄烨 on 2023/8/2.
//

import Foundation
import StoreKit

public class PaymentQueue: NSObject, SKPaymentTransactionObserver {

    private weak var inPurchase: InPurchase?
    
    public convenience init(inPurchase: InPurchase) {
        self.init()
        self.inPurchase = inPurchase
    }
    
    public override init() {
        super.init()
        SKPaymentQueue.default().add(self)
    }

    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            let transactionId = transaction.transactionIdentifier ?? "0"
            let productId = transaction.payment.productIdentifier
            
            switch (transaction.transactionState) {
                case .purchased:
                    SKPaymentQueue.default().finishTransaction(transaction)
                    
                    // Let the StoreKit2-based StoreHelper know about this purchase or subscription renewal
                    Task { @MainActor in
                        if let inPurchase {
                            inPurchase.productPurchased(productId, transactionId: transactionId)
                            await inPurchase.handleStoreKit1Transactions(productId: productId, date: Date(), status: .purchased, transaction: transaction)
                        }
                    }

                case .restored:
                    SKPaymentQueue.default().finishTransaction(transaction)
                    
                case .failed:
                    SKPaymentQueue.default().finishTransaction(transaction)
                
                default: break
            }
        }
    }

    public func paymentQueue(_ queue: SKPaymentQueue, shouldAddStorePayment payment: SKPayment, for product: SKProduct) -> Bool {
        if let handler = inPurchase?.shouldAddStorePaymentHandler { return handler(payment, product) }
        return true
    }
}
