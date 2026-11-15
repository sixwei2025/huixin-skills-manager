import SwiftUI

private let featureCardBackground = Color.primary.opacity(0.10)
private let featureCardRadius: CGFloat = 12

struct CommandPaletteView: View {
    @ObservedObject var store: SkillStore
    @ObservedObject var usageTracker: UsageTracker
    let onBack: () -> Void
    let onSelectSkill: (Skill) -> Void
    let onSelectAgent: (Agent) -> Void
    let onSelectPlugin: (Plugin) -> Void
    let onSelectCollection: (SkillCollection) -> Void
    let onSelectProject: (ProjectSkillRoot) -> Void
    let onOpenScreen: (SkillsBarToolScreen) -> Void
    let onCopyTrigger: (Skill) -> Void
    let onOpenSkillInEditor: (Skill) -> Void
    let onRefresh: () -> Void

    @State private var query = ""
    @FocusState private var focused: Bool

    private enum PaletteItem: Identifiable {
        case screen(SkillsBarToolScreen)
        case skill(Skill)
        case agent(Agent)
        case plugin(Plugin)
        case collection(SkillCollection)
        case project(ProjectSkillRoot)
        case action(id: String, title: String, detail: String, iconName: String, action: () -> Void)

        var id: String {
            switch self {
            case .screen(let screen):
                return "screen-\(screen.rawValue)"
            case .skill(let skill):
                return "skill-\(skill.id)"
            case .agent(let agent):
                return "agent-\(agent.id)"
            case .plugin(let plugin):
                return "plugin-\(plugin.id)"
            case .collection(let collection):
                return "collection-\(collection.id.uuidString)"
            case .project(let project):
                return "project-\(project.id.uuidString)"
            case .action(let id, _, _, _, _):
                return "action-\(id)"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            featureHeader(title: "快捷操作", subtitle: "Search everything", onBack: onBack)

            Divider()

            VStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "command")
                        .foregroundStyle(.secondary)
                    TextField("Search skills, agents, plugins, projects, tools, actions", text: $query)
                        .textFieldStyle(.plain)
                        .focused($focused)
                        .onSubmit(openFirstItem)
                    if !query.isEmpty {
                        Button {
                            query = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.tertiary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(11)
                .background(featureCardBackground)
                .clipShape(RoundedRectangle(cornerRadius: featureCardRadius))

                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(filteredItems) { item in
                            paletteRow(item)
                        }
                    }
                }
                .frame(maxHeight: SkillsBarLayout.mainScrollHeight)
            }
            .padding(14)
        }
        .frame(width: SkillsBarLayout.windowWidth, height: SkillsBarLayout.detailHeight)
        .onAppear {
            DispatchQueue.main.async { focused = true }
        }
    }

    private var filteredItems: [PaletteItem] {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let items = allItems
        guard !normalizedQuery.isEmpty else { return Array(items.prefix(80)) }
        return items.filter { item in
            paletteSearchText(for: item).contains(normalizedQuery)
        }
        .prefix(80)
        .map { $0 }
    }

    private var allItems: [PaletteItem] {
        let screens: [PaletteItem] = SkillsBarToolScreen.allCases
            .filter { $0 != .commandPalette }
            .map { .screen($0) }

        let actions: [PaletteItem] = [
            .action(id: "refresh", title: "Refresh all", detail: "Rescan skills, agents, plugins, and usage", iconName: "arrow.clockwise", action: onRefresh),
        ]

        return screens +
            actions +
            store.allSkills.map { .skill($0) } +
            store.allAgents.map { .agent($0) } +
            store.plugins.map { .plugin($0) } +
            store.orderedCollections.map { .collection($0) } +
            store.orderedProjectSkillRoots.map { .project($0) }
    }

    @ViewBuilder
    private func paletteRow(_ item: PaletteItem) -> some View {
        switch item {
        case .screen(let screen):
            commandRow(
                iconName: screen.iconName,
                title: screen.title,
                detail: "Open tool",
                badge: "Tool",
                action: { onOpenScreen(screen) }
            )
        case .skill(let skill):
            commandRow(
                iconName: skill.source.iconName,
                title: skill.displayName,
                detail: "\(skill.triggerCommand) - \(skill.source.shortScopeLabel)",
                badge: "技能",
                action: { onSelectSkill(skill) },
                trailing: {
                    compactRowButton("Copy", systemImage: "doc.on.doc") { onCopyTrigger(skill) }
                    compactRowButton("Open", systemImage: "chevron.left.forwardslash.chevron.right") { onOpenSkillInEditor(skill) }
                }
            )
        case .agent(let agent):
            commandRow(
                iconName: "person.crop.circle",
                title: agent.displayName,
                detail: "\(agent.identifier) - \(agent.source.sectionTitle)",
                badge: "Agent",
                action: { onSelectAgent(agent) }
            )
        case .plugin(let plugin):
            commandRow(
                iconName: "shippingbox",
                title: plugin.displayName,
                detail: plugin.version.map { "v\($0)" } ?? plugin.shortDescription,
                badge: "插件",
                action: { onSelectPlugin(plugin) }
            )
        case .collection(let collection):
            commandRow(
                iconName: collection.iconName,
                title: collection.name,
                detail: "\(collection.skillPaths.count) saved paths",
                badge: "Collection",
                action: { onSelectCollection(collection) }
            )
        case .project(let project):
            commandRow(
                iconName: project.isPinned ? "pin.fill" : "folder",
                title: project.name,
                detail: project.path,
                badge: "项目",
                action: { onSelectProject(project) }
            )
        case .action(_, let title, let detail, let iconName, let action):
            commandRow(
                iconName: iconName,
                title: title,
                detail: detail,
                badge: "Action",
                action: action
            )
        }
    }

    private func commandRow<Trailing: View>(
        iconName: String,
        title: String,
        detail: String,
        badge: String,
        action: @escaping () -> Void,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                paletteIcon(iconName)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(.system(size: 13, weight: .medium))
                            .lineLimit(1)
                        Text(badge)
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.12))
                            .foregroundStyle(.secondary)
                            .clipShape(Capsule())
                    }
                    Text(detail)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()
                trailing()
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(featureCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    private func commandRow(
        iconName: String,
        title: String,
        detail: String,
        badge: String,
        action: @escaping () -> Void
    ) -> some View {
        commandRow(iconName: iconName, title: title, detail: detail, badge: badge, action: action) {
            Image(systemName: "return")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
    }

    private func compactRowButton(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 11, weight: .semibold))
                .frame(width: 22, height: 22)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
        .help(title)
    }

    @ViewBuilder
    private func paletteIcon(_ iconName: String) -> some View {
        if iconName == "ClaudeLogo" || iconName == "CodexLogo" {
            Image(iconName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 18, height: 18)
        } else {
            Image(systemName: iconName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 18, height: 18)
        }
    }

    private func paletteSearchText(for item: PaletteItem) -> String {
        switch item {
        case .screen(let screen):
            return "\(screen.title) \(screen.rawValue) tool".lowercased()
        case .skill(let skill):
            return "\(skill.displayName) \(skill.description) \(skill.triggerCommand) \(skill.path) \(skill.source.shortScopeLabel)".lowercased()
        case .agent(let agent):
            return "\(agent.displayName) \(agent.description) \(agent.identifier) \(agent.path) \(agent.source.sectionTitle)".lowercased()
        case .plugin(let plugin):
            return "\(plugin.displayName) \(plugin.shortDescription) \(plugin.version ?? "") \(plugin.path)".lowercased()
        case .collection(let collection):
            return "\(collection.name) collection".lowercased()
        case .project(let project):
            return "\(project.name) \(project.path) project".lowercased()
        case .action(_, let title, let detail, _, _):
            return "\(title) \(detail) action".lowercased()
        }
    }

    private func openFirstItem() {
        guard let first = filteredItems.first else { return }
        switch first {
        case .screen(let screen):
            onOpenScreen(screen)
        case .skill(let skill):
            onSelectSkill(skill)
        case .agent(let agent):
            onSelectAgent(agent)
        case .plugin(let plugin):
            onSelectPlugin(plugin)
        case .collection(let collection):
            onSelectCollection(collection)
        case .project(let project):
            onSelectProject(project)
        case .action(_, _, _, _, let action):
            action()
        }
    }
}

struct SkillHealthView: View {
    @ObservedObject var store: SkillStore
    @ObservedObject var usageTracker: UsageTracker
    let onBack: () -> Void
    let onSelectSkillPath: (String) -> Void
    let onRefresh: () -> Void
    let onToast: (String) -> Void

    private var issues: [SkillHealthIssue] {
        store.skillHealthIssues(usageTracker: usageTracker)
    }

    var body: some View {
        VStack(spacing: 0) {
            featureHeader(title: "Skill Health", subtitle: "\(issues.count) checks need attention", onBack: onBack)
            Divider()
            ScrollView {
                VStack(spacing: 10) {
                    healthSummaryCard
                    healthActionsCard
                    if issues.isEmpty {
                        emptyFeatureState(icon: "checkmark.seal", title: "Everything looks healthy", detail: "No invalid frontmatter, missing descriptions, duplicate triggers, missing collection paths, unreadable folders, or stale pins were found.")
                    } else {
                        ForEach(SkillHealthCategory.allCases) { category in
                            let categoryIssues = issues.filter { $0.category == category }
                            if !categoryIssues.isEmpty {
                                healthCategoryCard(category, issues: categoryIssues)
                            }
                        }
                    }
                }
                .padding(14)
            }
        }
        .frame(width: SkillsBarLayout.windowWidth, height: SkillsBarLayout.detailHeight)
    }

    private var healthSummaryCard: some View {
        HStack(spacing: 8) {
            healthMetric("Critical", issues.filter { $0.severity == .critical }.count, color: .red)
            healthMetric("Warnings", issues.filter { $0.severity == .warning }.count, color: .orange)
            healthMetric("Info", issues.filter { $0.severity == .info }.count, color: .blue)
        }
        .padding(12)
        .background(featureCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: featureCardRadius))
    }

    private var healthActionsCard: some View {
        HStack(spacing: 10) {
            Button("刷新") {
                onRefresh()
            }
            Button("Clean Stale Pins") {
                let count = store.clearStalePinnedItems()
                onToast(count == 1 ? "Cleared 1 stale pin" : "Cleared \(count) stale pins")
            }
            Button("Clear Missing Collection Paths") {
                let count = store.clearAllMissingCollectionPaths()
                onToast(count == 1 ? "Cleared 1 missing path" : "Cleared \(count) missing paths")
            }
        }
        .font(.system(size: 12, weight: .medium))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(featureCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: featureCardRadius))
    }

    private func healthMetric(_ title: String, _ count: Int, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundStyle(color)
            Text(title)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func healthCategoryCard(_ category: SkillHealthCategory, issues: [SkillHealthIssue]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle(category.title, count: issues.count)
            ForEach(issues) { issue in
                Divider()
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: severityIcon(issue.severity))
                        .foregroundStyle(severityColor(issue.severity))
                        .frame(width: 18)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(issue.title)
                            .font(.system(size: 13, weight: .medium))
                        Text(issue.detail)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                    if let skillPath = issue.skillPath {
                        Button("Open") {
                            onSelectSkillPath(skillPath)
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.blue)
                    } else if let path = issue.path {
                        Button("Reveal") {
                            NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "")
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.blue)
                    }
                }
            }
        }
        .padding(12)
        .background(featureCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: featureCardRadius))
    }
}

struct InstructionsHubView: View {
    @ObservedObject var store: SkillStore
    let preferredEditor: ExternalEditor
    let onBack: () -> Void

    private var items: [InstructionHubItem] {
        store.instructionHubItems()
    }

    var body: some View {
        VStack(spacing: 0) {
            featureHeader(title: "规则文件", subtitle: "Global and project instruction files", onBack: onBack)
            Divider()
            ScrollView {
                VStack(spacing: 10) {
                    instructionSection("GLOBAL", items: items.filter { $0.scope == .global })
                    instructionSection("PROJECTS", items: items.filter { $0.scope == .project })
                }
                .padding(14)
            }
        }
        .frame(width: SkillsBarLayout.windowWidth, height: SkillsBarLayout.detailHeight)
    }

    private func instructionSection(_ title: String, items: [InstructionHubItem]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle(title, count: items.count)
            ForEach(items) { item in
                Divider()
                HStack(spacing: 8) {
                    Image(systemName: item.exists ? "doc.text" : "doc.badge.plus")
                        .foregroundStyle(instructionTint(item))
                        .frame(width: 18)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(instructionTitle(item))
                            .font(.system(size: 13, weight: .medium))
                        Text(item.path)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                    countPill(item.healthTitle)
                    Button(item.exists ? "Open" : "Create") {
                        SkillStore.open(URL(fileURLWithPath: item.path), in: preferredEditor)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.blue)
                }
            }
        }
        .padding(12)
        .background(featureCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: featureCardRadius))
    }

    private func instructionTitle(_ item: InstructionHubItem) -> String {
        if let projectName = item.projectName {
            return "\(projectName): \(item.displayName)"
        }
        return item.displayName
    }

    private func instructionTint(_ item: InstructionHubItem) -> Color {
        if !item.exists || !item.isReadable { return .orange }
        if item.isEmpty { return .yellow }
        return .blue
    }
}

private func featureHeader(title: String, subtitle: String, onBack: @escaping () -> Void) -> some View {
    HStack {
        Button(action: onBack) {
            HStack(spacing: 4) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 13, weight: .semibold))
                Text("返回")
                    .font(.system(size: 14))
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(.blue)

        Spacer()

        VStack(spacing: 1) {
            Text(title)
                .font(.system(size: 16, weight: .bold))
            Text(subtitle)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }

        Spacer()

        Color.clear.frame(width: 52, height: 1)
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 12)
}

private func sectionTitle(_ title: String, count: Int?) -> some View {
    HStack(spacing: 6) {
        Text(title)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.secondary)
            .tracking(0.5)
        if let count {
            countPill("\(count)")
        }
        Spacer()
    }
}

private func countPill(_ text: String) -> some View {
    Text(text)
        .font(.system(size: 10, weight: .medium))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.secondary.opacity(0.12))
        .clipShape(Capsule())
}

private func emptyFeatureState(icon: String, title: String, detail: String) -> some View {
    VStack(spacing: 10) {
        Image(systemName: icon)
            .font(.system(size: 30))
            .foregroundStyle(.secondary)
        Text(title)
            .font(.system(size: 15, weight: .semibold))
        Text(detail)
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 18)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 36)
    .background(featureCardBackground)
    .clipShape(RoundedRectangle(cornerRadius: featureCardRadius))
}

private func severityIcon(_ severity: SkillHealthSeverity) -> String {
    switch severity {
    case .critical:
        return "xmark.octagon.fill"
    case .warning:
        return "exclamationmark.triangle.fill"
    case .info:
        return "info.circle.fill"
    }
}

private func severityColor(_ severity: SkillHealthSeverity) -> Color {
    switch severity {
    case .critical:
        return .red
    case .warning:
        return .orange
    case .info:
        return .blue
    }
}


/// Workflow categories are local display preferences; skill files stay untouched.
struct WorkflowLibraryView: View {
    @ObservedObject var store: SkillStore
    let onSelectSkill: (Skill) -> Void
    let onDeleteSkill: (Skill) -> Void
    @AppStorage("workflowLibrarySelection") private var selection = "all"
    @State private var categoryName = ""
    @State private var isAddingSkills = false

    private var skills: [Skill] { store.workflowSkills() }
    private var selectedCollection: SkillCollection? {
        store.collections.first { "custom:" + $0.id.uuidString == selection }
    }
    private var selectedWorkflow: WorkflowCategory? { WorkflowCategory(rawValue: selection) }
    private var filteredSkills: [Skill] {
        let query = store.searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return skills.filter { skill in
            let inCategory: Bool
            if let collection = selectedCollection {
                inCategory = isAddingSkills || store.workflowContains(collection, skill: skill)
            } else if let workflow = selectedWorkflow {
                inCategory = store.workflowCategory(for: skill) == workflow
            } else {
                inCategory = true
            }
            return inCategory && (query.isEmpty || "\(skill.displayName) \(skill.name) \(skill.description)".lowercased().contains(query))
        }
    }
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            sidebar
                .frame(width: 176)
            Divider()
            VStack(alignment: .leading, spacing: 10) {
                header
                Divider()
                if filteredSkills.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "tray").font(.system(size: 28)).foregroundStyle(.tertiary)
                        Text(store.searchText.isEmpty ? "这个分类暂时没有技能" : "没有匹配的技能")
                        if selectedCollection != nil && !isAddingSkills {
                            Button("从技能库添加") { isAddingSkills = true }
                        }
                    }
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(filteredSkills) { skill in skillCard(skill) }
                        }.padding(.trailing, 3)
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(height: 490)
        .background(Color.primary.opacity(0.035))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 12)
        .onAppear {
            if selection.hasPrefix("custom:") && selectedCollection == nil { selection = "all" }
            categoryName = selectedCollection?.name ?? ""
        }
        .onChange(of: selection) { _, _ in
            isAddingSkills = selectedCollection?.skillPaths.isEmpty ?? false
            categoryName = selectedCollection?.name ?? ""
        }
    }
    private var sidebar: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 5) {
                categoryButton("全部技能", icon: "square.grid.2x2", id: "all", count: skills.count)
                sectionLabel("按工作流自动归类")
                ForEach(WorkflowCategory.allCases) { category in
                    categoryButton(category.title, icon: category.icon, id: category.rawValue,
                                   count: skills.filter { store.workflowCategory(for: $0) == category }.count)
                }
                HStack {
                    sectionLabel("我的分类")
                    Spacer()
                    Button(action: createCategory) {
                        Image(systemName: "plus.circle.fill").foregroundStyle(Color.accentColor)
                    }.buttonStyle(.plain).help("新建自定义分类")
                }
                ForEach(store.orderedCollections) { collection in
                    categoryButton(collection.name, icon: "folder", id: "custom:" + collection.id.uuidString,
                                   count: skills.filter { store.workflowContains(collection, skill: $0) }.count)
                }
                if store.collections.isEmpty {
                    Button("＋ 新建分类", action: createCategory)
                        .font(.system(size: 12)).buttonStyle(.plain).foregroundStyle(Color.accentColor)
                        .padding(.horizontal, 8).padding(.vertical, 5)
                }
            }.padding(10)
        }
    }
    private func sectionLabel(_ title: String) -> some View {
        Text(title).font(.system(size: 10, weight: .semibold)).foregroundStyle(.secondary)
            .padding(.top, 10).padding(.bottom, 3).padding(.leading, 6)
    }
    private func categoryButton(_ title: String, icon: String, id: String, count: Int) -> some View {
        Button { selection = id } label: {
            HStack(spacing: 7) {
                Image(systemName: icon).frame(width: 15)
                Text(title).lineLimit(1)
                Spacer(minLength: 2)
                Text("\(count)").font(.system(size: 10)).foregroundStyle(.secondary)
            }
            .font(.system(size: 12, weight: selection == id ? .semibold : .regular))
            .padding(.horizontal, 8).padding(.vertical, 7)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(selection == id ? Color.accentColor.opacity(0.13) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 7))
            .contentShape(Rectangle())
        }.buttonStyle(.plain)
    }
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                if let collection = selectedCollection {
                    TextField("分类名称", text: $categoryName)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { renameCategory(collection) }
                    Button("保存") { renameCategory(collection) }.disabled(categoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    Menu {
                        Button("删除分类（保留技能）", role: .destructive) {
                            store.deleteCollection(collection); selection = "all"
                        }
                    } label: { Image(systemName: "ellipsis.circle") }
                    .menuStyle(.borderlessButton).fixedSize()
                } else {
                    Text(selectedWorkflow?.title ?? "全部技能").font(.system(size: 16, weight: .semibold))
                    Spacer()
                    Text("\(filteredSkills.count) 项").foregroundStyle(.secondary).font(.system(size: 12))
                }
            }
            Text(selectedCollection == nil ? (selectedWorkflow?.steps ?? "按用途找技能，也可以建立自己的分类") : (isAddingSkills ? "勾选要加入的 Gemini 技能" : "一个技能可以加入多个自定义分类"))
                .font(.system(size: 11)).foregroundStyle(.secondary)
            HStack {
                Label("Gemini 技能", systemImage: "sparkles").foregroundStyle(.secondary)
                Spacer()
                if selectedCollection != nil {
                    Button(isAddingSkills ? "完成添加" : "添加技能") { isAddingSkills.toggle() }
                } else {
                    Text("本地自动分类 · 可手动调整").font(.system(size: 10)).foregroundStyle(.tertiary)
                }
            }.font(.system(size: 12))
        }
    }
    private func skillCard(_ skill: Skill) -> some View {
        HStack(alignment: .top, spacing: 10) {
            if let collection = selectedCollection, isAddingSkills {
                Button { store.toggleWorkflowMembership(skill, in: collection) } label: {
                    Image(systemName: store.workflowContains(collection, skill: skill) ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(store.workflowContains(collection, skill: skill) ? Color.accentColor : Color.secondary)
                }.buttonStyle(.plain).padding(.top, 3)
            }
            Button { onSelectSkill(skill) } label: {
                VStack(alignment: .leading, spacing: 5) {
                    Text(skill.displayName).font(.system(size: 13, weight: .semibold)).lineLimit(1)
                    Text(skill.shortDescription).font(.system(size: 11)).foregroundStyle(.secondary).lineLimit(2)
                    HStack(spacing: 6) {
                        Text(skill.source.groupTitle)
                        Text("·")
                        Text(store.workflowCategory(for: skill).title)
                        if store.hasWorkflowOverride(skill) { Text("手动") }
                    }.font(.system(size: 10)).foregroundStyle(.tertiary)
                }.frame(maxWidth: .infinity, alignment: .leading).contentShape(Rectangle())
            }.buttonStyle(.plain)
            Menu {
                workflowCardMenuItems(for: skill)
            } label: { Image(systemName: "ellipsis.circle").foregroundStyle(.secondary) }
            .menuStyle(.borderlessButton).fixedSize().help("管理技能分类与删除")
        }
        .padding(12).background(Color.primary.opacity(0.055))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .contextMenu {
            Button("打开详情") { onSelectSkill(skill) }
            Divider()
            workflowCardMenuItems(for: skill)
            Divider()
            Button("在 Finder 中显示") { SkillStore.revealInFinder(skill) }
        }
    }

    @ViewBuilder
    private func workflowCardMenuItems(for skill: Skill) -> some View {
        Menu("调整工作流归类") {
            ForEach(WorkflowCategory.allCases) { category in
                Button { store.setWorkflowCategory(category, for: skill) } label: {
                    Label(category.title, systemImage: store.workflowCategory(for: skill) == category ? "checkmark" : category.icon)
                }
            }
            Divider()
            Button("恢复自动归类") { store.setWorkflowCategory(nil, for: skill) }
        }
        Menu("加入或移出我的分类") {
            ForEach(store.orderedCollections) { collection in
                Button { store.toggleWorkflowMembership(skill, in: collection) } label: {
                    Label(collection.name, systemImage: store.workflowContains(collection, skill: skill) ? "checkmark" : "folder")
                }
            }
            Divider()
            Button("新建分类并加入") { createCategory(including: skill) }
        }
        if let collection = selectedCollection {
            Button("移出当前分类") { store.toggleWorkflowMembership(skill, in: collection) }
        }
        if !skill.source.isProjectSkill {
            Divider()
            Button("删除技能", role: .destructive) {
                onDeleteSkill(skill)
            }
        }
    }
    private func createCategory() { createCategory(including: nil) }
    private func createCategory(including skill: Skill?) {
        let collection = store.createCollection(named: "新分类", including: skill)
        selection = "custom:" + collection.id.uuidString
        categoryName = collection.name
        isAddingSkills = true
    }
    private func renameCategory(_ collection: SkillCollection) {
        store.renameCollection(collection, to: categoryName)
        categoryName = store.collections.first { $0.id == collection.id }?.name ?? categoryName
    }
}
