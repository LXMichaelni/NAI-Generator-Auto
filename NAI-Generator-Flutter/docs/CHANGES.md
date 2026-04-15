# 项目改动记录（由 Codex 生成）

日期：2026-02-03

## 本次改动概览
- 批次与批次内等待：新增随机偏差与批次内等待配置，并在生成流程中生效。
- Bark 推送：新增 Bark token 配置、401 认证失败推送与限频配置。
- UI 提示：批次冷却与批次内等待会弹出提示。
- 工具脚本：新增 Windows 一键运行与一键打包脚本。

## 详细改动
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

## 变更文件列表
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
