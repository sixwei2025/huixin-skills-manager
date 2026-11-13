import Foundation

struct Skill: Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
    let source: SkillSource
    let path: String
    var version: String?
    var body: String = ""
    var lastModified: Date?
    var folderContents: [String] = []
    var folderDirectories: Set<String> = []
    var directoryContents: [String: [String]] = [:]

    init(name: String, description: String, source: SkillSource, path: String, version: String? = nil, body: String = "", lastModified: Date? = nil, folderContents: [String] = [], folderDirectories: Set<String> = [], directoryContents: [String: [String]] = [:]) {
        self.id = path
        self.name = name
        self.description = description
        self.source = source
        self.path = path
        self.version = version
        self.body = body
        self.lastModified = lastModified
        self.folderContents = folderContents
        self.folderDirectories = folderDirectories
        self.directoryContents = directoryContents
    }

    var displayName: String {
        ChineseSkillNames.name(name.isEmpty ? URL(fileURLWithPath: path).deletingLastPathComponent().lastPathComponent : name, description: description, path: path)
    }

    var shortDescription: String {
        let firstLine = description.components(separatedBy: .newlines).first ?? description
        if firstLine.count > 120 {
            return String(firstLine.prefix(117)) + "..."
        }
        return firstLine
    }

    var isNew: Bool {
        guard let date = lastModified else { return false }
        return Date().timeIntervalSince(date) < 86400
    }

    var formattedLastModified: String? {
        guard let date = lastModified else { return nil }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    var triggerCommand: String {
        switch source {
        case .claudeCode(.user), .claudeCode(.project(_)):
            // <skills-root>/<folder-name>/SKILL.md -> /folder-name
            let folderName = URL(fileURLWithPath: path).deletingLastPathComponent().lastPathComponent
            return "/\(folderName)"

        case .claudeCode(.plugin):
            // ~/.claude/plugins/cache/<repo>/<plugin>/<ver>/skills/<skill>/SKILL.md
            // trigger: plugin-name:skill-name
            let components = path.components(separatedBy: "/")
            if let skillsIdx = components.lastIndex(of: "skills"),
               skillsIdx > 1,
               skillsIdx + 1 < components.count {
                let pluginName = components[skillsIdx - 2]
                let skillName = components[skillsIdx + 1]
                return "\(pluginName):\(skillName)"
            }
            let folderName = URL(fileURLWithPath: path).deletingLastPathComponent().lastPathComponent
            return folderName

        case .codexCLI(.builtin):
            let folderName = URL(fileURLWithPath: path).deletingLastPathComponent().lastPathComponent
            return folderName

        case .codexCLI(.plugin):
            let components = path.components(separatedBy: "/")
            if let skillsIdx = components.lastIndex(of: "skills"),
               skillsIdx > 1,
               skillsIdx + 1 < components.count {
                let pluginName = components[skillsIdx - 2]
                let skillName = components[skillsIdx + 1]
                return "\(pluginName):\(skillName)"
            }
            let folderName = URL(fileURLWithPath: path).deletingLastPathComponent().lastPathComponent
            return folderName

        case .codexCLI(.user):
            let folderName = URL(fileURLWithPath: path).deletingLastPathComponent().lastPathComponent
            return folderName

        case .pi, .workbuddy:
            // Pi registers /skill:<frontmatter name> and deliberately allows that name to
            // differ from the folder, so the folder name is not a safe substitute here.
            return name.isEmpty ? URL(fileURLWithPath: path).deletingLastPathComponent().lastPathComponent : name
        }
    }

    var triggerHint: String {
        switch source {
        case .claudeCode(.user):
            return "在 Gemini 中按原始名称调用"
        case .claudeCode(.project(let root)):
            return "Available in Claude Code when working in \(root.name)."
        case .claudeCode(.plugin):
            return "由 Gemini 自动发现的内置或插件技能"
        case .codexCLI(.builtin):
            return "Codex 内置技能"
        case .codexCLI(.plugin):
            return "通过 Codex 插件提供"
        case .codexCLI(.user):
            return "已安装的 Codex 技能"
        case .workbuddy:
            return "在 WorkBuddy 中按原始名称调用此技能"
        case .pi(.user):
            return "在 Grok Bot 中按原始名称调用此技能"
        case .pi(.shared):
            return "来自共享目录的 Grok Bot 技能"
        case .pi(.project(let root)):
            return "Available in Pi when working in \(root.name), once the project is trusted."
        }
    }
}


enum ChineseSkillNames {
    static let names: [String: String] = [
        "hyperframes by heygen": "网页视频制作套件",
        "default templates": "默认文档模板",
        "canva": "可画设计",
        "cloud environment": "云端环境",
        "google calendar": "谷歌日历",
        "adobe": "创意设计工具",
        "writing style": "个人文风",
        "remote desktop commander": "远程桌面操作",
        "remotion": "动画视频制作",
        "google contacts": "谷歌联系人",
        "build ios apps": "苹果手机应用开发",
        "figma": "界面设计工具",
        "superpowers": "开发协作增强套件",
        "unified-computer-use": "浏览器自动操作运行环境",
        "browser": "浏览器操作",
        "codex-app-tools": "桌面应用工具",
        "chrome": "谷歌浏览器操作",
        "computer use": "电脑操作",
        "plugin management": "插件管理",

        "/remotion-best-practices": "视频制作最佳实践",
        "/remotion-captions": "视频字幕制作",
        "/remotion-create": "创建动画视频",
        "/remotion-docs": "视频引擎文档",
        "/remotion-interactivity": "交互视频制作",
        "/remotion-maps": "地图视频动画",
        "/remotion-markup": "视频画面与动效",
        "/remotion-multimedia": "多媒体处理",
        "/remotion-render": "视频导出",
        "/remotion-saas": "视频应用开发",
        "/remotion-studio": "视频预览",
        "/remotion-upgrade": "视频引擎升级",
        "1688-product-research": "阿里批发选品调研",
        "1688-sourcing": "阿里批发货源采购",
        "3d-map-video": "三维地图视频",
        "ab-test-setup": "对照实验设计",
        "agent browser": "智能浏览器操作",
        "agent-proposal-architect": "智能助手方案策划",
        "agy-customizations": "谷歌命令行自定义",
        "ai-trending-topics": "人工智能热点选题",
        "aihot行业站改造": "人工智能行业资讯站改造",
        "ai内容质检闸门": "智能内容质量检查",
        "ai团队组建": "智能团队组建",
        "ai大模型测评": "人工智能大模型测评",
        "ai-tool-review-wechat": "AI 评测公众号",
        "ai评测公众号": "AI 评测公众号",
        "ai工具评测公众号": "AI 评测公众号",
        "ai热点资讯站": "人工智能热点资讯站",
        "ai热点选题挖掘": "人工智能热点选题挖掘",
        "ai编程助手鉴权修复": "智能编程助手登录修复",
        "alibaba-publish-skill": "阿里国际站商品发布",
        "alibaba-store-analysis": "阿里国际站店铺分析",
        "amz-hot-keywords": "亚马逊热门关键词",
        "amz-product-optimizer": "亚马逊商品优化",
        "analytics dashboard": "数据分析看板",
        "antigravity-guide": "谷歌编程助手指南",
        "article-image-generator": "文章配图制作",
        "authoring-skills": "技能编写指南",
        "automation": "定时自动化任务",
        "batch edit photos": "照片批量调色",
        "bibi": "哔哩哔哩内容助手",
        "book-to-skill": "书籍提炼成技能",
        "brainstorming": "创意构思",
        "branded presentation": "品牌演示文稿",
        "browseract": "浏览器自动操作",
        "browseract skill forge": "网页操作技能制作",
        "business review": "业务复盘演示",
        "b端商单交付系统": "企业商单交付系统",
        "capability-evolver": "能力持续改进",
        "ci debug": "持续集成故障排查",
        "cj-dropshipping-api": "跨境代发货管理",
        "claude-mem-huixin": "汇芯长期记忆",
        "clawhub": "开源技能市场",
        "cloud-desktop": "云端桌面操作",
        "cloud-environment-runtime": "云端运行环境",
        "commission-reconciler": "佣金账单核对",
        "company-delivery-hub": "企业项目交付中心",
        "company-research": "公司调研",
        "competitive-landscape": "竞争格局分析",
        "content-breakdown": "内容拆解",
        "content-planner": "内容选题与排期",
        "content-strategy": "内容策略",
        "copywriting": "商业文案写作",
        "create mockups": "产品样机展示",
        "create pet": "创建桌面萌宠",
        "create social variations": "社交平台尺寸适配",
        "create-website": "网站创建",
        "creating-financial-models": "财务模型制作",
        "dark-infographic-video": "暗色动态图解视频",
        "design from template": "模板视觉设计",
        "design report": "设计报告",
        "dispatching parallel agents": "并行任务分配",
        "documents": "文档制作与编辑",
        "docx": "文字文档制作",
        "ecom-agent-proposal": "电商智能助手方案",
        "ecom-content-authority": "电商内容专业度建设",
        "ecom-ops-booster": "电商运营提效",
        "ecom-skill-asset-vault": "电商技能资产库",
        "edit quick cut": "视频快速剪辑",
        "excel live control": "电子表格实时操作",
        "executing plans": "执行实施计划",
        "experiment analysis": "实验分析文档",
        "feishu-assistant": "飞书办公助手",
        "figma-code-connect": "设计稿代码关联",
        "figma-create-new-file": "创建设计文件",
        "figma-generate-design": "生成界面设计",
        "figma-generate-diagram": "生成设计图解",
        "figma-generate-library": "生成设计组件库",
        "figma-implement-motion": "实现设计动效",
        "figma-swiftui": "设计稿转苹果界面",
        "figma-use": "设计工具操作",
        "figma-use-figjam": "协作白板操作",
        "figma-use-motion": "设计动效操作",
        "figma-use-slides": "设计幻灯片操作",
        "financial budget": "财务预算表",
        "find-skills": "查找技能",
        "finishing a development branch": "完成开发分支",
        "fonts": "字体查找与预览",
        "frontend-design": "前端界面设计",
        "generative_ui": "生成交互界面",
        "geo-content-optimizer": "智能搜索内容优化",
        "geo-diagnostic": "智能搜索可见度诊断",
        "geo-optimizer": "智能搜索引用优化",
        "getnote-auth": "得到大脑连接与登录",
        "getnote-kb": "得到大脑知识库",
        "getnote-note": "得到大脑笔记管理",
        "getnote-search": "得到大脑笔记搜索",
        "getnote-suite": "得到大脑全能助手",
        "getnote-tag": "得到大脑标签管理",
        "get笔记": "得到笔记管理",
        "github": "代码仓库管理",
        "github技能本地化": "开源技能本地安装",
        "gmail": "谷歌邮箱管理",
        "gmail-assistant": "谷歌邮箱助手",
        "google docs": "谷歌文档",
        "google drive": "谷歌云盘",
        "google drive comments": "谷歌云盘评论",
        "google sheets": "谷歌电子表格",
        "google slides": "谷歌幻灯片",
        "gpt-image": "智能图像创作",
        "gsap": "网页动画制作",
        "high-quality-book-summary": "优质书籍深度解读",
        "hit-title-expert": "高吸引力标题策划",
        "huangdi-skill": "历史人物决策方法",
        "huashu-creative-suite": "花叔创意制作套件",
        "huashu-mac-use": "Mac桌面操控与实拍取证",
        "video-clipper-suite": "短视频智能剪辑与切片总控",
        "auto-tutorial": "可视化教程视频",
        "huixin-product-expert": "汇芯产品顾问",
        "humanize-ai-text": "自然文风改写",
        "hyperframes": "网页视频制作",
        "hyperframes cli": "网页视频制作命令行",
        "hyperframes registry": "网页视频组件库",
        "hypit": "多媒体视频导演",
        "hypit视频制作": "多媒体视频导演",
        "image gen": "图像生成与编辑",
        "inbox triage": "邮件收件箱整理",
        "investment committee memo": "投资委员会备忘录",
        "ios app intents": "苹果手机快捷操作",
        "ios debugger agent": "苹果手机应用调试",
        "ios ettrace performance": "苹果手机性能跟踪",
        "ios memgraph leaks": "苹果手机内存泄漏排查",
        "ios simulator browser": "苹果手机模拟器预览",
        "iphone镜像操控": "苹果手机镜像操控",
        "kazik-style-expert": "卡兹克文风顾问",
        "kazik-style-writing": "卡兹克风格写作",
        "lark-suite": "飞书全能办公助手",
        "legal memorandum": "法律备忘录",
        "local-video-hub": "本地视频中心",
        "mac应用截图操控": "苹果电脑应用截图操控",
        "mac抠图与截图": "苹果电脑抠图与截图",
        "market trends report": "市场趋势报告",
        "mcp-tools": "外部工具发现与调用",
        "migrate-agent-settings": "迁移智能助手配置",
        "migrate-workflows": "迁移自动化流程",
        "mimeng-title-factory": "咪蒙方法标题工厂",
        "minimal letterhead": "简约信头文档",
        "moments-copywriter": "朋友圈文案",
        "openai docs": "开放人工智能产品文档",
        "openmontage视频制作": "代码视频制作",
        "operating calendar": "运营日历",
        "operating review": "运营复盘演示",
        "org-structure-research": "组织结构调研",
        "outlier-trend-analyzer": "异常热点趋势分析",
        "pdf": "便携文档处理",
        "pdf设计复刻": "便携文档设计复刻",
        "people-research": "人物背景调研",
        "permissioned-github": "代码仓库授权操作",
        "pets": "桌面萌宠管理",
        "plugin": "插件管理与创建",
        "plugin creator": "插件创建",
        "plugin-management": "插件与连接管理",
        "pptx": "演示文稿编辑",
        "ppt渲染校验": "演示文稿渲染检查",
        "presentations": "演示文稿制作",
        "product-description-generator": "商品详情文案",
        "product-selection": "商品选品",
        "project kickoff": "项目启动演示",
        "project tracker": "项目进度表",
        "psych-kepu-video": "心理科普动画视频",
        "pua-anti-slacking": "复杂任务执行督促",
        "public-opinion-monitor": "舆情监测分析",
        "publish changes": "发布代码变更",
        "rapid-demo-generator": "快速样品制作",
        "receiving code review": "处理代码评审意见",
        "remotion best practices": "视频制作最佳实践",
        "remotion-best-practices": "视频制作最佳实践",
        "requesting code review": "发起代码评审",
        "retouch portraits": "人像批量精修",
        "reverse-engineer-anything": "软件原理与结构分析",
        "review agent": "代码审查助手",
        "review follow-up": "跟进评审意见",
        "run-workflow": "执行自动化流程",
        "sales pipeline": "销售进度表",
        "sales-negotiator": "销售谈判顾问",
        "sec-skill-evaluator": "企业技能价值评估",
        "self-improvement": "学习记录与持续改进",
        "simple dark mode": "简约深色演示",
        "simple light mode": "简约浅色演示",
        "sites": "网站搭建",
        "sites-remix": "网站二次创作",
        "skill creator": "技能创建与优化",
        "skill installer": "技能安装",
        "skill-creator": "技能创建与优化",
        "skill-finder": "技能查找与推荐",
        "skill-vetter": "技能安全审核",
        "social resize": "社交设计尺寸适配",
        "social-matrix-suite": "社交内容矩阵制作",
        "social-media-publisher": "社交平台发布",
        "social-network-mapper": "社交关系图谱",
        "spark-video-cast": "视频人物与场景资产",
        "spark-video-clip-review": "视频逐镜质量检查",
        "spark-video-director": "视频分镜导演",
        "spark-video-screenwriter": "视频剧本编写",
        "spark-video-vfx-review": "视频特效预检",
        "spreadsheets": "电子表格分析与制作",
        "strategy memorandum": "战略备忘录",
        "subagent-driven development": "分工协作开发",
        "summarize": "网页与文件摘要",
        "swarm": "协作任务编排",
        "swarm_monitor": "协作任务进度监控",
        "swarm_narrator": "协作任务讲解",
        "swiftui liquid glass": "苹果液态玻璃界面",
        "swiftui performance audit": "苹果界面性能诊断",
        "swiftui ui patterns": "苹果界面设计模式",
        "swiftui view refactor": "苹果界面结构优化",
        "system design": "系统设计文档",
        "systematic debugging": "系统化故障排查",
        "talking-head-video": "口播短视频制作",
        "team alignment": "团队目标对齐",
        "template creator": "个人模板制作",
        "test-driven development": "测试驱动开发",
        "three-statement forecast": "三大财务报表预测",
        "topic-radar-suite": "全网选题雷达",
        "translate design": "设计内容翻译",
        "ui-plugin-navigation": "工具面板导航",
        "update pet": "更新桌面萌宠",
        "using git worktrees": "独立开发目录管理",
        "using superpowers": "增强技能使用指南",
        "validate-with-ai": "智能质量核验",
        "verification before completion": "交付前核验",
        "viral-video-script": "短视频脚本策划",
        "visualize": "交互可视化",
        "web-access": "网页访问与采集",
        "web-access-v2": "网页深度访问",
        "website to hyperframes": "网页转动态视频",
        "wechat-ai-review-generator": "AI 评测公众号",
        "wechat-autopilot": "公众号全流程自动化",
        "wechat-cover-generator": "公众号封面设计",
        "wechat-cover-skill": "公众号封面渲染引擎",
        "wechat-formatter": "公众号文章排版",
        "wechat-outlier-monitor": "公众号异常爆文监测",
        "weread-skills": "微信读书助手",
        "workbuddy-credits-manager": "工作搭档积分管家",
        "write-like-me": "个人文风写作",
        "writing plans": "编写实施计划",
        "writing skills": "编写技能",
        "xiaolongxia-skill-coach": "小龙虾技能教练",
        "xlsx": "电子表格编辑",
        "zhihu-publisher": "知乎内容发布",
        "zsxq-suite": "知识星球运营助手",
        "中文markdown转pdf": "中文长文转便携文档",
        "公众号文章转md": "公众号文章转纯文本文稿",
        "公众号文章转pdf": "公众号文章转便携文档",
        "公众号百万级排版skill": "公众号文章专业排版",
        "双身份saas架构": "双身份软件服务架构",
        "命令行转mcp连接器": "命令行转工具连接器",
        "品牌geo改写": "品牌智能搜索优化",
        "星球知识库cli": "星球知识库命令行",
        "流程sop视频": "标准操作流程视频",
        "知识星球cli": "知识星球命令行",
        "课程资料pdf设计": "课程资料文档设计",
        "高端ppt设计": "高端演示文稿设计",
    ]
    static func name(_ original: String, description: String = "", path: String = "") -> String {
        if let translated = names[original.lowercased()] { return translated }
        guard original.range(of: "[A-Za-z]", options: .regularExpression) != nil else { return original }
        let chinese = description.components(separatedBy: .newlines).first(where: { $0.range(of: "[\u{4E00}-\u{9FFF}]", options: .regularExpression) != nil }) ?? ""
        if !chinese.isEmpty {
            let cleaned = chinese.replacingOccurrences(of: "[A-Za-z0-9_`/:.()\\-]+", with: "", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines)
            if cleaned.count >= 3 { return String(cleaned.prefix(22)) }
        }
        return "自定义技能"
    }
}
