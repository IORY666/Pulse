import SwiftUI
import SwiftData

/// Gravity App 入口
@main
struct GravityApp: App {
    /// SwiftData 模型容器
    let modelContainer: ModelContainer

    init() {
        let container: ModelContainer
        do {
            let schema = Schema([
                QuickCommandModel.self,
                ConnectionConfigModel.self,
            ])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("SwiftData 初始化失败: \(error)")
        }
        modelContainer = container

        Task { @MainActor in
            DataStore.shared.modelContext = container.mainContext
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
