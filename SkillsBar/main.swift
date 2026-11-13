import AppKit

if CommandLine.arguments.contains("--self-test") {
    let block = "---\nname: test-tool\ndescription: >-\n  第一行\n  第二行\nmetadata:\n  name: ignored\n---\n正文"
    let parsed = FrontmatterParser.parse(content: block)!
    precondition(parsed.name == "test-tool" && parsed.description == "第一行 第二行" && parsed.body == "正文")
    let literal = FrontmatterParser.parse(content: "---\nname: test\ndescription: |\n  第一行\n  第二行\n---\n正文")!
    precondition(literal.description == "第一行\n第二行")
    let skill = Skill(name: "workbuddy-credits-manager", description: "", source: .workbuddy, path: "/tmp/workbuddy-credits-manager/SKILL.md")
    precondition(skill.displayName == "工作搭档积分管家" && skill.triggerCommand == "workbuddy-credits-manager")
    precondition(SkillStore.SkillTab.workbuddy.groupID == "workbuddy")
    precondition(SkillsBarLayout.windowWidth == 760)
    // Isolate persistence tests from the real user's categories.
    MainActor.assumeIsolated {
        let suite = "cn.huixin.skillsmanager.tests." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = SkillStore(workflowDefaults: defaults)
        let sample = Skill(name: "remotion-render", description: "导出成片", source: .codexCLI(.user), path: "/tmp/huixin-fixture/remotion/SKILL.md")
        precondition(store.workflowCategory(for: sample) == .video)
        let office = Skill(name: "spreadsheets", description: "", source: .codexCLI(.user), path: "/tmp/huixin-fixture/spreadsheets/SKILL.md")
        precondition(store.workflowCategory(for: office) == .office)
        let unknown = Skill(name: "xyz-123", description: "", source: .workbuddy, path: "/tmp/huixin-fixture/xyz-123/SKILL.md")
        precondition(store.workflowCategory(for: unknown) == .other)
        store.setWorkflowCategory(.business, for: sample)
        let collection = store.createCollection(named: "产品发布")
        store.toggleWorkflowMembership(sample, in: collection)
        let reopened = SkillStore(workflowDefaults: defaults)
        precondition(reopened.workflowCategory(for: sample) == .business)
        precondition(reopened.collections.count == 1 && reopened.workflowContains(reopened.collections[0], skill: sample))
        reopened.renameCollection(reopened.collections[0], to: "客户项目")
        let renamed = SkillStore(workflowDefaults: defaults)
        precondition(renamed.collections[0].name == "客户项目")
        renamed.toggleWorkflowMembership(sample, in: renamed.collections[0])
        precondition(renamed.collections[0].skillPaths.isEmpty)
        renamed.setWorkflowCategory(nil, for: sample)
        precondition(SkillStore(workflowDefaults: defaults).workflowCategory(for: sample) == .video)
        renamed.deleteCollection(renamed.collections[0])
        precondition(SkillStore(workflowDefaults: defaults).collections.isEmpty)
        // Physical copies installed in four assistants form one overview entry.
        let copiesRoot = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: copiesRoot) }
        let sources: [SkillSource] = [.claudeCode(.user), .codexCLI(.user), .pi(.user), .workbuddy]
        let copies = sources.enumerated().map { index, source -> Skill in
            let folder = copiesRoot.appendingPathComponent("assistant-\(index)/synced-tool")
            try! FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let file = folder.appendingPathComponent("SKILL.md")
            try! "---\nname: synced-tool\ndescription: real copy\n---\nbody".write(to: file, atomically: true, encoding: .utf8)
            return Skill(name: "synced-tool", description: "real copy", source: source, path: file.path)
        }
        precondition(SkillStore.uniqueWorkflowSkills(copies).count == 1)
        for copy in copies {
            let filtered = SkillStore.uniqueWorkflowSkills(copies, sourceGroup: copy.source.groupTitle)
            precondition(filtered.count == 1 && filtered[0].path == copy.path)
        }
        let different = Skill(name: "another-tool", description: "real copy", source: .workbuddy, path: "/tmp/another/SKILL.md")
        precondition(SkillStore.uniqueWorkflowSkills(copies + [different]).count == 2)
        let pluginA = Skill(name: "synced-tool", description: "", source: .codexCLI(.plugin), path: "/tmp/plugins/cache/vendor/plugin-a/1/skills/synced-tool/SKILL.md")
        let pluginB = Skill(name: "synced-tool", description: "", source: .codexCLI(.plugin), path: "/tmp/plugins/cache/vendor/plugin-b/1/skills/synced-tool/SKILL.md")
        precondition(SkillStore.uniqueWorkflowSkills(copies + [pluginA, pluginB]).count == 3)
        // Old path-based preferences survive, including resetting through another copy.
        defaults.set([SkillStore.workflowIdentity(copies[0].path): WorkflowCategory.business.rawValue], forKey: "workflowCategoryOverrides")
        let migrated = SkillStore(workflowDefaults: defaults)
        precondition(migrated.workflowCategory(for: copies[3]) == .business)
        migrated.setWorkflowCategory(.knowledge, for: copies[1])
        precondition(copies.allSatisfy { migrated.workflowCategory(for: $0) == .knowledge })
        let syncedCollection = migrated.createCollection(named: "同步技能")
        migrated.toggleWorkflowMembership(copies[0], in: syncedCollection)
        let restored = SkillStore(workflowDefaults: defaults)
        precondition(restored.workflowContains(restored.collections[0], skill: copies[3]))
        restored.toggleWorkflowMembership(copies[3], in: restored.collections[0])
        precondition(restored.collections[0].skillPaths.isEmpty)
        restored.setWorkflowCategory(nil, for: copies[2])
        precondition(copies.allSatisfy { !restored.hasWorkflowOverride($0) })
        // Linked installations refer to one skill for overrides and membership.
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try! FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let file = folder.appendingPathComponent("SKILL.md")
        try! "fixture".write(to: file, atomically: true, encoding: .utf8)
        let alias = folder.appendingPathComponent("alias.md")
        try! FileManager.default.createSymbolicLink(at: alias, withDestinationURL: file)
        let real = Skill(name: "sample", description: "", source: .workbuddy, path: file.path)
        let linked = Skill(name: "sample", description: "", source: .pi(.shared), path: alias.path)
        renamed.setWorkflowCategory(.knowledge, for: real)
        precondition(renamed.workflowCategory(for: linked) == .knowledge)
        let sharedCollection = renamed.createCollection(named: "跨来源")
        renamed.toggleWorkflowMembership(real, in: sharedCollection)
        precondition(renamed.workflowContains(renamed.collections[0], skill: linked))
        renamed.toggleWorkflowMembership(linked, in: renamed.collections[0])
        precondition(renamed.collections[0].skillPaths.isEmpty)
    }
    print("通过：多行说明、元数据隔离、中文显示、原始调用名、来源分组、加宽面板、自动分类、手动纠正、自定义分类、重启恢复、跨来源链接、四平台副本合并、来源筛选、插件隔离、旧分类兼容")
    exit(0)
}
if CommandLine.arguments.contains("--plugin-catalog-json") {
    let rows = PluginScanner().scanInstalledPlugins().map { ["name": $0.name, "displayName": $0.displayName] }
    FileHandle.standardOutput.write(try! JSONSerialization.data(withJSONObject: rows, options: [.prettyPrinted]))
    exit(0)
}
if CommandLine.arguments.contains("--workflow-catalog-json") {
    MainActor.assumeIsolated {
    let skills = SkillScanner().scanAll()
    let rows = SkillStore.uniqueWorkflowSkills(skills).map { skill in
        ["name": skill.name, "identity": SkillStore.workflowLogicalIdentity(skill),
         "sources": Array(Set(skills.filter { SkillStore.workflowLogicalIdentity($0) == SkillStore.workflowLogicalIdentity(skill) }.map { $0.source.groupTitle })).sorted().joined(separator: " / ")]
    }
    FileHandle.standardOutput.write(try! JSONSerialization.data(withJSONObject: rows, options: [.prettyPrinted, .sortedKeys]))
    }
    exit(0)
}
if CommandLine.arguments.contains("--catalog-json") {
    let skills = SkillScanner().scanAll()
    let rows = skills.map { ["name": $0.name, "displayName": $0.displayName, "description": $0.description, "path": $0.path, "source": $0.source.groupTitle, "trigger": $0.triggerCommand] }
    let data = try! JSONSerialization.data(withJSONObject: rows, options: [.prettyPrinted, .sortedKeys])
    FileHandle.standardOutput.write(data)
    exit(0)
}
let app = NSApplication.shared
let delegate = MainActor.assumeIsolated { AppDelegate() }
app.delegate = delegate
app.run()
