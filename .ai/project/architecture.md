# 架构说明

## 系统上下文

```
用户 → Flutter App (NavigationView + IndexedStack)
         ├── GenerationPage ──→ GeneratePayloadUseCase
         │                          ├── PromptConfig.getPrmpts() → 级联随机选词
         │                          ├── CharacterConfig.getPrompt() → 角色 prompt
         │                          └── ParamConfig.getPayload() → 参数组装
         │                      ↓
         │                  ApiService.fetchData()
         │                      ↓ POST (三级优先: sentry > debug > 直连)
         │                  NAI API (image.novelai.net)
         │                      ↓ ZIP response
         │                  ImageService.processResponse() → 解压
         │                  ImageService.embedMetadata() → 隐写 (可选)
         │                  FileService.savePictureToFile() → 保存
         │                      ↓
         │                  InfoCardContent → UI 卡片
         │
         ├── ConfigPage ──→ PromptConfig 树形编辑
         └── SettingsPage ──→ Settings / ParamConfig / ConfigService
```

## 依赖注入

- 全局统一使用 GetIt (Service Locator)，不混用 Provider
- 所有服务和共享状态通过 `GetIt.I()` 获取
- ViewModel 通过 `ChangeNotifierProvider` 创建，但内部依赖从 GetIt 获取

## 核心数据流

1. **Payload 生成** (`GeneratePayloadUseCase.call()`)
   - 读取 `PayloadConfig` 的所有子模型
   - `PromptConfig.getPrmpts()` 递归执行级联随机选取
   - 变量替换: `__变量名__` → 从 `savedPromptConfigList` 中查找匹配的 config
   - 组装 v4_prompt / characterPrompts / vibe 配置
   - 返回 `PayloadGenerationResult`（payload + comment + suggestedFileName）

2. **批次控制** (`GenerationPageViewmodel`)
   - `startBatch()` → `nextCommand()` → API 调用 → 成功后判断:
     - 达到总数限制 → `stopBatch()`
     - 达到批次数 → `setCooldown()` → Timer → `nextCommand()`
     - 未达到 → `setInnerDelay()` → Timer → `nextCommand()`
   - 失败时: payload 缓存重用（最多 3 次）

3. **配置持久化** (`ConfigService`)
   - Hive box 存储，UUID 管理多份配置
   - 导入/导出: JSON 文件（跨平台兼容）
   - 导入时做 schema 校验（检查 `prompt_config` 键），失败显示错误提示

## 关键设计决策

- **级联随机 Prompt**: 树形 `PromptConfig` 支持嵌套（`type: 'config'`），5 种选取策略
- **sealed class `NestedPrompt`**: `NestedPromptString`(叶子) / `NestedPromptList`(分支)，支持 DFS 查找
- **Command 模式**: 用 `flutter_command` 包装异步生图操作，支持执行状态监听
- **跨平台文件保存**: Web(blob download) / Windows(File) / Android(SaverGallery)
- **PNG 隐写**: stealth_pngcomp 格式，gzip 压缩后嵌入 alpha 通道最低位
- **Vibe v4**: 从 PNG iTXt chunk 或 .naiv4vibe JSON 文件提取编码
- **NavigationView**: 使用 IndexedStack 缓存页面状态，tab 切换不重建页面
- **ViewModel 分层**: 构造函数不接收 BuildContext，需要时通过方法参数传入
- **builder 无副作用**: builder 回调只做 UI 构建，副作用（网络请求、状态修改）放在 initState/listener 中
- **PromptConfig null 安全**: fromJson 所有字段有 `??` 默认值，不因缺失字段崩溃
- **seed 运算**: `(seed & 0xFFFFFFFF)` 加括号确保位运算优先级正确
