# 项目概览

## 项目目标

**NAI CasRand (NAI Cascaded Random Generator) v0.9.2**

NovelAI API 的第三方图像生成客户端，核心目标：
- 按照级联随机规则组合提示词（prompt），生成大量不同风格/角色/场景的图片
- 批量自动调用 NAI API 生图，支持精细的批次控制（interval + jitter）
- 支持多角色定位、Vibe Transfer（v3/v4）、Director Tools 等高级功能
- 跨平台运行（Web、Windows、Android）

## 技术栈

- **框架**: Flutter (Dart), SDK >=3.3.4 <4.0.0
- **架构**: MVVM (ViewModel + ChangeNotifier/Command) + Service Layer + Use Case
- **DI**: GetIt (Service Locator)，全局统一，不混用 Provider
- **持久化**: Hive (本地 KV 存储，UUID 管理多份配置)
- **网络**: http 包 + IOClient（支持代理）
- **国际化**: easy_localization (en, zh-CN)
- **图片处理**: image 包 + archive 包（ZIP 解压）
- **异步命令**: flutter_command
- **日志**: LogService（使用 path_provider 获取平台安全路径）

## 入口与启动方式

- 主入口: `NAI-Generator-Flutter/lib/main.dart`
- Windows 运行: `flutter run -d windows` 或 `run_windows.bat`
- Windows 打包: `flutter build windows` 或 `build_windows.bat`
- Web 运行: `flutter run -d chrome`

## 架构概要

项目结构 `NAI-Generator-Flutter/lib/`：
- `core/constants/` — 常量与默认值
- `data/models/` — 数据模型（PayloadConfig, PromptConfig, ParamConfig, Settings 等）
- `data/services/` — 服务层（API, Config, File, Image, Bark, Log）
- `data/use_cases/` — 业务用例（GeneratePayloadUseCase）
- `ui/` — 视图层（MVVM，每个功能模块有 view_models/ 和 widgets/）

三主页面：Generation（生图）、Config（Prompt 配置）、Settings（参数设置）

## 架构约束（已落地）

- ViewModel 构造函数不接收 BuildContext，通过方法参数传入
- builder 回调中不执行副作用（网络请求、状态修改），副作用放在生命周期方法中
- NavigationView 使用 IndexedStack 缓存页面状态，避免 tab 切换时重建
- 配置导入时对 JSON 做 schema 校验（检查 `prompt_config` 键存在性），失败时显示错误提示
- PromptConfig.fromJson 所有字段有 `??` 默认值兜底，不会因缺失字段崩溃
- i18n 覆盖所有用户可见字符串，不硬编码英文
