import SwiftUI
import SwiftData

/// Pulse · 极简习惯打卡 — App入口
@main
struct PulseApp: App {
    /// 主题管理器
    @State private var themeManager = ThemeManager.shared
    /// 内购管理器
    @State private var storeManager = StoreManager.shared
    /// 习惯ViewModel
    @State private var habitViewModel = HabitViewModel()

    /// SwiftData模型容器 - iCloud自动同步
    var modelContainer: ModelContainer = {
        let schema = Schema([Habit.self, HabitRecord.self])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // 如果iCloud配置失败，回退到纯本地存储
            print("⚠️ iCloud配置失败，使用本地存储: \(error)")
            do {
                let localConfig = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: false
                )
                return try ModelContainer(for: schema, configurations: [localConfig])
            } catch {
                fatalError("无法创建数据容器: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
                .environment(habitViewModel)
                .environment(storeManager)
                .environment(themeManager)
                .preferredColorScheme(themeManager.preferredColorScheme)
                .onAppear {
                    // 初始化ViewModel的上下文
                    habitViewModel.configure(with: modelContainer.mainContext)
                    // 加载IAP产品
                    Task {
                        await storeManager.loadProduct()
                    }
                }
        }
    }
}
