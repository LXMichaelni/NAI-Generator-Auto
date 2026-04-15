# 已知风险

## 安全风险

- **API Key 明文存储**: `settings.apiKey` 直接存入 Hive，未加密
- **SSL 验证关闭**: `badCertificateCallback` 在代理模式下始终返回 `true`
- **请求头伪装硬编码**: `getHeaders()` 中 referer 和 user-agent 硬编码，NAI 更新可能导致拒绝

## 架构风险

- **PromptConfig 有状态**: `_sequentialIdx` / `_sequentialRepeatIdx` 是实例内部状态，不随配置序列化，重启后重置为 0
- **重复定义**: `xMapping` 和 `doubleMapping` 在 `payload_config.dart` 和 `generate_payload_use_case.dart` 中各定义一次
- **无测试**: 仅有 `flutter_test` 依赖但无实际测试文件，覆盖率 0%

## 回归高危点

- **GeneratePayloadUseCase.call()**: 核心 payload 组装逻辑，涉及 prompt + character + vibe + param 多路合并
- **PromptConfig.getPrmpts()**: 级联随机选取的递归逻辑，selector 策略分支多
- **ImageService.embedMetadata()**: 隐写算法，位操作精确性要求高
- **VibeConfigV4.fromPngBytes()**: iTXt chunk 解析，格式假设固定
- **GenerationPageViewmodel.nextCommand()**: 批次状态机（active/cooling/innerDelay），Timer 竞态风险

## 平台兼容性

- **Web 平台**: 不支持代理（`kIsWeb` 时 `createHttpClient` 返回 null）
- **Android**: 需要存储权限（SDK < 29），SaverGallery API 可能随 Android 版本变化
- **iOS/macOS/Linux**: 目录存在但未充分测试
