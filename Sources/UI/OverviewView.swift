import SwiftUI

/// 概览页：打开即见。机器档案头部 + 综合评分 + 红旗区 + 各分类状态一览（可点击跳转）。
struct OverviewView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.xl) {
                deviceHeader
                if !model.report.redFlags.isEmpty { redFlagSection }
                categorySummary
                testSummary
                footer
            }
            .padding(DS.Spacing.xl)
            .frame(maxWidth: 780)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .navigationTitle(L("概览", "Overview"))
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    model.saveCurrentToHistory()
                } label: {
                    Label(L("保存到历史", "Save to History"), systemImage: "square.and.arrow.down")
                }
                .disabled(model.isScanning || model.profile == nil)
                .help(L("保存本次检测快照，便于日后对比（如电池衰减）", "Save a snapshot of this check to compare later (e.g. battery wear)"))
            }
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        ReportExporter.export(profile: model.profile, report: model.report, format: .png)
                    } label: { Label(L("导出为长图 (PNG)", "Export as Long Image (PNG)"), systemImage: "photo") }
                    Button {
                        ReportExporter.export(profile: model.profile, report: model.report, format: .pdf)
                    } label: { Label(L("导出为 PDF", "Export as PDF"), systemImage: "doc.richtext") }
                } label: {
                    Label(L("导出报告", "Export Report"), systemImage: "square.and.arrow.up")
                }
                .disabled(model.isScanning)
            }
        }
    }

    // MARK: - 机器档案头部

    private var deviceHeader: some View {
        Card {
            HStack(alignment: .top, spacing: DS.Spacing.lg) {
                Image(systemName: deviceSymbol)
                    .font(.system(size: 46))
                    .foregroundStyle(.tint)
                    .frame(width: 64)
                VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                    Text(model.profile?.marketingName ?? L("正在识别机型…", "Identifying model…"))
                        .font(DS.Font.largeTitle)
                        .fixedSize(horizontal: false, vertical: true)
                    if let p = model.profile {
                        Text("\(p.chip) · \(p.memory) · \(p.macOSVersion)")
                            .font(DS.Font.body).foregroundStyle(.secondary)
                        HStack(spacing: DS.Spacing.sm) {
                            metaChip(icon: "barcode", text: p.serialNumber.isEmpty ? L("序列号未知", "Serial number unknown") : p.serialNumber)
                            metaChip(icon: "cpu", text: p.architecture)
                            if !p.modelYear.isEmpty {
                                metaChip(icon: "calendar", text: L("\(p.modelYear) 年款", "\(p.modelYear) model"))
                            }
                        }
                    }
                }
                Spacer(minLength: DS.Spacing.md)
                scoreBadge
            }
        }
    }

    /// 统一的元信息小胶囊，避免旧版三个 Label 直接换行挤在一起。
    private func metaChip(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 10))
            Text(text).font(DS.Font.caption)
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, DS.Spacing.sm)
        .padding(.vertical, 3)
        .background(Capsule().fill(Color.secondary.opacity(0.1)))
    }

    private var scoreBadge: some View {
        VStack(spacing: 2) {
            Text("\(model.report.score)")
                .font(.system(size: 40, weight: .heavy))
                .foregroundStyle(scoreColor)
                .contentTransition(.numericText())
            Text(L("综合评分", "Overall score")).font(DS.Font.caption).foregroundStyle(.secondary)
        }
    }

    private var scoreColor: Color {
        if !model.report.redFlags.isEmpty || model.report.score < 60 { return .red }
        if model.report.score < 90 { return .orange }
        return .green
    }

    private var deviceSymbol: String {
        let name = model.profile?.marketingName ?? ""
        if name.contains("mini") || name.contains("Mac Pro") || name.contains("Studio") { return "macstudio.fill" }
        if name.contains("iMac") { return "desktopcomputer" }
        if name.contains("Air") { return "macbook" }
        return "macbook"
    }

    // MARK: - 红旗区

    private var redFlagSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            Label(L("重大问题 · 请优先阅读", "Major Issues · Read First"), systemImage: "exclamationmark.octagon.fill")
                .font(DS.Font.title).foregroundStyle(.red)
            ForEach(model.report.redFlags) { flag in
                HStack(alignment: .top, spacing: DS.Spacing.sm) {
                    Text(flag.isRedFlagHeadline ?? flag.summary)
                        .font(DS.Font.body)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                }
                .padding(DS.Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: DS.Radius.control).fill(Color.red.opacity(0.1)))
                .overlay(RoundedRectangle(cornerRadius: DS.Radius.control).strokeBorder(Color.red.opacity(0.25)))
            }
        }
    }

    // MARK: - 分类状态一览

    private var categorySummary: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            SectionLabel(text: L("系统检测", "System Checks"))
            Card {
                ForEach(Array(SidebarItem.autoCategories.enumerated()), id: \.element) { index, item in
                    summaryRow(item)
                    if index < SidebarItem.autoCategories.count - 1 { DS.Divider() }
                }
            }
        }
    }

    private var testSummary: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            HStack {
                SectionLabel(text: L("硬件测试", "Hardware Tests"))
                Spacer()
                Text(L("\(model.completedTestCount) / \(SidebarItem.interactiveTests.count) 已测试", "\(model.completedTestCount) of \(SidebarItem.interactiveTests.count) tested"))
                    .font(DS.Font.caption).foregroundStyle(.secondary)
            }
            Card {
                ForEach(Array(SidebarItem.interactiveTests.enumerated()), id: \.element) { index, item in
                    summaryRow(item)
                    if index < SidebarItem.interactiveTests.count - 1 { DS.Divider() }
                }
            }
        }
    }

    private func summaryRow(_ item: SidebarItem) -> some View {
        Button {
            model.selection = item
        } label: {
            HStack(spacing: DS.Spacing.md) {
                Image(systemName: item.icon).frame(width: 22).foregroundStyle(.tint)
                Text(item.title).font(DS.Font.bodyEmphasis)
                Spacer()
                if item == .specs {
                    Text(hardwareSpecsSummary)
                        .font(DS.Font.caption).foregroundStyle(.secondary)
                        .lineLimit(1).truncationMode(.tail).frame(maxWidth: 320, alignment: .trailing)
                    Image(systemName: "chevron.right").font(.system(size: 10)).foregroundStyle(.tertiary)
                } else if let status = model.status(for: item) {
                    Text(model.results(for: item).first?.summary ?? status.label)
                        .font(DS.Font.caption).foregroundStyle(.secondary)
                        .lineLimit(1).truncationMode(.tail).frame(maxWidth: 320, alignment: .trailing)
                    StatusDot(status: status)
                } else {
                    Text(item.isInteractive ? L("未测试", "Not tested") : "—")
                        .font(DS.Font.caption).foregroundStyle(.tertiary)
                    Image(systemName: "chevron.right").font(.system(size: 10)).foregroundStyle(.tertiary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var hardwareSpecsSummary: String {
        guard let profile = model.profile else {
            return model.isScanning ? L("正在读取硬件信息…", "Reading hardware info…") : L("查看硬件详情", "View hardware details")
        }
        let chip = profile.chip.trimmingCharacters(in: .whitespacesAndNewlines)
        let memory = profile.memory.trimmingCharacters(in: .whitespacesAndNewlines)
        let storageDetails = model.result(id: "storage")?.rawDetails ?? [:]
        let capacity = (storageDetails["容量"] ?? storageDetails["Capacity"] ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = [
            chip,
            memory.isEmpty ? "" : L("\(memory) 内存", "\(memory) memory"),
            capacity.isEmpty ? "" : L("\(capacity) 磁盘", "\(capacity) storage"),
        ].filter { !$0.isEmpty }
        return parts.isEmpty ? L("查看硬件详情", "View hardware details") : parts.joined(separator: " · ")
    }

    // MARK: - 底部

    private var footer: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
            DS.Divider()
            Text(L("检测时间：\(model.generatedAt.formatted(date: .abbreviated, time: .shortened)) · MacCheck v\(model.report.appVersion)", "Checked: \(model.generatedAt.formatted(date: .abbreviated, time: .shortened)) · MacCheck v\(model.report.appVersion)"))
            Text(L("本 App 完全本地运行，不联网、不上传任何数据。检测结果仅供参考，不构成质保。", "This app runs entirely on your Mac. It never goes online or uploads anything. Results are for reference only and are not a warranty."))
        }
        .font(DS.Font.caption).foregroundStyle(.secondary)
        .padding(.top, DS.Spacing.sm)
    }
}
