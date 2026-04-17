# Sentry 反代劫持功能 — 接入记录

日期：2026-04-17
作者：Claude Code (Michael LX 指导)

---

## 背景

NAI-Generator-Flutter 是一个 NovelAI 批量生图客户端。用户需要手动管理 API Key（Persistent Token），当多人共享同一 NovelAI 账号时，Token 会被互相覆写导致生图中断。

nai-sentry 是一个独立的 Python 守护脚本（位于 `C:\Users\Lenovo\Desktop\noveial-token\Dev`），它持续监控 Token 状态，被抢时自动夺回。nai-sentry 提供了一个本地 Token 服务（反向代理），运行在 `localhost:7899`：

- `GET /token` — 返回最新的 Persistent Token（纯文本）
- 其他路径 — 透明反向代理到 NovelAI，自动注入最新 Token 到 Authorization header

本次改动让 Flutter 生图客户端可以通过 nai-sentry 的反向代理发送请求，实现 Token 的无感替换。

---

## 设计原则

- 最小侵入：只增不删，不改动任何现有字段名、方法签名、文件结构
- 向后兼容：关闭开关后行为与改动前完全一致
- 现有配置保留：sentryProxy 关闭时，apiKey 和 proxy 字段的值不被修改，只是 UI 上灰显

---

## 改动清单（7 个文件，+154 / -7 行）

对应 commit: `86806d2 feat: 接入 nai-sentry 反代劫持 (无感替换 api key)`

### 1. `lib/data/models/settings.dart`

新增两个字段到 Settings 类：

```dart
bool sentryProxyEnabled;        // 默认 false
String sentryProxyBaseUrl;      // 默认 'http://localhost:7899'
```

- constructor 中新增 `required this.sentryProxyEnabled` 和 `required this.sentryProxyBaseUrl`
- `fromJson`: `sentryProxyEnabled: json['sentry_proxy_enabled'] ?? false`
- `fromJson`: `sentryProxyBaseUrl: json['sentry_proxy_base_url'] ?? 'http://localhost:7899'`
- `toJson`: 对应两个字段序列化

### 2. `lib/data/models/payload_config.dart`

`getHeaders()` 方法修改：

```dart
final auth = settings.sentryProxyEnabled
    ? 'Bearer sentry-placeholder'    // sentry 会替换为真实 Token
    : 'Bearer ${settings.apiKey}';   // 原逻辑不变
```

当 sentry 启用时，Authorization header 发送占位符，nai-sentry 反向代理会在转发时替换为真实 Token。

### 3. `lib/ui/generation_page/view_models/generation_page_viewmodel.dart`

endpoint 选择逻辑改为三级优先：

```dart
if (payloadConfig.settings.sentryProxyEnabled) {
  // 优先级 1: sentry 反代 — 请求走 localhost:7899，不走自身 VPN 代理
  endpoint = '$base/ai/generate-image';
  requestProxy = '';
} else if (payloadConfig.settings.debugApiEnabled) {
  // 优先级 2: debug API（原有逻辑）
  endpoint = payloadConfig.settings.debugApiPath;
  requestProxy = payloadConfig.settings.proxy;
} else {
  // 优先级 3: 直连 NovelAI（原有逻辑）
  endpoint = 'https://image.novelai.net/ai/generate-image';
  requestProxy = payloadConfig.settings.proxy;
}
```

关键点：sentry 启用时 `requestProxy = ''`，因为 nai-sentry 自己会通过配置的 VPN 代理转发请求。

### 4. `lib/ui/settings_page/view_models/settings_page_viewmodel.dart`

新增 import: `import 'package:http/http.dart' as http;`

新增 3 个方法：

- `setSentryProxyEnabled(bool? value)` — 切换开关
- `setSentryProxyBaseUrl(String value)` — 修改反代地址
- `testSentryProxy(BuildContext context)` — 连通性测试：GET `$base/token`，3 秒超时，成功显示 Token 前 20 字符

### 5. `lib/ui/settings_page/widgets/settings_page_view.dart`

UI 变更：

- `_buildApiKeyTile()`: sentry 启用时灰显，显示"已由 sentry 接管"
- 新增 `_buildSentryProxyTile(BuildContext context)`: ExpansionTile 包含：
  - CheckboxListTile（启用/禁用开关）
  - EditableListTile（反代地址输入）
  - TextButton（测试连通按钮）
- `_buildProxyTile()`: sentry 启用时灰显，显示"反代劫持启用中，仅关闭后生效"

### 6. `assets/l10n/zh-CN.json`

新增 11 个 i18n key（sentry_proxy_* 前缀），中文文案。

### 7. `assets/l10n/en.json`

新增 11 个 i18n key，英文文案。

---

## i18n Key 完整列表

| Key | zh-CN | en |
|-----|-------|-----|
| `sentry_proxy_section` | 反代劫持 (无感替换 api key) | Sentry Reverse Proxy Hijack (transparent API Key) |
| `sentry_proxy_enabled_subtitle` | 已启用 -- 由本机 nai-sentry 接管 Token 与代理 | ENABLED -- local nai-sentry owns Token & proxy |
| `sentry_proxy_disabled_subtitle` | 未启用 -- 使用上方 API Key 与 HTTP 代理 | DISABLED -- using API Key & HTTP Proxy above |
| `sentry_proxy_toggle` | 启用反代劫持 | Enable Reverse Proxy Hijack |
| `sentry_proxy_toggle_hint` | 开启后请求走本机 sentry，API Key 与 HTTP 代理本次不使用 | Requests go through local sentry; API Key & HTTP Proxy are ignored |
| `sentry_proxy_base_url` | 反代地址 | Sentry Base URL |
| `sentry_proxy_base_url_hint` | nai-sentry Token 服务地址，默认 http://localhost:7899 | nai-sentry Token service URL, default http://localhost:7899 |
| `sentry_proxy_api_key_hijacked` | 已由 sentry 接管 | Managed by sentry |
| `sentry_proxy_overrides_proxy` | 反代劫持启用中，仅关闭后生效 | Reverse proxy active -- field inactive until disabled |
| `sentry_proxy_test` | 测试连通 | Test connectivity |
| `sentry_proxy_test_ok` | sentry Token 服务就绪 | sentry Token service ready |
| `sentry_proxy_test_fail` | sentry 连通失败 | sentry unreachable |

---

## 数据流

```
Flutter 生图请求 (sentryProxyEnabled = true)
  │
  ▼
POST http://localhost:7899/ai/generate-image
  Authorization: Bearer sentry-placeholder    ← Flutter 发的占位符
  Body: { ... 生图参数 ... }
  │
  ▼
nai-sentry Token 服务 (proxy/token_proxy.py)
  │  替换 Authorization → Bearer {最新的真实 PST}
  │  通过配置的 VPN 代理转发
  ▼
POST https://image.novelai.net/ai/generate-image
  Authorization: Bearer pst-abc123...         ← 真实 Token
```

---

## 使用前提

1. nai-sentry 已安装并配置好 `.env`（账号密码、代理等）
2. `.env` 中设置 `TOKEN_SERVICE_ENABLED=true`
3. 运行 `nai-sentry run`（Token 服务随守护模式自动启动）
4. Flutter 设置页开启「反代劫持」开关

---

## 已知限制

- Token 服务仅在 `nai-sentry run` 模式下启动，`deny` 和 `stress` 模式不启动
- Flutter 端未做自动重连/心跳，如果 sentry 服务中断，生图会直接失败
- 测试连通按钮只检查 `/token` 端点，不验证实际生图能力

---

## 项目技术栈速查

| 项 | 值 |
|----|-----|
| 框架 | Flutter (SDK >=3.3.4) |
| 包名 | nai_casrand |
| 状态管理 | ChangeNotifier + get_it (服务定位器) |
| DI | get_it |
| i18n | easy_localization (JSON) |
| HTTP | http package（支持可配超时） |
| 存储 | Hive + encrypt (Token 加密) |
| 架构 | data/models + data/services + ui/viewmodels + ui/widgets (MVVM) |

---

## 静态分析结果

`flutter analyze` 报告 0 个 error，6 个 info（全部是改动前已存在的 deprecated_member_use 和 unintended_html_in_doc_comment，不在本次修改的文件中）。
