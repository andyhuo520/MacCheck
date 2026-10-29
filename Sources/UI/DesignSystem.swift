import SwiftUI

/// 设计系统 —— 遵循 Apple HIG 与 Jony Ive 的克制美学：
/// 中性底色为主、语义色克制使用、清晰的字号层级、一致的圆角与留白。
/// 全局统一入口 `DS`，避免各视图各写各的魔法数字。
enum DS {

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 20
        static let xl: CGFloat = 28
    }

    enum Radius {
        static let card: CGFloat = 12
        static let control: CGFloat = 8
        static let pill: CGFloat = 999
    }

    enum Font {
        static let largeTitle = SwiftUI.Font.system(size: 26, weight: .bold)
        static let title = SwiftUI.Font.system(size: 19, weight: .semibold)
        static let section = SwiftUI.Font.system(size: 12, weight: .semibold)   // 分区小标题（全大写间距）
        static let body = SwiftUI.Font.system(size: 13)
        static let bodyEmphasis = SwiftUI.Font.system(size: 13, weight: .semibold)
        static let caption = SwiftUI.Font.system(size: 11)
        static let mono = SwiftUI.Font.system(size: 11, design: .monospaced)
    }

    enum Color {
        static let cardBackground = SwiftUI.Color(nsColor: .controlBackgroundColor)
        static let windowBackground = SwiftUI.Color(nsColor: .windowBackgroundColor)
        static let hairline = SwiftUI.Color.primary.opacity(0.08)
        static let secondaryText = SwiftUI.Color.secondary
    }

    /// 细分隔线（Ive 风格常用发丝级分隔而非粗线）。
    static func Divider() -> some View {
        Rectangle().fill(Color.hairline).frame(height: 1)
    }
}

// MARK: - 状态语义（统一用 SF Symbol + 语义色，不用 emoji，更专业）

extension CheckStatus {
    var symbolName: String {
        switch self {
        case .pass: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .redFlag: return "exclamationmark.octagon.fill"
        case .skipped: return "minus.circle"
        case .unsupported: return "minus.circle"
        }
    }

    var tint: Color {
        switch self {
        case .pass: return .green
        case .warning: return .orange
        case .redFlag: return .red
        case .skipped, .unsupported: return .secondary
        }
    }

    var label: String {
        switch self {
        case .pass: return L("正常", "Passed")
        case .warning: return L("注意", "Warning")
        case .redFlag: return L("严重", "Major issue")
        case .skipped: return L("已跳过", "Skipped")
        case .unsupported: return L("不适用", "Not supported")
        }
    }
}

// MARK: - 复用组件

/// 状态圆点徽章（侧边栏、卡片右上角用）。
struct StatusDot: View {
    let status: CheckStatus
    var body: some View {
        Image(systemName: status.symbolName)
            .font(.system(size: 13))
            .foregroundStyle(status.tint)
    }
}

/// 交互测试详情页顶部标题块。
struct CheckHeader: View {
    let icon: String
    let title: String
    let subtitle: String
    var body: some View {
        HStack(alignment: .top, spacing: DS.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 26))
                .foregroundStyle(.tint)
                .frame(width: 40)
            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                Text(title).font(DS.Font.title)
                Text(subtitle).font(DS.Font.body).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

/// 行内提示条（权限被拒、需注意等）。
struct InlineNotice: View {
    let icon: String
    let tint: Color
    let text: String
    var body: some View {
        HStack(alignment: .top, spacing: DS.Spacing.sm) {
            Image(systemName: icon).foregroundStyle(tint)
            Text(text).font(DS.Font.body).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding(DS.Spacing.md)
        .background(RoundedRectangle(cornerRadius: DS.Radius.control).fill(tint.opacity(0.1)))
    }
}

/// 分区小标题（全大写字距，Ive/HIG 常见的分组标签样式）。
struct SectionLabel: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(DS.Font.section)
            .tracking(0.6)
            .foregroundStyle(.secondary)
    }
}

/// 键值信息行。
struct InfoRow: View {
    let key: String
    let value: String
    var mono: Bool = false
    var body: some View {
        HStack(alignment: .top) {
            Text(key).font(DS.Font.body).foregroundStyle(.secondary)
            Spacer(minLength: DS.Spacing.lg)
            Text(value).font(mono ? DS.Font.body.monospaced() : DS.Font.body)
                .multilineTextAlignment(.trailing)
                .textSelection(.enabled)
        }
    }
}

extension View {
    /// 交互测试页统一容器：套 ScrollView（自动避开标题栏、内容过高可滚动）+ 居中 + 标题。
    /// 解决交互页不在 ScrollView 里时内容顶到标题栏下方被遮挡的问题。
    func checkPane(_ title: String) -> some View {
        ScrollView {
            self
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .navigationTitle(title)
    }
}

/// 统一卡片容器。
struct Card<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            content
        }
        .padding(DS.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: DS.Radius.card).fill(DS.Color.cardBackground))
        .overlay(RoundedRectangle(cornerRadius: DS.Radius.card).strokeBorder(DS.Color.hairline))
    }
}
