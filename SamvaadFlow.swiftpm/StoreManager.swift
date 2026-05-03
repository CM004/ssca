//
//  StoreManager.swift
//  SamvaadFlow
//
//  StoreKit 2 manager for one-time "Unlock All Domains" purchase ($2).
//

import StoreKit
import SwiftUI

@MainActor
final class StoreManager: ObservableObject {

    static let productID = "com.samvaadflow.alldomains"

    @Published var isPro: Bool = false
    @Published var product: Product? = nil
    @Published var purchaseError: String? = nil

    private var transactionListener: Task<Void, Never>?

    init() {
        transactionListener = listenForTransactions()
        Task { await loadProduct() }
        Task { await checkEntitlements() }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Load product

    func loadProduct() async {
        do {
            let products = try await Product.products(for: [Self.productID])
            product = products.first
        } catch {
            print("StoreManager: Failed to load products: \(error)")
        }
    }

    // MARK: - Purchase

    func purchase() async {
        guard let product else { return }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                isPro = true
                purchaseError = nil
            case .userCancelled:
                break
            case .pending:
                purchaseError = "Purchase is pending approval."
            @unknown default:
                break
            }
        } catch {
            purchaseError = "Purchase failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Restore

    func restore() async {
        try? await AppStore.sync()
        await checkEntitlements()
    }

    // MARK: - Check entitlements

    func checkEntitlements() async {
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result),
               transaction.productID == Self.productID {
                isPro = true
                return
            }
        }
    }

    // MARK: - Listen for transactions

    private func listenForTransactions() -> Task<Void, Never> {
        let targetProductID = Self.productID
        return Task.detached {
            for await result in Transaction.updates {
                guard let transaction = try? result.payloadValue,
                      transaction.productID == targetProductID else { continue }
                await MainActor.run { [weak self] in self?.isPro = true }
                await transaction.finish()
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe): return safe
        case .unverified: throw StoreError.unverified
        }
    }

    enum StoreError: Error {
        case unverified
    }
}
