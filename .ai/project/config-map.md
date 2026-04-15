# 配置映射

## 运行时配置

所有配置集中在 `PayloadConfig` 对象中，通过 GetIt 全局单例注入。

### API 与网络

- `settings.apiKey` — NAI API Token（Bearer auth）
- `settings.proxy` — HTTP 代理地址（可选，用于 IOClient）
- `settings.debugApiPath` — 调试 API 地址（默认 `http://localhost:5000/ai/generate-image`）
- `settings.debugApiEnabled` — 是否使用调试 API
- 生产 API 端点: `https://image.novelai.net/ai/generate-image`

### 生成参数 (ParamConfig)

- `model` — 模型名（默认 `nai-diffusion-4-curated-preview`）
- `sizes` — 生成尺寸列表（随机选一个，默认 832×1216）
- `steps` — 采样步数（默认 28）
- `sampler` — 采样器（默认 `k_euler_ancestral`）
- `noiseSchedule` — 噪声调度（默认 `native`）
- `scale` — CFG Scale（默认 6.5）
- `cfgRescale` — CFG Rescale（默认 0.1）
- `seed` / `randomSeed` — 种子控制
- `negativePrompt` — 反向提示词
- `sm` / `smDyn` — SMEA / SMEA+DYN（仅 v3 模型）
- `varietyPlus` — Variety+ 模式

### 批次控制 (Settings)

- `batchCount` — 每批次请求数（默认 10）
- `batchIntervalSec` — 批次间冷却秒数（默认 10）
- `batchIntervalJitterSec` — 冷却随机偏差（默认 0）
- `batchInnerIntervalSec` — 批次内请求间隔（默认 0）
- `batchInnerIntervalJitterSec` — 请求间隔随机偏差（默认 0）
- `numberOfRequests` — 总请求数（0 = 无限）

### 输出与 UI

- `outputFolderPath` — 输出目录（Windows，默认 Documents/nai-generated）
- `generationPageColumnCount` — 生成页列数（默认 2）
- `generationPageMaxItems` — 最大卡片数（默认 200）
- `themeMode` — 主题模式（system/light/dark）
- `fileNamePrefixKey` — 文件名前缀规则（支持 `__变量名__` 替换）

### Metadata 处理

- `metadataEraseEnabled` — 是否擦除/替换元数据
- `customMetadataEnabled` — 是否注入自定义元数据
- `customMetadataContent` — 自定义元数据内容（stealth_pngcomp 隐写格式）

### Bark 推送

- `barkToken` — Bark 设备 Key
- `barkNotifyAuthFailEnabled` — 401 时是否推送
- `barkNotifyAuthFailCooldownSec` — 推送冷却秒数（默认 60）
- 推送端点: `https://api.day.app/push`

## 敏感信息约束

- `apiKey` 为 NAI API Token，禁止写入记忆文件
- `barkToken` 为推送令牌，禁止写入记忆文件

## 数据文件位置

- 默认配置: `assets/json/example.json`
- 本地化文件: `assets/l10n/en.json`, `assets/l10n/zh-CN.json`
- Hive 存储: 应用数据目录（`getApplicationDocumentsDirectory()`）
- 配置索引: Hive box `savedBox` 中的 `configIndex` (JSON)
- 单份配置: Hive box `savedBox` 中的 `savedConfig-{uuid}` (JSON)
