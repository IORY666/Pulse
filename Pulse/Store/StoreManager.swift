import Foundation
import StoreKit
import SwiftUI

/// App内购管理器 - 使用StoreKit 2
@MainActor
@Observable
final class StoreManager {
    /// Pro版是否已解锁
    var isProUnlocked: Bool = false
    /// Pro产品信息
    var proProduct: Product?
    /// 是否正在加载产品
    var isLoading: Bool = false
    /// 是否正在购买
    var isPurchasing: Bool = false
    /// 购买错误信息
    var purchaseError: String?
    /// 是否显示错误
    var showError: Bool = false

    /// Pro版产品ID
    static let proProductID = "com.pulse.habittracker.pro"

    /// 单例
    static let shared = StoreManager()

    private var updatesTask: Task<Void, Never>?

    private init() {
        // 从本地恢复状态
        isProUnlocked = UserDefaults.standard.bool(forKey: "is_pro_unlocked")

        // 启动交易监听
        updatesTask = Task {
            for await update in Transaction.updates {
                if let transaction = try? update.payloadValue {
                    await handleTransaction(transaction)
                }
            }
        }

        // 启动时检查未完成的交易
        Task {
            await checkUnfinishedTransactions()
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    /// 加载Pro产品信息
    func loadProduct() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let products = try await Product.products(for: [Self.proProductID])
            proProduct = products.first
        } catch {
            purchaseError = "无法加载产品信息，请检查网络连接后重试"
            showError = true
        }
    }

    /// 购买Pro
    func purchasePro() async {
        guard let product = proProduct else {
            await loadProduct()
            guard proProduct != nil else {
                purchaseError = "产品信息加载失败，请稍后重试"
                showError = true
                return
            }
            return
        }

        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                if let transaction = try? verification.payloadValue {
                    await handleTransaction(transaction)
                }
            case .userCancelled:
                break // 用户取消，不提示错误
            case .pending:
                purchaseError = "购买正在处理中，请稍后查看"
                showError = true
            @unknown default:
                purchaseError = "购买失败，请稍后重试"
                showError = true
            }
        } catch {
            purchaseError = "购买失败：\(error.localizedDescription)"
            showError = true
        }
    }

    /// 恢复购买
    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }

        do {
            for await result in Transaction.currentEntitlements {
                if let transaction = try? result.payloadValue,
                   transaction.productID == Self.proProductID {
                    await handleTransaction(transaction)
                    return
                }
            }
            purchaseError = "未找到已购买的项目，请确认您使用同一个Apple ID登录"
            showError = true
        } catch {
            purchaseError = "恢复购买失败：\(error.localizedDescription)"
            showError = true
        }
    }

    /// 处理交易
    private func handleTransaction(_ transaction: Transaction) async {
        // 验证产品ID
        guard transaction.productID == Self.proProductID else { return }

        // 更新Pro状态
        isProUnlocked = true
        UserDefaults.standard.set(true, forKey: "is_pro_unlocked")

        // 完成交易
        await transaction.finish()
    }

    /// 检查未完成的交易
    private func checkUnfinishedTransactions() async {
        for await result in Transaction.unfinished {
            if let transaction = try? result.payloadValue {
                await handleTransaction(transaction)
            }
        }
    }
}
