import SwiftUI
import SwiftData

/// Gravity App 入口
@main
struct GravityApp: App {
    /// SwiftData 模型容器
    let modelContainer: ModelContainer

    init() {
        do {
            // 注册持久化模型
            let schema = Schema([
                QuickCommandModel.self,
                ConnectionConfigModel.self,
            ])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("SwiftData 初始化失败: \(error)")
        }

        // 注入 ModelContext 到 DataStore
        Task { @MainActor in
            DataStore.shared.modelContext = modelContainer.mainContext
        }
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .modelContainer(modelContainer)
                .preferredColorScheme(.dark)
        }
    }
}
