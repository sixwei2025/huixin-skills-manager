import Foundation
import SwiftUI

enum SkillCollectionAccent: String, CaseIterable, Codable, Identifiable, Hashable {
    case blue
    case purple
    case teal
    case green
    case orange
    case pink
    case gray

    var id: String { rawValue }

    var title: String {
        switch self {
        case .blue: return "Blue"
        case .purple: return "Purple"
        case .teal: return "Teal"
        case .green: return "Green"
        case .orange: return "Orange"
        case .pink: return "Pink"
        case .gray: return "Gray"
        }
    }

    var swiftUIColor: Color {
        switch self {
        case .blue: return .blue
        case .purple: return .purple
        case .teal: return .teal
        case .green: return .green
        case .orange: return .orange
        case .pink: return .pink
        case .gray: return .gray
        }
    }
}

enum SkillCollectionIcon: String, CaseIterable, Identifiable, Hashable {
    case stack = "square.stack.3d.up"
    case folder = "folder"
    case bookmark = "bookmark"
    case document = "doc.text"
    case terminal = "terminal"
    case tools = "hammer"
    case package = "shippingbox"
    case sparkles = "sparkles"
    case magic = "wand.and.stars"
    case settings = "gearshape"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .stack: return "Stack"
        case .folder: return "Folder"
        case .bookmark: return "Bookmark"
        case .document: return "Document"
        case .terminal: return "Terminal"
        case .tools: return "工具"
        case .package: return "Package"
        case .sparkles: return "Sparkles"
        case .magic: return "Magic"
        case .settings: return "设置"
        }
    }
}

struct SkillCollection: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var skillPaths: [String]
    var iconName: String
    var accent: SkillCollectionAccent
    var isPinned: Bool
    let createdAt: Date
    var updatedAt: Date

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case skillPaths
        case iconName
        case accent
        case isPinned
        case createdAt
        case updatedAt
    }

    init(
        id: UUID = UUID(),
        name: String,
        skillPaths: [String] = [],
        iconName: String = SkillCollectionIcon.stack.rawValue,
        accent: SkillCollectionAccent = .blue,
        isPinned: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.skillPaths = skillPaths
        self.iconName = iconName
        self.accent = accent
        self.isPinned = isPinned
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decode(String.self, forKey: .name)
        skillPaths = try container.decodeIfPresent([String].self, forKey: .skillPaths) ?? []
        iconName = try container.decodeIfPresent(String.self, forKey: .iconName) ?? SkillCollectionIcon.stack.rawValue
        accent = try container.decodeIfPresent(SkillCollectionAccent.self, forKey: .accent) ?? .blue
        isPinned = try container.decodeIfPresent(Bool.self, forKey: .isPinned) ?? false
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? createdAt
    }
}

struct ResolvedSkillCollection: Identifiable {
    let collection: SkillCollection
    let skills: [Skill]
    let missingCount: Int
    let missingSkillPaths: [String]

    var id: UUID { collection.id }
}

// Categories describe a skill's purpose; source tabs continue to describe its host.
enum WorkflowCategory: String, CaseIterable, Identifiable, Codable {
    case publishing, video, business, knowledge, research, design, office, development, other
    var id: String { rawValue }
    var title: String {
        switch self {
        case .publishing: return "公众号与内容"
        case .video: return "视频制作"
        case .business: return "企业与交付"
        case .knowledge: return "知识管理"
        case .research: return "选题与调研"
        case .design: return "设计与配图"
        case .office: return "办公与协作"
        case .development: return "开发与工具"
        case .other: return "其他技能"
        }
    }
    var icon: String {
        switch self {
        case .publishing: return "text.bubble"
        case .video: return "film"
        case .business: return "briefcase"
        case .knowledge: return "books.vertical"
        case .research: return "magnifyingglass"
        case .design: return "paintpalette"
        case .office: return "doc.on.doc"
        case .development: return "wrench.and.screwdriver"
        case .other: return "square.grid.2x2"
        }
    }
    var steps: String {
        switch self {
        case .publishing: return "策划 → 写作 → 排版 → 发布"
        case .video: return "脚本 → 素材 → 动效 → 成片"
        case .business: return "需求 → 制作 → 交付 → 跟进"
        case .knowledge: return "收集 → 搜索 → 整理 → 复用"
        case .research: return "发现 → 查证 → 分析 → 决策"
        case .design: return "构思 → 设计 → 配图 → 导出"
        case .office: return "文档 → 表格 → 演示 → 协作"
        case .development: return "搭建 → 开发 → 操作 → 维护"
        case .other: return "暂未匹配用途，可手动调整归类"
        }
    }
    private var keywords: [String] {
        switch self {
        case .publishing: return ["wechat", "公众号", "朋友圈", "小红书", "小绿书", "copywriter", "writing", "writer", "标题", "文风", "content-planner", "social-matrix"]
        case .video: return ["video", "视频", "motion", "remotion", "hyperframes", "hyperframe", "hypit", "字幕", "配音", "gsap", "动画", "成片", "口播", "vibe", "知识大赏", "obsidian-gold", "neon-matrix", "blueprint-lab", "paper-ink", "flat-card", "cosmos-hud", "video-cover"]
        case .business: return ["company-delivery", "企业交付", "商单", "作战中枢", "课程交付", "project-manager", "项目管理", "商业", "customer", "sales", "crm", "proposal"]
        case .knowledge: return ["getnote", "得到", "obsidian", "知识库", "知识管理", "weread", "微信读书", "book-to-skill", "笔记", "知识星球", "zsxq"]
        case .research: return ["research", "调研", "aihot", "trending", "radar", "雷达", "选题", "monitor", "舆情", "评测", "review", "validate-with-ai", "搜索", "search"]
        case .design: return ["design", "image", "illustrat", "图片", "配图", "封面", "cover", "canva", "adobe", "photoshop", "figma", "mockup", "设计"]
        case .office: return ["lark", "飞书", "document", "文档", "spreadsheet", "表格", "presentation", "幻灯片", "slides", "pdf", "gmail", "calendar", "日历", "contacts", "联系人", "google-drive", "办公", "sheet"]
        case .development: return ["browser", "浏览器", "computer", "电脑操作", "skill-", "plugin", "插件", "cli", "codex", "github", "开发", "build", "程序", "runtime", "环境", "auth", "登录", "额度", "credits", "manager", "agent"]
        case .other: return []
        }
    }
    static func suggest(for skill: Skill) -> WorkflowCategory {
        let name = skill.name.lowercased()
        let folder = URL(fileURLWithPath: skill.path).deletingLastPathComponent().lastPathComponent.lowercased()
        let description = skill.description.lowercased()
        // Name/folder matches take priority over descriptions that mention other steps.
        var winner: WorkflowCategory = .other
        var best = 0
        for category in allCases where category != .other {
            let identityMatch = category.keywords.contains { name.contains($0) || folder.contains($0) }
            let descriptionMatches = min(3, category.keywords.filter { description.contains($0) }.count)
            let score = (identityMatch ? 10 : 0) + descriptionMatches
            if score > best { winner = category; best = score }
        }
        return winner
    }
}
