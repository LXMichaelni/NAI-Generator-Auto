# 回归检查清单

## 通用检查

- 验证相关回调、任务、异步链路是否仍然正常。
- 检查状态流转、重试逻辑和幂等性是否被影响。
- 当行为随环境变化时，确认配置优先级和覆盖关系仍然正确。

## 代码审查修复后的回归检查（2026-04-17）

### DI 统一（GetIt）
- [ ] 确认所有页面正常加载，无 Provider 相关运行时错误
- [ ] 确认 SettingsPageViewmodel 的 dispose 被正确调用（切换页面后无内存泄漏）

### NavigationView IndexedStack
- [ ] 三个 tab 切换时页面状态保持（生成页进度、配置页编辑内容、设置页输入值）
- [ ] 首次进入每个 tab 时正常初始化

### ViewModel 无 BuildContext 构造
- [ ] GenerationPageView 正常启动和生图
- [ ] SettingsPageView 所有设置项可正常读写

### builder 无副作用
- [ ] GenerationPage 的 Command listener 正常触发（生图成功/失败回调）
- [ ] 不会出现重复请求或状态不一致

### PromptConfig.fromJson null 安全
- [ ] 导入缺少字段的旧版 JSON 配置不崩溃
- [ ] 默认值正确填充（type='str', comment='Unnamed config' 等）

### 配置导入 schema 校验
- [ ] 导入合法 JSON 正常加载
- [ ] 导入缺少 prompt_config 键的 JSON 显示错误提示而非崩溃
- [ ] 从剪贴板导入 PromptConfig 正常工作

### seed 运算符优先级
- [ ] 生图时 seed 值在 0~0xFFFFFFFF 范围内

### LogService path_provider
- [ ] Windows/Android/Web 各平台日志正常写入
- [ ] 不再依赖 Directory.current

### i18n
- [ ] 切换到英文后所有字符串显示英文（无中文残留）
- [ ] 切换到中文后所有字符串显示中文
- [ ] 新增的 requesting_progress、generation_error、unnamed_config 键正常显示

### CI/CD
- [ ] GitHub Actions android.yml 构建通过
- [ ] GitHub Actions web.yml 构建通过
