import SwiftUI

/// 活跃终端会话列表（仪表盘底部）
struct ActiveSessionsList: View {
    let sessions: [(id: String, name: String, isRunning: Bool, lastOutput: String, lineCount: Int)]
    var onTap: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("活跃终端")
                .font(.caption)
                .foregroundColor(GravityColors.textSecondary)
                .padding(.horizontal, 4)

            if sessions.isEmpty {
                HStack {
                    Image(systemName: "terminal")
                        .foregroundColor(GravityColors.textSecondary)
                    Text("暂无活跃会话")
                        .font(.system(size: 13))
                        .foregroundColor(GravityColors.textSecondary)
                }
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(GravityColors.cardBackground)
                .cornerRadius(8)
            } else {
                ForEach(sessions, id: \.id) { session in
                    Button(action: { onTap(session.id) }) {
                        HStack(spacing: 8) {
                            // 状态灯
                            Circle()
                                .fill(session.isRunning ? GravityColors.success : GravityColors.textSecondary)
                                .frame(width: 6, height: 6)

                            // 会话信息
                            VStack(alignment: .leading, spacing: 2) {
                                Text(session.name)
                                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                                    .foregroundColor(GravityColors.textPrimary)
                                    .lineLimit(1)

                                Text("\(session.lineCount) 行 · \(session.lastOutput)")
                                    .font(.system(size: 11))
                                    .foregroundColor(GravityColors.textSecondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 10))
                                .foregroundColor(GravityColors.textSecondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(GravityColors.cardBackground)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

#Preview {
    ActiveSessionsList(
        sessions: [
            (id: "1", name: "终端 #1", isRunning: true, lastOutput: "3分钟前", lineCount: 245),
            (id: "2", name: "npm run dev", isRunning: true, lastOutput: "刚刚", lineCount: 89),
        ],
        onTap: { _ in }
    )
    .padding()
    .background(GravityColors.background)
    .preferredColorScheme(.dark)
}
