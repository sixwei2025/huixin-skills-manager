import AppKit

if CommandLine.arguments.contains("--self-test") {
    let block = "---\nname: test-tool\ndescription: >-\n  第一行\n  第二行\nmetadata:\n  name: ignored\n---\n正文"
    let parsed = FrontmatterParser.parse(content: block)!
    precondition(parsed.name == "test-tool" && parsed.description == "第一行 第二行" && parsed.body == "正文")
    let literal = FrontmatterParser.parse(content: "---\nname: test\ndescription: |\n  第一行\n  第二行\n---\n正文")!
    precondition(literal.description == "第一行\n第二行")
    let skill = Skill(name: "workbuddy-credits-manager", description: "", source: .workbuddy, path: "/tmp/workbuddy-credits-manager/SKILL.md")
    precondition(skill.displayName == "汇芯工作搭档积分管家" && skill.triggerCommand == "workbuddy-credits-manager")
    let metadataSkillDoc = FrontmatterParser.parse(content: "---\nname: huixin-workbuddy-tutorial\nmetadata:\n  display_name: 汇芯·WorkBuddy实操教程视频\nauthor: 袁六伟 · 台州汇芯\ndescription: 教程\n---\n# 汇芯·WorkBuddy实操教程视频\n正文")!
    precondition(metadataSkillDoc.displayName == "汇芯·WorkBuddy实操教程视频")
    let longSkill = Skill(name: "huixin-workbuddy-tutorial", description: metadataSkillDoc.description, source: .workbuddy, path: "/tmp/huixin-workbuddy-tutorial/SKILL.md", customDisplayName: metadataSkillDoc.displayName, author: metadataSkillDoc.author, body: metadataSkillDoc.body)
    precondition(longSkill.displayName == "汇芯·WorkBuddy实操教程视频")
    precondition(longSkill.displayName.count > 13)
    let explicitSkillDoc = FrontmatterParser.parse(content: "---\nname: brand-new-tool\ndisplay_name: 全新效率工具\nauthor: 第三方作者\ndescription: A tool, with, commas.\n---\n# 新工具\n正文")!
    precondition(explicitSkillDoc.displayName == "全新效率工具" && explicitSkillDoc.author == "第三方作者")
    let thirdPartySkill = Skill(name: "brand-new-tool", description: explicitSkillDoc.description, source: .workbuddy, path: "/tmp/brand-new-tool/SKILL.md", customDisplayName: explicitSkillDoc.displayName, author: explicitSkillDoc.author, body: explicitSkillDoc.body)
    precondition(thirdPartySkill.originCategory == .thirdParty && thirdPartySkill.displayName == "全新效率工具")
    let commaSafeSkill = Skill(name: "unmapped-en-skill", description: "Create videos, charts, and decks. 用真实页面制作视频", source: .workbuddy, path: "/tmp/unmapped/SKILL.md")
    precondition(commaSafeSkill.displayName == "用真实页面制作视频")
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

        // Deleting from WorkflowLibraryView removes all assistant copies, symlinks, pins, and collections without touching plugins or root folders.
        let fakeHome = FileManager.default.temporaryDirectory.appendingPathComponent("huixin-delete-test-" + UUID().uuidString)
        let fakeTrash = fakeHome.appendingPathComponent(".FakeTrash")
        defer { try? FileManager.default.removeItem(at: fakeHome) }
        let fm = FileManager.default
        let agentsSkills = fakeHome.appendingPathComponent(".agents/skills")
        let geminiDir = fakeHome.appendingPathComponent(".gemini")
        let codexSkills = fakeHome.appendingPathComponent(".codex/skills")
        let grokSkills = fakeHome.appendingPathComponent(".grokbot/skills")
        let wbSkills = fakeHome.appendingPathComponent(".workbuddy/skills")
        let pluginSkillDir = fakeHome.appendingPathComponent(".codex/plugins/cache/vendor/sample-plugin/1.0/skills/shared-suite")
        for dir in [agentsSkills, geminiDir, codexSkills, grokSkills, wbSkills, pluginSkillDir, fakeTrash] {
            try! fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        try! fm.createSymbolicLink(at: geminiDir.appendingPathComponent("skills"), withDestinationURL: agentsSkills)

        let agentsShared = agentsSkills.appendingPathComponent("shared-suite")
        let subSkillDir = agentsShared.appendingPathComponent("subskills/sub-a")
        try! fm.createDirectory(at: subSkillDir, withIntermediateDirectories: true)
        try! "---\nname: shared-suite\ndescription: synced\n---\nbody".write(to: agentsShared.appendingPathComponent("SKILL.md"), atomically: true, encoding: .utf8)
        try! "---\nname: sub-a\ndescription: sub\n---\nbody".write(to: subSkillDir.appendingPathComponent("SKILL.md"), atomically: true, encoding: .utf8)
        try! fm.createSymbolicLink(at: codexSkills.appendingPathComponent("shared-suite"), withDestinationURL: agentsShared)
        try! fm.createSymbolicLink(at: grokSkills.appendingPathComponent("shared-suite"), withDestinationURL: agentsShared)
        let wbShared = wbSkills.appendingPathComponent("shared-suite")
        try! fm.createDirectory(at: wbShared, withIntermediateDirectories: true)
        try! "---\nname: shared-suite\ndescription: wb copy\n---\nbody".write(to: wbShared.appendingPathComponent("SKILL.md"), atomically: true, encoding: .utf8)
        try! fm.createSymbolicLink(at: wbSkills.appendingPathComponent("sub-a"), withDestinationURL: subSkillDir)
        try! "---\nname: shared-suite\ndescription: plugin\n---\nbody".write(to: pluginSkillDir.appendingPathComponent("SKILL.md"), atomically: true, encoding: .utf8)

        let codexReverse = codexSkills.appendingPathComponent("reverse-tool")
        try! fm.createDirectory(at: codexReverse.appendingPathComponent("agents"), withIntermediateDirectories: true)
        try! "---\nname: reverse-tool\ndescription: reverse\n---\nbody".write(to: codexReverse.appendingPathComponent("SKILL.md"), atomically: true, encoding: .utf8)
        try! "interface:\n  display_name: 中文覆盖名\n".write(to: codexReverse.appendingPathComponent("agents/openai.yaml"), atomically: true, encoding: .utf8)
        let agentsReverse = agentsSkills.appendingPathComponent("reverse-tool")
        try! fm.createSymbolicLink(at: agentsReverse, withDestinationURL: codexReverse)
        try! fm.createSymbolicLink(at: grokSkills.appendingPathComponent("reverse-tool"), withDestinationURL: agentsReverse)
        try! fm.createSymbolicLink(at: wbSkills.appendingPathComponent("reverse-tool"), withDestinationURL: agentsReverse)
        try! "---\nname: standalone-note\ndescription: single file\n---\nbody".write(to: grokSkills.appendingPathComponent("standalone-note.md"), atomically: true, encoding: .utf8)

        let deleteSuite = "cn.huixin.skillsmanager.tests." + UUID().uuidString
        let deleteDefaults = UserDefaults(suiteName: deleteSuite)!
        defer { deleteDefaults.removePersistentDomain(forName: deleteSuite) }
        let deleteStore = SkillStore(
            workflowDefaults: deleteDefaults,
            homeDirectory: fakeHome.path,
            trashItemHandler: { url in
                let dest = fakeTrash.appendingPathComponent(UUID().uuidString + "-" + url.lastPathComponent)
                try fm.moveItem(at: url, to: dest)
            }
        )
        deleteStore.reloadScannedSkillsForTesting()
        let geminiSharedSkill = deleteStore.workflowSkills().first { $0.name == "shared-suite" }!
        let wbSharedSkill = deleteStore.allSkills.first { $0.path == wbShared.appendingPathComponent("SKILL.md").path }!
        let codexSharedSkill = deleteStore.allSkills.first { $0.path == codexSkills.appendingPathComponent("shared-suite/SKILL.md").path }!
        let deleteCollection = deleteStore.createCollection(named: "待删", including: wbSharedSkill)
        deleteStore.togglePin(codexSharedSkill)
        precondition(deleteStore.deletionTargetSources(for: geminiSharedSkill, syncAcrossAssistants: true) == ["Gemini", "Codex", "Grok Bot", "WorkBuddy"])
        precondition(deleteStore.deleteSkill(geminiSharedSkill, syncAcrossAssistants: true))
        precondition(!fm.fileExists(atPath: agentsShared.path))
        precondition(!fm.fileExists(atPath: wbShared.path))
        precondition((try? fm.attributesOfItem(atPath: codexSkills.appendingPathComponent("shared-suite").path)) == nil)
        precondition((try? fm.attributesOfItem(atPath: grokSkills.appendingPathComponent("shared-suite").path)) == nil)
        precondition((try? fm.attributesOfItem(atPath: wbSkills.appendingPathComponent("sub-a").path)) == nil)
        precondition(fm.fileExists(atPath: pluginSkillDir.appendingPathComponent("SKILL.md").path))
        precondition(deleteStore.collections.first { $0.id == deleteCollection.id }?.skillPaths.isEmpty == true)
        precondition(!deleteStore.pinnedPaths.contains(codexSharedSkill.path))
        precondition(!deleteStore.workflowSkills().contains { $0.name == "shared-suite" })
        precondition(!deleteStore.groupsForTab(.workbuddy).flatMap(\.sections).flatMap(\.skills).contains { $0.name == "shared-suite" })

        let geminiReverseSkill = deleteStore.workflowSkills().first { $0.name == "reverse-tool" }!
        precondition(deleteStore.deleteSkill(geminiReverseSkill, syncAcrossAssistants: true))
        precondition(!fm.fileExists(atPath: codexReverse.path))
        precondition((try? fm.attributesOfItem(atPath: agentsReverse.path)) == nil)
        precondition((try? fm.attributesOfItem(atPath: grokSkills.appendingPathComponent("reverse-tool").path)) == nil)
        precondition((try? fm.attributesOfItem(atPath: wbSkills.appendingPathComponent("reverse-tool").path)) == nil)

        let standaloneSkill = deleteStore.allSkills.first { $0.name == "standalone-note" }!
        precondition(deleteStore.deleteSkill(standaloneSkill, syncAcrossAssistants: false))
        precondition(!fm.fileExists(atPath: grokSkills.appendingPathComponent("standalone-note.md").path))
        precondition(fm.fileExists(atPath: grokSkills.path))
    }
    print("通过：多行说明、元数据隔离、中文显示、原始调用名、来源分组、加宽面板、自动分类、手动纠正、自定义分类、重启恢复、跨来源链接、四平台副本合并、来源筛选、插件隔离、旧分类兼容、工作流同步删除")
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
