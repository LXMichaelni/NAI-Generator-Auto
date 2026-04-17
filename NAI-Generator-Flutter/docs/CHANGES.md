# 项目改动记录

---

## 2026-04-17 — API 请求链路修复 + Sentry 反代劫持

### Sentry 反代劫持（无感替换 API Key）

对应 commit: `86806d2`

接入 nai-sentry 本地反向代理服务，实现 Token 的无感替换。当多人共享同一 NovelAI 账号时，nai-sentry 守护脚本会自动夺回被覆写的 Token，Flutter 客户端通过反代发送请求，无需手动管理 Token。

改动要点：
- `Settings` 新增 `sentryProxyEnabled` / `sentryProxyBaseUrl` 两个字段
- `PayloadConfig.getHeaders()` 在 sentry 启用时发送占位符 Token，由反代替换为真实 Token
- 生图 endpoint 三级优先：sentry 反代 > debug API > 直连 NAI
- 设置页新增 sentry 反代区块（开关、地址输入、连通性测试按钮）
- API Key 和 HTTP 代理在 sentry 启用时灰显
- i18n 新增 11 个 `sentry_proxy_*` key（中/英）

详见 `docs/SENTRY_PROXY_INTEGRATION.md`。

### API 请求链路修复（VBM 审计）

基于 VBM 审计（`vbm-api-fix-plan.csv`）完成的三项修复：

#### T1: Content-Type header

- `payload_config.dart` 的 `getHeaders()` 中添加 `'content-type': 'application/json'`
- 修复前 `http` 包默认发送 `text/plain`，部分场景下 API 可能拒绝请求

#### T2: 可配置 API 超时（T2-a ~ T2-g）

- `Settings` 新增 `apiTimeoutSec` 字段（默认 60 秒，0 = 无限等待）
- `ApiRequest` 新增 `Duration? timeout` 可选参数
- `ApiService.fetchData()` 在有 timeout 时附加 `.timeout()`
- `GenerationPageViewmodel` 从 settings 读取超时值并传入请求
- `SettingsPageViewmodel` 新增 `setApiTimeout()` setter
- 设置页 Batch settings 展开后底部新增 API timeout 输入框
- i18n 新增 `api_timeout` / `api_timeout_hint` key（中/英）

#### T3: 429 状态码正确处理

- 429 响应后直接 `throw Exception(tr('rate_limit_429'))`，不再进入 ZIP 解压流程
- 修复前：429 → 记日志 → 继续解压 → 解压失败 → 显示误导性错误
- 修复后：429 → 记日志 → throw → catch 显示正确的限流提示
- i18n 新增 `rate_limit_429` key（中/英）

### 变更文件列表

- `lib/data/models/settings.dart` — 新增 sentry 字段 + apiTimeoutSec 字段
- `lib/data/models/payload_config.dart` — Content-Type header + sentry 占位符 Token
- `lib/data/models/api_request.dart` — 新增 timeout 字段
- `lib/data/services/api_service.dart` — 支持 timeout
- `lib/ui/generation_page/view_models/generation_page_viewmodel.dart` — sentry endpoint 路由 + timeout 传递 + 429 throw
- `lib/ui/settings_page/view_models/settings_page_viewmodel.dart` — sentry 方法 + setApiTimeout + testSentryProxy
- `lib/ui/settings_page/widgets/settings_page_view.dart` — sentry UI 区块 + timeout 输入框
- `assets/l10n/en.json` — 新增 14 个 i18n key
- `assets/l10n/zh-CN.json` — 新增 14 个 i18n key

---

## 2026-02-03 — 批次等待 + Bark 推送 + Windows 脚本

（由 Codex 生成）

### 生成流程
- 批次冷却加入随机偏差（基于 `batch_interval_jitter`）。
- 批次内新增等待与随机偏差（基于 `batch_inner_interval`/`batch_inner_interval_jitter`）。
- 401 认证失败时触发 Bark 推送（受开关与冷却时间控制）。

### 设置项与配置
- 新增设置项：
  - `batch_interval_jitter`
  - `batch_inner_interval`
  - `batch_inner_interval_jitter`
  - `bark_token`
  - `bark_notify_auth_fail`
  - `bark_notify_auth_fail_cooldown`
- 设置页新增对应输入框/勾选项。

### UI 提示
- 批次冷却提示（显示本次等待秒数）。
- 批次内等待提示（显示本次等待秒数）。

### Bark 推送
- 新增 Bark 推送服务封装（POST `/push`，支持代理）。
- 推送标题统一加前缀 `[Nai] `。

### 脚本
- `run_windows.bat`：一键 `flutter run -d windows`
- `build_windows.bat`：一键 `flutter build windows`

### 变更文件列表
- `lib/ui/generation_page/view_models/generation_page_viewmodel.dart`
- `lib/ui/generation_page/widgets/generation_page_view.dart`
- `lib/data/models/settings.dart`
- `lib/data/services/bark_service.dart`（新增）
- `lib/ui/settings_page/view_models/settings_page_viewmodel.dart`
- `lib/ui/settings_page/widgets/settings_page_view.dart`
- `assets/l10n/en.json`
- `assets/l10n/zh-CN.json`
- `run_windows.bat`（新增）
- `build_windows.bat`（新增）
- `pubspec.lock`（Flutter 工具更新）
