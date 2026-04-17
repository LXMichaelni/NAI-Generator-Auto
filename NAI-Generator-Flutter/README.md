# NAI CasRand

<p align="center">
  <img src="assets/appicon.png" alt="NAI CasRand" width="128" height="128"/>
</p>

<p align="center">
  <b>NAI Cascaded Random Generator</b><br/>
  一个基于 Flutter 的 NovelAI 图像批量生成工具，支持按级联规则随机组合提示词（prompt），并调用官方 API 批量生图。
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.3%2B-02569B?logo=flutter" alt="Flutter"/>
  <img src="https://img.shields.io/badge/Dart-%3E%3D3.3-0175C2?logo=dart" alt="Dart"/>
  <img src="https://img.shields.io/badge/version-0.9.2-green" alt="version"/>
  <img src="https://img.shields.io/badge/platform-Windows%20%7C%20Android%20%7C%20Web%20%7C%20macOS%20%7C%20Linux-lightgrey" alt="platform"/>
  <img src="https://img.shields.io/badge/license-MIT-blue" alt="license"/>
</p>

---

## 目录

- [简介](#简介)
- [核心特性](#核心特性)
- [界面展示](#界面展示)
- [快速上手](#快速上手)
- [Prompts 级联配置](#prompts-级联配置)
- [Sentry 反代劫持](#sentry-反代劫持)
- [支持平台](#支持平台)
- [从源码构建](#从源码构建)
- [项目结构](#项目结构)
- [常见问题](#常见问题)
- [许可证](#许可证)

---

## 简介

**NAI CasRand** 是一个按指定模式生成随机提示词（prompt）、并将其与生成参数一起发送到 NovelAI API 以获取图像的工具。它解决了以下几类典型需求：

- 想从大量喜欢的画师 / 风格中，通过组合和统计找到最合适的搭配；
- 想批量得到某个或某组角色在不同场景、动作下的图像；
- 想要持续、无人值守地 roll 图，通过概率和级联结构让结果既丰富又可控。

通过**级联（Cascaded）**的配置体系，你可以精细地描述"什么时候选哪些词、以什么方式拼接、以多大的概率出现、以及要不要加权"，然后让 CasRand 自动地循环生成。

## 核心特性

- 🎲 **级联随机提示词**：支持 `单个（随机/顺序）`、`多个（指定数量/指定概率）`、`全部` 五种选取模式，任意嵌套。
- 🖌️ **权重括号随机化**：为每个被选中的词条随机添加 `{}` 括号，自动调整权重。
- 🔗 **前后缀插入语法**：使用 `|||` 分隔符，可以把一条词条拆成前后两半分别拼接到 prompt 的首尾。
- 🖼️ **完整的生成参数**：支持 txt2img、img2img、Vibe Transfer（V4 vibe bundle），以及 Director Tools 全套功能。
- 🧩 **配置导入 / 导出**：所有设置可以一键保存为 JSON，在 PC Web 端编辑好后导入到手机上批量生图。
- 🌐 **跨平台**：同一套代码支持 Windows / Android / Web / macOS / Linux。
- 🌏 **多语言**：内置简体中文与英文（`easy_localization`）。
- 🎨 **自适应主题**：跟随系统亮暗，并支持手动切换（`adaptive_theme`）。
- 🔐 **本地加密存储**：使用 `hive` + `encrypt` 在本地安全地保存 API Token。
- 🔄 **Sentry 反代劫持**：接入 nai-sentry 本地反向代理，多人共享账号时自动夺回 Token，生图端无感切换。
- ⏱️ **可配 API 超时**：默认 60 秒超时，可在设置页调整（0 = 无限等待），避免请求永久挂起。
- 🛡️ **429 限流保护**：频率受限时直接提示，不再误报 ZIP 解压错误。

## 界面展示

| 图像生成                | 提示词设置              |
| ----------------------- | ----------------------- |
| ![](docs/imgs/0001.jpg) | ![](docs/imgs/0002.jpg) |

| I2I / Vibe Transfer 设置 | Director Tools          | 生成参数和用户选项      |
| ------------------------ | ----------------------- | ----------------------- |
| ![](docs/imgs/0003.jpg)  | ![](docs/imgs/0005.jpg) | ![](docs/imgs/0004.jpg) |

## 快速上手

### 1. 填写 Token

进入 **参数设置** 页面，填入 NovelAI 的 API Token。

> Token 获取方式：`novelai.net → 设置 → Account → Get Persistent API Token`

如果没有填写或填写错误，生图时会得到 `Unauthorized` 错误。

如果你使用 nai-sentry 反代劫持（多人共享账号场景），可以跳过手动填写 Token，直接在设置页开启「反代劫持」开关即可。详见下方 [Sentry 反代劫持](#sentry-反代劫持) 章节。

### 2. 生成图片

在 **图像生成** 页面，点击 **开始** 按钮即可按当前设置循环生成；点击 **停止** 结束。

- Web 端：图片以浏览器下载的方式保存。
- Android 端：图片自动保存到相册。
- 桌面端：保存到指定目录。

在页面设置菜单中可调整每轮生成数量、展示方式等。

### 3. 保存 / 读取配置

在 **参数设置** 页面：

- **保存**：将当前所有设置（含 prompts 配置）导出为 JSON 文件。
- **导入**：读取此前保存的 JSON，恢复全部设置。

导出的 JSON 是跨平台的，可以在 PC Web 端精心编辑完，再同步到手机上批量生图。

## Prompts 级联配置

NAI CasRand 用一棵 **Config 树** 来描述如何从词条池中随机组合 prompts。每个 `Config` 节点都具有以下属性：

| 属性           | 作用                                                                  | 可选值                                                                          |
| -------------- | --------------------------------------------------------------------- | ------------------------------------------------------------------------------- |
| `选取方式`     | 指示如何从下属内容里选取                                              | `单个-随机`、`单个-顺序`、`多个-指定数量`、`多个-指定概率`、`全部`              |
| `打乱顺序`     | 当选取 `多个-指定概率` 或 `全部` 时，是否打乱选中内容顺序             | `是` / `否`                                                                     |
| `选中数量`     | 当选取 `多个-指定数量` 时，指定选中的数量                             | 整数（≤ 下属长度）                                                              |
| `选中概率`     | 当选取 `多个-指定概率` 时，每条被选中的概率                           | 浮点数（0~1）                                                                   |
| `随机括号数量` | 为每个被选中条目，随机添加 `{}` 括号以调权重                          | 两个整数 `[min, max]`                                                           |
| `下属设置类型` | 下属是一组字符串词条，还是嵌套的子 Config                             | `字符串内容` / `嵌套 Config`                                                    |
| `下属设置内容` | 具体内容                                                              | 若为字符串：每行一个词条；若为嵌套：一个 Config 列表                             |

### 使用技巧

- **顺序遍历的陷阱**：当多个 Config 同时使用 `单个-顺序遍历` 时，由于各自计数器独立，可能出现某些组合永远不会被选中。
- **前后缀语法**：如果词条中包含 `|||`，软件会把该词条按分隔符切成两段，前段拼接到当前 prompt 的开头、后段拼接到末尾。可用于"在一段 prompt 中间插入额外内容"。
- **Prompt 预览**：在生成页面的设置中可以 **只生成 prompt、不生成图片**，用来调试当前配置。

### 默认配置示例

每次启动时会加载一个简单的默认配置作为示范，其顶层 Config `示例提示词` 以 `全部` 模式串起以下子节点：

| 子 Config  | 作用                                                   |
| ---------- | ------------------------------------------------------ |
| `角色`     | 从列表中 **随机选一个** 角色                            |
| `画师`     | **随机选 4 个** 画师，每个额外随机加 0~2 层权重括号     |
| `特殊风格` | 以 **3% 概率** 追加线稿、3D 模型等特殊风格              |
| `前缀`     | 固定拼接的前缀（例如："必须是萝莉"）                    |
| `内容`     | 从若干动作 / 场景中 **随机选一个**                      |
| `背景`     | 固定背景描述                                            |
| `质量`     | 固定的质量标签（"叠 buff"）                             |

## Sentry 反代劫持

当多人共享同一 NovelAI 账号时，Token 会被互相覆写导致生图中断。[nai-sentry](../Dev) 是一个独立的 Python 守护脚本，持续监控 Token 状态，被抢时自动夺回。

开启后，Flutter 客户端的生图请求走本地反代（默认 `localhost:7899`），nai-sentry 自动注入最新 Token，实现无感替换。

### 使用方式

1. 确保 nai-sentry 已安装并运行（`nai-sentry run`）
2. 在 Flutter 设置页展开「反代劫持」区块
3. 勾选「启用反代劫持」
4. （可选）点击「测试连通」确认服务可达

启用后，API Key 和 HTTP 代理字段会灰显——它们的值不会被修改，只是本次不使用（由 sentry 接管）。关闭开关后恢复原有行为。

### 数据流

```
Flutter → POST localhost:7899/ai/generate-image (Bearer sentry-placeholder)
  → nai-sentry 替换为真实 Token，通过 VPN 代理转发
    → POST image.novelai.net/ai/generate-image (Bearer pst-xxx...)
```

详细技术文档见 `docs/SENTRY_PROXY_INTEGRATION.md`。

## 支持平台

| 平台     | 状态   | 说明                                             |
| -------- | ------ | ------------------------------------------------ |
| Windows  | ✅     | 提供 `run_windows.bat` / `build_windows.bat`     |
| Android  | ✅     | 自动保存图片到相册，需授予存储权限               |
| Web      | ✅     | 浏览器下载图片                                   |
| macOS    | ✅     | 需自行配置签名                                   |
| Linux    | ✅     | 需安装 GTK 依赖                                  |
| iOS      | ⚠️     | 代码可编译，未做上架适配                         |

## 从源码构建

### 前置条件

- Flutter SDK ≥ **3.3.4**（稳定通道）
- Dart SDK ≥ **3.3**
- 目标平台对应的构建工具链（Android Studio / Visual Studio Build Tools / Xcode 等）

### 步骤

```bash
# 1. 克隆仓库
git clone <repo-url>
cd NAI-Generator-Flutter

# 2. 拉取依赖
flutter pub get

# 3. 运行（开发模式）
flutter run                 # 自动检测默认设备
flutter run -d chrome       # Web
flutter run -d windows      # Windows

# 4. 打包发布
flutter build windows       # Windows: build/windows/x64/runner/Release/
flutter build apk --release # Android: build/app/outputs/flutter-apk/
flutter build web           # Web:     build/web/
flutter build macos         # macOS
flutter build linux         # Linux
```

Windows 用户也可以直接双击根目录下的 `run_windows.bat` 或 `build_windows.bat`。

## 项目结构

```
NAI-Generator-Flutter/
├── lib/
│   ├── main.dart            # 应用入口
│   ├── core/                # 核心领域逻辑（prompt 级联、API 调用、加密、存储）
│   ├── data/                # 数据模型与仓储层
│   └── ui/                  # 各页面与组件
├── assets/
│   ├── appicon.png
│   ├── json/example.json    # 默认配置示例
│   └── l10n/                # 多语言资源（en / zh-CN）
├── android/ ios/ web/ windows/ macos/ linux/   # 各平台壳工程
├── docs/                    # 文档与截图
├── pubspec.yaml             # 依赖与资源清单
├── run_windows.bat          # Windows 一键运行
├── build_windows.bat        # Windows 一键打包
└── README.md
```

## 常见问题

**Q: 提示 `Unauthorized` / 401 怎么办？**
A: 检查 **参数设置** 里的 API Token 是否填写正确，并确认网络能访问 `api.novelai.net`。如果使用 sentry 反代，确认 nai-sentry 服务正在运行，可点击「测试连通」按钮验证。

**Q: 提示「请求频率受限 (429)」怎么办？**
A: NovelAI API 有频率限制。适当增大批次间等待时间（`batch_interval`）和批次内等待时间（`batch_inner_interval`），或减少并发请求数。

**Q: 生图请求一直卡住不返回？**
A: 在设置页 Batch settings 中可配置 API 超时时间（默认 60 秒）。设为 0 表示无限等待。超时后会自动跳过当前请求继续下一张。

**Q: Android 端不保存图片？**
A: 请确认已经授予 App 的存储 / 相册权限（安装后首次保存时会请求）。

**Q: Web 端图片保存到哪里？**
A: Web 模式会触发浏览器下载，文件保存在浏览器的默认下载目录。

**Q: Token 是明文保存的吗？**
A: 不是，Token 通过 `encrypt` 包加密后落到本地 `hive` 存储。

**Q: Sentry 反代启用后原来的 API Key 会被删掉吗？**
A: 不会。开关只控制本次请求走哪条路径，原有的 API Key 和代理设置值不会被修改，关闭开关后立即恢复使用。

**Q: 为什么顺序遍历有时候跳过了一些组合？**
A: 见上文 *"顺序遍历的陷阱"*。多个同级的 `单个-顺序` Config 会各自独立计数，组合上会出现周期错位。建议把需要完整遍历的轴合并到同一个 Config 中。

## 许可证

本项目基于 [MIT License](LICENSE) 开源。请在合法合规的前提下使用 NovelAI API，勿用于违反当地法律或 NovelAI 服务条款的用途。
