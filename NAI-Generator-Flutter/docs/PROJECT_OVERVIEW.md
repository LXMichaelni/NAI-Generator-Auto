# NAI Generator Flutter - 项目说明

更新时间：2026-02-03

## 1. 项目简介
- 包名：`nai_casrand`
- 版本：`0.9.2`
- 简述：一个基于 Flutter 的图像生成客户端，支持按提示词/配置批量生成。

## 2. 平台与运行环境
- Flutter SDK：`>=3.3.4 <4.0.0`
- 工程包含的平台目录：`android/ ios/ web/ windows/ macos/ linux/`
  - 说明：目录存在并不代表所有平台已完善测试。

## 3. 目录结构概览
- `lib/` 核心代码
  - `lib/ui/` 页面与视图模型
  - `lib/data/models/` 配置/数据模型
  - `lib/data/services/` 网络/文件/推送服务
  - `lib/data/use_cases/` 业务用例（生成 payload 等）
  - `lib/core/constants/` 常量与默认值
- `assets/` 资源与本地化
  - `assets/json/example.json` 默认配置
  - `assets/l10n/en.json` / `assets/l10n/zh-CN.json` 文案
- `docs/` 文档

## 4. 关键依赖（节选）
- `easy_localization`：多语言
- `get_it`：依赖注入
- `http` / `io_client`：网络请求
- `hive`：配置持久化
- `file_picker` / `path_provider`：文件选择与路径
- `image` / `archive`：图片与 zip 处理
- `flutter_command`：异步命令封装

## 5. 生图流程（核心逻辑）
1) 生成 payload（`GeneratePayloadUseCase`）
2) 发送请求（`ApiService.fetchData` → `https://image.novelai.net/ai/generate-image` 或 debug API）
3) 解析返回（`ImageService.processResponse` 解压 zip）
4) 可选处理：嵌入自定义 metadata
5) 生成文件名并保存到输出目录
6) 更新 UI 卡片（成功或错误）

错误处理要点：
- 401 会触发 Bark 推送（需启用开关+有效 token）
- 429 等其他错误无专门处理，仅显示错误卡片
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

## 8. 设置项概览（关键字段）
- API：`api_key`、`debug_api_path`、`debug_api_enabled`
- 网络：`proxy`
- 输出：`output_folder`（Windows）、`file_name_prefix_key`
- 生成：`batch_count`、`batch_interval`、`batch_interval_jitter`
        `batch_inner_interval`、`batch_inner_interval_jitter`
        `number_of_requests`
- 元数据：`metadata_erase_enabled`、`custom_metadata_enabled`、`custom_metadata_content`
- UI：`generation_page_column_count`、`theme_mode`
- Bark：`bark_token`、`bark_notify_auth_fail`、`bark_notify_auth_fail_cooldown`

## 9. Bark 推送
- 触发：API 返回 401（Unauthorized）
- 方式：`POST https://api.day.app/push`（JSON）
- 标题前缀：`[Nai] `
- 限频：默认 60 秒内只推送一次

## 10. 本地化
- 语言文件：`assets/l10n/en.json`、`assets/l10n/zh-CN.json`
- 使用 `easy_localization`

## 11. Windows 运行/打包
- 一键运行：`run_windows.bat`
- 一键打包：`build_windows.bat`
- 手动命令：
  - 运行：`flutter run -d windows`
  - 打包：`flutter build windows`

## 12. 近期改动
详见 `docs/CHANGES.md`。
