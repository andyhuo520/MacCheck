import SwiftUI
import AppKit

/// 详情面板路由：概览 / 硬件规格 / 各检测分类 / 交互测试。
struct DetailRouter: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        switch model.selection ?? .overview {
        case .overview:
            OverviewView()
        case .specs:
            SpecsView()
        case .keyboard:
            FullscreenLaunchPane(item: .keyboard, test: .keyboard,
                icon: "keyboard.fill", title: L("键盘测试", "Keyboard Test"),
                subtitle: L("全屏逐键点亮，按下的键即刻高亮，自动识别失灵与卡键。", "Full-screen key map: every key lights up as you press it, so dead or stuck keys stand out."))
        case .screen:
            FullscreenLaunchPane(item: .screen, test: .screen,
                icon: "display", title: L("屏幕测试", "Display Test"),
                subtitle: L("纯色、灰阶、棋盘格全套画面轮播，用于查找坏点、亮点、色带与漏光。", "Cycles through solid colors, grayscale and checkerboard patterns to reveal dead pixels, bright spots, banding and backlight bleed."))
        case .audio:
            AudioCheckView { model.recordTest($0) }
        case .microphone:
            MicrophoneCheckView { model.recordTest($0) }
        case .camera:
            CameraCheckView { model.recordTest($0) }
        case .touchID:
            TouchIDCheckView { model.recordTest($0) }
        case .trackpad:
            TrackpadCheckView { model.recordTest($0) }
        case .performance:
            PerformanceCheckView { model.recordTest($0) }
        case .diskSpeed:
            DiskSpeedCheckView { model.recordTest($0) }
        case .portsLive:
            PortLiveCheckView { model.recordTest($0) }
        case .aiModels:
            AIModelsView()
        case .history:
            HistoryView()
        case .settings:
            SettingsView()
        default:
            CategoryDetailView(item: model.selection ?? .overview)
        }
    }
}

// MARK: - 硬件规格（基础信息 · 系统 · 购买与保修）

struct SpecsView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.lg) {
                if let p = model.profile {
                    basicInfoCard(p)
                    systemCard(p)
                    warrantyCard(p)
                } else {
                    ProgressView(L("正在读取硬件规格…", "Reading hardware specs…"))
                }
            }
            .padding(DS.Spacing.xl)
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .navigationTitle(L("硬件规格", "Specs"))
    }

    // 基础信息
    private func basicInfoCard(_ p: DeviceProfile) -> some View {
        Card {
            cardHeader(icon: "laptopcomputer", title: L("基础信息", "Basics"))
            KeyValueList {
                KVRow(icon: "macbook", key: L("机型", "Model"), value: p.marketingName)
                KVRow(icon: "barcode", key: L("序列号", "Serial number"), value: p.serialNumber, mono: true, copyable: true)
                KVRow(icon: "tag", key: L("型号标识", "Model identifier"), value: p.modelIdentifier, mono: true)
                KVRow(icon: "cpu", key: L("芯片", "Chip"), value: p.chip)
                KVRow(icon: "memorychip", key: L("内存", "Memory"), value: p.memory)
                KVRow(icon: "internaldrive", key: L("磁盘容量", "Disk capacity"), value: diskCapacity)
                KVRow(icon: "square.stack.3d.up", key: L("架构", "Architecture"), value: p.architecture, last: true)
            }
        }
    }

    private var diskCapacity: String {
        let details = model.result(id: "storage")?.rawDetails ?? [:]
        let capacity = (details["容量"] ?? details["Capacity"] ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if !capacity.isEmpty { return capacity }
        return model.isScanning ? L("正在读取…", "Reading…") : L("未能读取", "Unavailable")
    }

    // 系统
    private func systemCard(_ p: DeviceProfile) -> some View {
        Card {
            cardHeader(icon: "gearshape", title: L("系统", "System"))
            KeyValueList {
                KVRow(icon: "apple.logo", key: L("操作系统", "macOS"), value: p.macOSVersion, last: true)
            }
        }
    }

    // 购买与保修
    private func warrantyCard(_ p: DeviceProfile) -> some View {
        let lock = model.result(id: "management.activationLock")
        return Card {
            cardHeader(icon: "checkmark.seal", title: L("购买与保修", "Purchase & Warranty"))
            KeyValueList {
                KVRow(icon: "calendar", key: L("机型年份", "Model year"), value: p.modelYear.isEmpty ? L("未知", "Unknown") : p.modelYear)
                KVRow(icon: "clock.arrow.circlepath", key: L("预计机龄", "Estimated age"), value: ageText(p.modelYear))
                KVRow(icon: "hammer", key: L("生产日期", "Manufacture date"), value: p.productionDate)
                KVRow(icon: "lock.shield",
                      key: L("激活锁", "Activation Lock"),
                      value: lock?.summary ?? L("见「安全与锁定」", "See \"Security & Locks\""),
                      valueTint: lock?.status.tint,
                      last: true)
            }

            InlineNotice(icon: "info.circle", tint: .secondary,
                text: L("保修状态与激活/购买日期需向 Apple 服务器查询，本 App 不联网因此无法直接读取。点击下方按钮用序列号在官网查询。", "Warranty status and activation/purchase date live on Apple's servers. This app works offline, so it can't read them. Use the button below to look them up on Apple's site with the serial number."))

            HStack(spacing: DS.Spacing.md) {
                Button {
                    if let url = URL(string: "https://checkcoverage.apple.com/") {
                        NSWorkspace.shared.open(url)
                    }
                } label: {
                    Label(L("在 Apple 官网查询保修", "Check Warranty on Apple.com"), systemImage: "safari")
                }
                .buttonStyle(.borderedProminent)

                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(p.serialNumber, forType: .string)
                } label: {
                    Label(L("复制序列号", "Copy Serial Number"), systemImage: "doc.on.doc")
                }
                .buttonStyle(.bordered)
                .disabled(p.serialNumber.isEmpty)
            }
        }
    }

    private func cardHeader(icon: String, title: String) -> some View {
        HStack(spacing: DS.Spacing.sm) {
            Image(systemName: icon).foregroundStyle(.tint).font(.system(size: 13, weight: .semibold))
            SectionLabel(text: title)
            Spacer()
        }
    }

    private func ageText(_ yearStr: String) -> String {
        guard let year = Int(yearStr) else { return L("未知", "Unknown") }
        let now = Calendar.current.component(.year, from: Date())
        let age = now - year
        if age <= 0 { return L("当年机型（约 1 年内）", "Current-year model (under ~1 year)") }
        return L("约 \(age) 年", age == 1 ? "About 1 year" : "About \(age) years")
    }
}

/// 优雅的键值列表：图标 + 名称在左，值在右，行间发丝分隔。
struct KeyValueList<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        VStack(spacing: 0) { content }
    }
}

struct KVRow: View {
    let icon: String
    let key: String
    let value: String
    var mono: Bool = false
    var copyable: Bool = false
    var valueTint: Color? = nil
    var last: Bool = false

    @State private var copied = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: DS.Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .frame(width: 18)
                Text(key).font(DS.Font.body).foregroundStyle(.secondary)
                Spacer(minLength: DS.Spacing.lg)
                Text(value)
                    .font(mono ? DS.Font.body.monospaced() : DS.Font.body)
                    .foregroundStyle(valueTint ?? .primary)
                    .multilineTextAlignment(.trailing)
                    .textSelection(.enabled)
                if copyable {
                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(value, forType: .string)
                        copied = true
                    } label: {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.borderless)
                    .help(L("复制", "Copy"))
                }
            }
            .padding(.vertical, DS.Spacing.sm)
            if !last { DS.Divider() }
        }
    }
}

// MARK: - 通用分类详情（电池 / 安全 / 存储 / 网络 / 接口）

struct CategoryDetailView: View {
    @EnvironmentObject private var model: AppModel
    let item: SidebarItem

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.lg) {
                let results = model.results(for: item)
                if results.isEmpty {
                    if model.isScanning {
                        ProgressView(L("正在检测…", "Checking…"))
                    } else {
                        InlineNotice(icon: "minus.circle", tint: .secondary, text: L("本机无此项数据或不适用。", "No data for this Mac, or not applicable."))
                    }
                } else {
                    ForEach(results) { result in
                        resultCard(result)
                    }
                }
            }
            .padding(DS.Spacing.xl)
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .navigationTitle(item.title)
    }

    private func resultCard(_ result: CheckResult) -> some View {
        Card {
            HStack(alignment: .top, spacing: DS.Spacing.md) {
                Image(systemName: result.status.symbolName)
                    .font(.system(size: 20)).foregroundStyle(result.status.tint)
                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                    HStack(spacing: DS.Spacing.sm) {
                        Text(result.title).font(DS.Font.bodyEmphasis)
                        StatusPill(status: result.status)
                    }
                    Text(result.summary).font(DS.Font.body).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
            }
            if let headline = result.isRedFlagHeadline {
                Text(headline)
                    .font(DS.Font.body)
                    .padding(DS.Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: DS.Radius.control).fill(Color.red.opacity(0.1)))
            }
            if !result.rawDetails.isEmpty {
                DS.Divider()
                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                    ForEach(result.rawDetails.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                        InfoRow(key: key, value: value, mono: true)
                    }
                }
            }
        }
    }
}

/// 小型状态药丸标签。
struct StatusPill: View {
    let status: CheckStatus
    var body: some View {
        Text(status.label)
            .font(.system(size: 10, weight: .semibold))
            .padding(.horizontal, DS.Spacing.sm)
            .padding(.vertical, 2)
            .background(Capsule().fill(status.tint.opacity(0.15)))
            .foregroundStyle(status.tint)
    }
}

// MARK: - 全屏测试启动面板（键盘 / 屏幕）

struct FullscreenLaunchPane: View {
    @EnvironmentObject private var model: AppModel
    let item: SidebarItem
    let test: FullscreenTest
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.lg) {
                CheckHeader(icon: icon, title: title, subtitle: subtitle)

                if let result = model.result(id: item.resultIDs.first ?? "") {
                    Card {
                        HStack(spacing: DS.Spacing.md) {
                            Image(systemName: result.status.symbolName)
                                .font(.system(size: 20)).foregroundStyle(result.status.tint)
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: DS.Spacing.sm) {
                                    Text(L("上次结果", "Last result")).font(DS.Font.bodyEmphasis)
                                    StatusPill(status: result.status)
                                }
                                Text(result.summary).font(DS.Font.body).foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                    }
                }

                Button {
                    model.fullscreenTest = test
                } label: {
                    Label(model.result(id: item.resultIDs.first ?? "") == nil ? L("开始测试", "Start Test") : L("重新测试", "Test Again"),
                          systemImage: "play.fill")
                        .frame(minWidth: 160)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                InlineNotice(icon: "info.circle", tint: .secondary,
                    text: L("测试将进入全屏。键盘测试期间长按 esc 键、或按 Cmd+Q 可随时安全退出。", "The test runs full screen. During the keyboard test, hold esc or press Cmd+Q to exit safely at any time."))
            }
            .padding(DS.Spacing.xl)
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .navigationTitle(title)
    }
}
