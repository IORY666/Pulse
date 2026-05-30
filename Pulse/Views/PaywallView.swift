import SwiftUI

/// Pro付费墙视图 — 硬付费墙，一次买断
struct PaywallView: View {
    @Environment(StoreManager.self) private var storeManager
    @Environment(\.dismiss) private var dismiss
    @State private var isPurchasing = false
    @State private var isRestoring = false
    @State private var animateFeatures = false

    /// Pro功能列表
    private let proFeatures: [(icon: String, title: String, description: String, color: Color)] = [
        ("infinity", "无限习惯", "不再局限于3个，添加所有你想养成的习惯", .blue),
        ("paintpalette.fill", "精美主题", "10+款精心设计的Widget主题和App配色", .purple),
        ("icloud.fill", "iCloud同步", "多设备数据自动同步，换手机也不丢失", .cyan),
        ("tablecells.fill", "数据导出", "一键导出CSV，分析你的习惯数据", .green),
        ("bell.badge.fill", "智能提醒", "自定义多个提醒时间，不再忘记打卡", .orange),
        ("sparkles", "永久更新", "一次购买终身使用，未来所有新功能免费", .yellow),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // 顶部标语
                    headerSection
                        .padding(.top, 32)

                    // 功能列表
                    featuresSection
                        .padding(.top, 32)

                    // 价格按钮
                    purchaseSection
                        .padding(.top, 32)
                        .padding(.bottom, 16)

                    // 恢复购买
                    Button {
                        Task {
                            isRestoring = true
                            await storeManager.restorePurchases()
                            isRestoring = false
                            if storeManager.isProUnlocked {
                                dismiss()
                            }
                        }
                    } label: {
                        Text(isRestoring ? "正在恢复..." : "恢复购买")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .disabled(isRestoring)

                    // 保障信息
                    HStack(spacing: 16) {
                        guaranteeItem(icon: "lock.shield.fill", text: "隐私安全")
                        guaranteeItem(icon: "checkmark.seal.fill", text: "一次买断")
                        guaranteeItem(icon: "arrow.trianglehead.clockwise", text: "支持退款")
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 32)
                }
                .padding(.horizontal, 24)
            }
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 0.5).delay(0.3)) {
                    animateFeatures = true
                }
            }
            .onChange(of: storeManager.isProUnlocked) { _, isPro in
                if isPro {
                    dismiss()
                }
            }
            .alert("购买提示", isPresented: $storeManager.showError) {
                Button("确定") {}
            } message: {
                Text(storeManager.purchaseError ?? "未知错误")
            }
        }
    }

    // MARK: - 头部区域

    private var headerSection: some View {
        VStack(spacing: 16) {
            // 图标
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [.orange, .pink, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                Image(systemName: "crown.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.white)
            }

            Text("升级到 Pulse Pro")
                .font(.title2)
                .fontWeight(.bold)

            Text("无限习惯 · 精美主题 · iCloud同步")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - 功能列表

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("解锁全部功能")
                .font(.headline)
                .padding(.bottom, 4)

            ForEach(Array(proFeatures.enumerated()), id: \.offset) { index, feature in
                HStack(spacing: 14) {
                    Image(systemName: feature.icon)
                        .font(.body)
                        .foregroundStyle(feature.color)
                        .frame(width: 32, height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(feature.color.opacity(0.12))
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(feature.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text(feature.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .opacity(animateFeatures ? 1 : 0)
                .offset(x: animateFeatures ? 0 : 20)
                .animation(
                    .spring(response: 0.5, dampingFraction: 0.8)
                        .delay(0.1 * Double(index)),
                    value: animateFeatures
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
    }

    // MARK: - 购买区域

    private var purchaseSection: some View {
        VStack(spacing: 12) {
            // 价格展示
            VStack(spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("¥")
                        .font(.title3)
                        .foregroundStyle(.orange)
                    Text("36")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                }

                Text("一次性购买 · 永久使用 · 无需订阅")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                // 对比订阅的说服信息
                HStack(spacing: 4) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.red)
                    Text("不搞订阅")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .strikethrough()
                    Text("·")
                        .foregroundStyle(.secondary)
                    Text("≈ 其他App 2个月订阅费")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 2)
            }

            // 购买按钮
            Button {
                Task {
                    isPurchasing = true
                    await storeManager.purchasePro()
                    isPurchasing = false
                }
            } label: {
                HStack {
                    Spacer()
                    if isPurchasing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "crown.fill")
                        Text("立即解锁 Pro")
                            .fontWeight(.bold)
                    }
                    Spacer()
                }
                .foregroundStyle(.white)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [.orange, .pink],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: 16)
                )
            }
            .disabled(isPurchasing)
            .buttonStyle(.plain)

            // 退款保障
            Text("购买后如不满意，可通过Apple申请退款")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
    }

    // MARK: - 保障项

    private func guaranteeItem(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(text)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - 预览

#Preview {
    PaywallView()
        .environment(StoreManager.shared)
}
