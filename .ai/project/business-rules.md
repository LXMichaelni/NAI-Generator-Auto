# 业务规则

## Prompt 选取规则

- **single**: 随机选一个
- **single_sequential**: 顺序遍历，到末尾回到开头（有内部计数器 `_sequentialIdx`）
- **all**: 选取全部
- **multiple_num**: 随机选 N 个（先 shuffle 再 take）
- **multiple_prob**: 每项按概率 P 独立抽取
- **shuffled**: `multiple_prob` 和 `all` 模式下是否打乱顺序

## 变量替换

- 语法: `__变量名__`（Unicode 兼容）
- 匹配: 从 `savedPromptConfigList` 中查找 `comment == 变量名` 的 config
- 未匹配: 保持原样 `__变量名__`
- 递归: 变量替换在 `NestedPrompt` 层面递归执行

## 随机括号（权重调节）

- `randomBracketsUpper` / `randomBracketsLower` 定义范围
- 正值 → 添加 `{}` 提升权重（NAI 语法）
- 负值 → 添加 `[]` 降低权重

## 分隔符 `|||`

- 字符串中含 `|||` 时，前部分添加到 prompt 开头，后部分添加到末尾
- 用于在已有 prompt 中间插入内容

## 批次控制

- 每批次 `batchCount` 个请求后进入冷却
- 冷却时间 = `batchIntervalSec` ± `batchIntervalJitterSec`（随机偏差）
- 批次内请求间隔 = `batchInnerIntervalSec` ± `batchInnerIntervalJitterSec`
- 总请求数 `numberOfRequests`（0 = 无限）
- payload 生成失败时缓存重用最多 3 次

## API 交互

- 端点: `POST https://image.novelai.net/ai/generate-image`
- 认证: `Bearer {apiKey}`
- 请求头伪装: Firefox UA + novelai.net referer
- 响应: ZIP 压缩包，内含 `image_0.png`
- 401 → 触发 Bark 推送（冷却 60 秒内不重复）
- 429 → 记录日志（速率限制）

## 模型分支

- 模型名含 `-3` → NAI v3 Vibe Transfer（imageB64 + referenceStrength + infoExtracted）
- 模型名含 `-4-` → NAI v4 Vibe Transfer（vibeB64 + 离散 informationExtracted）
- 模型含 `diffusion-4` → 移除 sm/smDyn 参数，noise_schedule native→karras

## Metadata 隐写

- 格式: stealth_pngcomp（magic bytes + gzip 压缩 + alpha 通道最低位）
- 可选功能: 擦除原始 metadata / 注入自定义 metadata
- 提取: 从 alpha 通道反向读取并 gzip 解压
