<div align="center">

<img src="assets/showcase/hero-banner.jpg" alt="汇芯技能管家：四个工具的技能，放进一个中文菜单栏" width="100%" />

# 汇芯技能管家
### `huixin-skills-manager` · 按工作流自动归类，也能建立自己的技能分类

[![平台](https://img.shields.io/badge/macOS-14%2B-C8102E?style=flat-square)](#二安装与快速开始)
[![引擎](https://img.shields.io/badge/原生界面-SwiftUI-18181B?style=flat-square)](#三它怎样工作)
[![原则](https://img.shields.io/badge/中文显示-保留原始调用名-B45309?style=flat-square)](#四几个容易踩的坑)
[![许可](https://img.shields.io/badge/新增部分-MIT-059669?style=flat-square)](LICENSE)

> **中文增强版：袁六伟 · 台州汇芯**｜一人 AI 公司创始人，学员 7000+ 人，服务商单客户 100+ 家（覆盖近 20 个行业），得到 / 华为分享老师。  
> **公众号 / 视频号：袁六伟** · AI 变现实战派，自己跑通才拿出来教。

**技能装了很多，真正需要时，却想不起它叫什么、装在哪个工具里。** 汇芯技能管家不仅是你每个 AI 工具（Gemini、Codex、Grok Bot、WorkBuddy）的随身 Skill 助手，更是统管全机技能资产的**「技能中央大脑」**：把本地技能集中展示，按工作流自动分类、自定义分类、按工具筛选，按中文搜索，点开查看说明，复制原始调用名或打开文件位置。它管理的是技能文件，不负责执行技能，也不读取账号额度。

**来源致谢：本项目基于 [Aman Mittal 的 SkillsBar](https://github.com/amandeepmittal/skillsbar) 二次开发。感谢原作者提供菜单栏技能浏览器的产品原型与代码基础。保留原作者版权与 Apache-2.0 许可；本版新增部分采用 MIT。具体来源和修改范围见 [NOTICE](NOTICE)。**

[看实际界面](#一先看实际界面) · [安装使用](#二安装与快速开始) · [目录与功能](#三它怎样工作) · [常见问题](#四几个容易踩的坑) · [开源与致谢](#五仓库结构与开源边界)

</div>

## 一、先看实际界面

下面是本机运行应用后导出的真实原生界面。图中的数量来自示例机器，安装后会按你自己的文件重新扫描。

<img src="assets/showcase/01-real-interface.png" alt="汇芯技能管家原生界面：中文技能名称、四个来源、搜索与收藏" width="100%" />

| 使用时遇到的问题 | 汇芯技能管家的处理方式 |
|---|---|
| 多个工具的技能分散在不同文件夹 | Gemini、Codex、Grok Bot、WorkBuddy 分开扫描，放进同一窗口 |
| 英文技能名不容易记 | 为已知技能提供中文展示名，支持中文与原始名称搜索 |
| 为了改中文，改坏了技能文件名 | 只改应用的显示层，保留原始目录、文件、调用标识 |
| 不清楚技能到底从哪里来的 | 保留来源、真实路径、项目范围和插件范围 |
| 小窗口里名称和说明挤在一起 | 面板加宽到 760 点，列表和说明有更充足的左右空间 |
| 只记得要做什么，不记得技能属于哪个工具 | 按公众号、视频、企业交付、知识管理等工作流自动归类 |
| 一个项目要用多个工具里的技能 | 新建自定义分类，跨来源添加技能；一个技能可加入多个分类 |
| 新增技能后要重新打开整个工具 | 监听技能目录变化，并提供手动刷新 |

### 这一版实际改了什么

在原版的 Claude Code、Codex、Pi 基础上，本版改为 Gemini、Codex、Grok Bot，并新增 WorkBuddy。这里替换的是扫描目录和分组逻辑，并非只换标签。技能名称的中文映射在本地完成，不上传技能正文，也不调用模型翻译。

## 二、安装与快速开始

### 方式一：下载应用

到 [下载页面](https://github.com/sixwei2025/huixin-skills-manager/releases/latest) 下载 macOS 安装包；解压后把“汇芯技能管家.app”拖入“应用程序”。

应用为开源构建，使用本地临时签名，尚未进行 Apple 开发者签名与公证。如果系统阻止打开，请按 macOS 正常的安全提示处理，或使用下面的源码方式构建。不要关闭系统安全保护。

### 方式二：从源码构建

需要 macOS 14 或更新版本，以及包含命令行工具的 Xcode。无需配置任何模型密钥。

```bash
git clone https://github.com/sixwei2025/huixin-skills-manager.git
cd huixin-skills-manager
bash scripts/build.sh
```

完成后打开 `build/distribution/汇芯技能管家.app`。安装包在 `build/huixin-skills-manager-macos.zip`。

### 安装配套助手 Skill（可选）

```bash
npx skills add sixwei2025/huixin-skills-manager
```

这条命令安装“汇芯技能管家”的安装与使用指引，让你的智能助手知道怎样构建、启动和排查本工具；它不等于桌面应用安装命令。

### 打开之后怎么用

1. 点击菜单栏中的技能图标，或按 **⌥⇧S** 打开面板。
2. 选择 Gemini、Codex、Grok Bot 或 WorkBuddy。
3. 输入中文名称、原始名称或关键词搜索。
4. 点开技能，查看说明、复制原始调用名称，或打开真实文件位置。
5. 点击 **工作流分类**，按用途浏览；左侧 **我的分类 → ＋** 可新建分类，改名后点“保存”，再点“添加技能”勾选。
6. 技能卡片右侧 **⋯ → 调整工作流归类** 可以纠正自动结果，也可“恢复自动归类”。同一个技能可加入多个自定义分类；删除分类保留技能文件。

**与原版并存时，只运行其中一个。** 原版和本版沿用相同快捷键，同时运行会出现两个菜单栏图标。首次使用建议退出旧版 SkillsBar，保留本版。原版的偏好设置不会被本版覆盖；本版使用独立应用标识 `cn.huixin.skillsmanager`。

## 三、它怎样工作

### 工作流分类（v1.1.0）

分类页将四个来源的技能放在一起，默认按名称、所在文件夹及说明中的关键词，分到公众号与内容、视频制作、企业与交付、知识管理、选题与调研、设计与配图、办公与协作、开发与工具、其他技能。它是可解释的本地规则分类，不调用模型、不上传正文，也不执行这些工作流。分类可能有误，可在技能右侧菜单纠正。

<img src="assets/showcase/02-workflow-categories.png" alt="工作流分类真实界面：左侧用途分类、右侧技能列表与来源筛选" width="100%" />

自定义分类支持创建、改名、跨来源添加或移出技能、删除分类；原来的收藏夹自动沿用。手动归类和自定义分类保存在本机应用偏好设置中，关闭再打开仍保留。指向同一个真实文件的多来源链接合并展示；内容相同但实际分开的两份文件仍视为不同技能。移动或重新安装技能后路径改变，可能需要重新添加到自定义分类。

分类页的“全部来源”可以进一步筛选 Gemini、Codex、Grok Bot、WorkBuddy。搜索会在当前分类和来源内进行。首次更新默认打开分类页，之后记住你选择的页面。


<img src="assets/showcase/pipeline-architecture.jpg" alt="汇芯技能管家：扫描真实目录、解析技能、中文展示、搜索收藏、保留原始调用" width="100%" />

| 来源 | 默认读取位置 | 说明 |
|---|---|---|
| Gemini | `~/.gemini/skills/`、`~/.gemini/config/skills/`、`~/.gemini/config/plugins/`、`~/.gemini/antigravity-cli/builtin/skills/` | 兼容当前机器的谷歌命令行与内置技能目录 |
| Codex | `~/.codex/skills/`、`~/.codex/skills/.system/`、`~/.codex/plugins/cache/` | 用户、内置、插件技能，以及插件目录信息 |
| Grok Bot | `~/.grokbot/skills/`、`~/.agents/skills/` | 本版使用 Grok Bot 的本地技能目录；不是官方 Grok Build 的额度接口 |
| WorkBuddy | `~/.workbuddy/skills/` | 支持技能目录与目录集合中的技能文件 |
| 项目技能 | 用户添加项目下的 `.gemini/skills/`、`.grokbot/skills/`、`.agents/skills/` | 项目必须由用户明确添加，不全盘搜索电脑 |

同一工具下指向相同真实文件的软链接会去重；不同工具共享一个技能时，各自显示属于正常情况。工具只发现存在于磁盘的技能文件，不保证对应宿主已启用或执行过它。

### 中文名称怎样保持兼容

- `Skill.name`、文件路径、原始调用名保留原值。
- `displayName` 映射为中文，用于列表、详情、收藏与搜索。
- 已知技能有明确中文映射；未知技能优先从中文说明生成简短标题，没有可用说明时标为“自定义技能”。
- 不执行技能正文里的命令，不为了翻译改写 `SKILL.md`。
- 修改中文映射可编辑 `SkillsBar/Models/Skill.swift` 中的 `ChineseSkillNames`，然后重新构建。

### 使用统计的边界

本版只保留已核验的 Codex 本地记录解析。Gemini、Grok Bot 和 WorkBuddy 的调用次数暂不提供；不会拿旧版 Claude Code 或 Pi 的记录冒充它们的使用统计。这里的统计不是账号额度，额度看板请另用对应工具。

## 四、几个容易踩的坑

**改成中文后，原始调用名也跟着变了。** 本版把中文名与调用名分开：你看到的是中文，复制出的仍是原始标识。Grok Bot 与 WorkBuddy 的技能调用方式由宿主决定，本工具不臆造统一的斜杠命令。

**只换了来源标签，目录还在扫旧工具。** 本版按表中真实目录读取，旧 Claude Code/Pi 目录不再作为这些新标签的技能来源。

**说明里只有一个 `>-` 或 `|`。** 已修复多行说明解析，支持折叠与保留换行的常见写法；这不是一个完整 YAML 编辑器，复杂非标准写法仍可能需要整理元数据。

**新装的技能没有中文名。** 中文映射不联网自动生成。未知名称会按中文说明显示摘要，或回退为“自定义技能”；原始标识仍可搜索和查看。欢迎提交准确的中文映射。

**收藏里的名称变了，会不会丢文件？** 收藏与技能身份继续按真实路径关联。改中文展示不会移动文件。跨机器迁移路径时，仍需要重新定位原目录。

## 五、仓库结构与开源边界

```text
huixin-skills-manager/
├── README.md                 # 中文介绍与使用说明
├── LICENSE                   # 本版新增部分的 MIT 许可
├── licenses/                 # 上游 Apache-2.0 许可，保留原作者版权
├── NOTICE                    # 上游来源、提交版本与本次修改范围
├── SkillsBar/                # 基于上游的原生应用源码
│   ├── Models/               # 来源、中文显示名、收藏等数据结构
│   ├── Services/             # 本地扫描、目录监听、解析与搜索
│   ├── Views/                # 菜单栏、列表、详情和设置界面
│   └── SkillsBarLayout.swift # 760 点宽布局
├── skills/huixin-skills-manager/SKILL.md # 可单独安装的使用助手
├── SkillsBar.xcodeproj/       # Xcode 工程
├── scripts/build.sh          # 构建、签名、核验与打包
├── assets/showcase/          # 品牌头图、架构图、真实界面
├── docs/                     # 验证与来源说明
└── scripts/github-actions-build.yml # 可手动启用的自动构建示例
```

本项目以 macOS 桌面工具为主，并附带安装与使用助手 Skill。`npx skills add` 只安装助手的明文指引，不会自动安装桌面应用；桌面程序需下载构建附件或从源码构建。仓库不包含本机技能正文、账户凭证、浏览器登录会话、客户文件和知识库内容。列表中的第三方技能仍归各自作者所有，中文别名不改变其权利归属。

### 致敬与感谢

- **直接开发基础与产品原型**：[SkillsBar · Aman Mittal](https://github.com/amandeepmittal/skillsbar)。本版从提交 `85fe0018278505445433eea32809d1d9d7fde57e` 开始修改，保留 Apache-2.0 协议与原作者版权。
- **同名早期项目**：[SkillsBar · alberduris](https://github.com/alberduris/SkillsBar)，感谢菜单栏技能管理这一方向的公开探索。
- **菜单栏工具生态**：[CodexBar](https://github.com/steipete/CodexBar)，感谢开源社区的经验分享。本工具与这些作者、Google、OpenAI、Cursor、腾讯均无官方从属或背书关系。

### 关于汇芯与同系列项目

袁六伟，一人 AI 公司创始人。学员 7000+ 人，服务商单客户 100+ 家（覆盖近 20 个行业），得到 / 华为分享老师。我们关注实际业务中的 AI 应用，自己跑通才拿出来教。公众号 / 视频号：**袁六伟**。

| 项目 | 用途 |
|---|---|
| [汇芯技能管家](https://github.com/sixwei2025/huixin-skills-manager) | 本地技能中文浏览与分类管理 |
| [公众号封面渲染引擎](https://github.com/sixwei2025/wechat-cover-skill) | 公众号封面制作 |
| [公众号排版工具](https://github.com/sixwei2025/gzh-million-layout-skill) | 手机阅读排版 |
| [工具评测写作](https://github.com/sixwei2025/ai-tool-review-wechat-skill) | 真实工具评测内容制作 |
| [本地视频中心](https://github.com/sixwei2025/local-video-hub) | 本地视频作品管理 |
| [口播视频制作](https://github.com/sixwei2025/talking-head-video-skill) | 口播视频制作 |
| [三维地图视频](https://github.com/sixwei2025/3d-map-video-skill) | 地图讲解视频制作 |


| [动态图解视频](https://github.com/sixwei2025/dark-infographic-video-skill) | 数据图解与短视频制作 |
| [书籍提炼工具](https://github.com/sixwei2025/book-skill) | 将书籍方法整理为可复用技能 |
| [历史认知方法](https://github.com/sixwei2025/huangdi-skill) | 历史材料与决策方法学习 |
| [标题策划](https://github.com/sixwei2025/hit-title-expert-skill) | 内容标题策划 |
| [可视化教程](https://github.com/sixwei2025/auto-tutorial-skill) | 软件使用教程制作 |
| [心理科普视频](https://github.com/sixwei2025/psych-kepu-video-skill) | 心理科普动画 |
| [一人公司方法库](https://github.com/sixwei2025/yuanliuwei-ai-skills) | 一人公司业务方法 |
| [内容选题雷达](https://github.com/sixwei2025/sunrise-tracker) | 内容选题监测 |


如果这个工具帮你找技能更方便，欢迎收藏项目、反馈使用问题，或贡献中文名称映射。

### 总览以 Gemini 为主

Gemini 是写内容、做视频和出课程的主力。工作流分类总览仅展示 Gemini 已安装的技能，分类数量和总览数量统一按 Gemini 统计。同一技能在 Gemini 中重复安装时仍只计一项。Codex、Grok Bot、WorkBuddy 的安装记录保留在各自栏目。手动归类与自定义分类继续支持同步副本，兼容旧版保存的分类。
