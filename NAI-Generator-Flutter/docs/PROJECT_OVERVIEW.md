# NAI Generator Flutter - 项目说明

更新时间：2026-04-17

## 1. 项目简介
- 包名：`nai_casrand`
- 版本：`0.9.2`
- 简述：一个基于 Flutter 的 NovelAI 图像批量生成客户端，支持按级联规则随机组合提示词（prompt），并调用 API 批量生图。

## 2. 平台与运行环境
- Flutter SDK：`>=3.3.4 <4.0.0`
- 工程包含的平台目录：`android/ ios/ web/ windows/ macos/ linux/`
  - 说明：目录存在并不代表所有平台已完善测试。

## 3. 目录结构概览
- `lib/` 核心代码
  - `lib/ui/` 页面与视图模型（MVVM，按功能划分）
  - `lib/data/models/` 配置/数据模型（10 个文件）
  - `lib/data/services/` 网络/文件/推送/日志服务（6 个文件）
  - `lib/data/use_cases/` 业务用例（生成 payload）
  - `lib/core/constants/` 常量与默认值
- `assets/` 资源与本地化
  - `assets/json/example.json` 默认配置
  - `assets/l10n/en.json` / `assets/l10n/zh-CN.json` 文案
- `docs/` 文档

## 4. 关键依赖（节选）
- `easy_localization`：多语言
- `get_it`：依赖注入 / 服务定位器
- `http`：网络请求
- `hive`：配置持久化
- `encrypt`：API Token 本地加密
- `file_picker` / `path_provider`：文件选择与路径
- `image` / `archive`：图片与 zip 处理
- `flutter_command`：异步命令封装
- `adaptive_theme`：自适应亮暗主题
- `super_drag_and_drop` / `super_clipboard`：拖放与剪贴板
- `png_chunks_extract`：V4 vibe bundle PNG iTXt 解析

## 5. 生图流程（核心逻辑）
1) 生成 payload（`GeneratePayloadUseCase`）
2) 确定 endpoint（三级优先：sentry 反代 > debug API > 直连 NAI）
3) 发送请求（`ApiService.fetchData`，支持可配超时）
4) 解析返回（`ImageService.processResponse` 解压 zip）
5) 可选处理：嵌入自定义 metadata
6) 生成文件名并保存到输出目录
7) 更新 UI 卡片（成功或错误）

错误处理要点：
- 401 会触发 Bark 推送（需启用开关+有效 token）
- 429 直接抛异常，显示限流提示（不再进入 ZIP 解压流程）
- API 请求支持可配超时（默认 60 秒，0 = 无限等待），超时抛 `TimeoutException`
- payload 有最多 3 次缓存重用策略

## 6. 批次与等待策略
- `batch_count`：每批次请求数
- `batch_interval` + `batch_interval_jitter`：批次间等待（随机偏差）
- `batch_inner_interval` + `batch_inner_interval_jitter`：批次内等待（随机偏差）
- `number_of_requests`：总生成数（0 = 无限）

## 7. 配置与存储
- 默认配置来自 `assets/json/example.json`
- 配置持久化使用 `Hive`（存储在应用数据目录）
- 通过 UUID 管理多份配置，并可导入/导出
- API Token 通过 `encrypt` 包加密后存储

## 8. 设置项概览（关键字段）
- API：`api_key`、`debug_api_path`、`debug_api_enabled`
- Sentry 反代：`sentry_proxy_enabled`、`sentry_proxy_base_url`
- 网络：`proxy`
- 超时：`api_timeout`（默认 60 秒，0 = 无限等待）
- 输出：`output_folder`（Windows）、`file_name_prefix_key`
- 生成：`batch_count`、`batch_interval`、`batch_interval_jitter`
        `batch_inner_interval`、`batch_inner_interval_jitter`
        `number_of_requests`
- 元数据：`metadata_erase_enabled`、`custom_metadata_enabled`、`custom_metadata_content`
- UI：`generation_page_column_count`、`theme_mode`
- Bark：`bark_token`、`bark_notify_auth_fail`、`bark_notify_auth_fail_cooldown`

## 9. Sentry 反代劫持

当多人共享同一 NovelAI 账号时，Token 会被互相覆写。nai-sentry 是一个独立的 Python 守护脚本，持续监控 Token 状态并自动夺回。

- 启用后，生图请求走 `localhost:7899`（可配），nai-sentry 自动注入最新 Token
- Flutter 端发送占位符 `Bearer sentry-placeholder`，反代替换为真实 Token
- 启用时 API Key 和 HTTP 代理字段灰显（由 sentry 接管）
- 设置页提供连通性测试按钮（GET `/token`，3 秒超时）

使用前提：
1. nai-sentry 已安装并配置好 `.env`
2. `.env` 中设置 `TOKEN_SERVICE_ENABLED=true`
3. 运行 `nai-sentry run`
4. Flutter 设置页开启「反代劫持」开关

详见 `docs/SENTRY_PROXY_INTEGRATION.md`。

## 10. Bark 推送
- 触发：API 返回 401（Unauthorized）
- 方式：`POST https://api.day.app/push`（JSON）
- 标题前缀：`[Nai] `
- 限频：默认 60 秒内只推送一次

## 11. 本地化
- 语言文件：`assets/l10n/en.json`、`assets/l10n/zh-CN.json`
- 使用 `easy_localization`
- 当前 i18n key 覆盖：基础 UI、sentry 反代（11 key）、API timeout（2 key）、429 限流（1 key）

## 12. Windows 运行/打包
- 一键运行：`run_windows.bat`（支持 `clean` 参数清理构建缓存）
- 一键打包：`build_windows.bat`
- 手动命令：
  - 运行：`flutter run -d windows`
  - 打包：`flutter build windows`

## 13. CI/CD
- GitHub Actions 三条流水线：
  - `windows.yml` — 构建 Windows release，上传 ZIP artifact
  - `android.yml` — 构建签名 APK，上传 artifact
  - `web.yml` — 构建 Web release，部署到 `deploy` 分支
- 均使用 Flutter 3.29.3 stable
- 支持 `--dart-define-from-file=secrets.json`（从 GitHub Secrets 解码）

## 14. 近期改动
详见 `docs/CHANGES.md`。
