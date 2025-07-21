# GitHub Actions 构建说明

本项目配置了多个GitHub Actions工作流来自动化构建和发布流程。

## 🔄 工作流概览

### 1. 主构建工作流 (`build-apk.yml`)

**触发条件**:
- 推送到 `main` 或 `master` 分支
- 推送标签 (如 `v1.5.0`)
- 手动触发

**功能**:
- 自动构建Release APK
- 创建GitHub Release (当推送标签时)
- 上传APK作为Artifacts
- 包含完整的发布说明

### 2. 手动构建工作流 (`manual-build.yml`)

**触发方式**:
- 在GitHub仓库页面点击 **Actions** → **Manual Build APK** → **Run workflow**

**选项**:
- `build_type`: 选择构建类型 (release/debug)
- `create_release`: 是否创建GitHub Release
- `release_notes`: 自定义发布说明

**特点**:
- 灵活的构建选项
- 详细的构建信息展示
- 可选择创建发布版本

### 3. PR构建检查 (`pr-build.yml`)

**触发条件**:
- Pull Request 创建、更新或重新开启

**功能**:
- 代码格式检查
- 静态分析
- 构建验证
- 自动评论PR状态
- 上传Debug APK供测试

## 📥 如何下载APK

### 方法一: Actions Artifacts
1. 进入项目的 **Actions** 页面
2. 选择对应的构建运行
3. 在页面底部的 **Artifacts** 部分下载

### 方法二: Releases页面
1. 进入项目的 **Releases** 页面
2. 选择对应版本
3. 下载附件中的APK文件

### 方法三: 手动触发构建
1. 进入 **Actions** → **Manual Build APK**
2. 点击 **Run workflow**
3. 选择构建选项并运行
4. 构建完成后在Artifacts中下载

## 🏷️ 版本发布流程

### 自动发布 (推荐)
1. 更新 `pubspec.yaml` 中的版本号
2. 提交代码到main分支
3. 创建并推送版本标签：
   ```bash
   git tag v1.5.0
   git push origin v1.5.0
   ```
4. GitHub Actions自动创建Release并上传APK

### 手动发布
1. 使用 **Manual Build APK** 工作流
2. 选择 `release` 构建类型
3. 勾选 `create_release`
4. 填写发布说明
5. 运行工作流

## 🔧 配置说明

### 环境要求
- **Java**: OpenJDK 17 (Zulu distribution)
- **Flutter**: 3.24.5 stable
- **Android**: 构建tools和SDK已预安装

### 构建参数
- **Release模式**: 优化的生产版本，体积更小
- **Debug模式**: 包含调试信息，便于测试

### 文件命名规则
- 自动构建: `TodoList-v{version}-{type}.apk`
- 手动构建: `TodoList-v{version}-{type}-{timestamp}.apk`

## 🚀 使用技巧

### 快速构建
如果只是想快速获得最新的APK：
1. 进入Actions页面
2. 运行 **Manual Build APK**
3. 使用默认设置 (release模式)
4. 等待构建完成并下载

### 测试版本
对于开发和测试：
1. 创建Pull Request
2. **PR Build Check** 会自动运行
3. 在PR页面下载Debug APK进行测试

### 正式发布
发布新版本时：
1. 确保所有测试通过
2. 更新版本号
3. 推送版本标签
4. GitHub自动创建正式发布

## 📊 构建统计

每次构建都会显示：
- APK文件大小
- 构建时间
- 版本信息
- 构建日志

## 🛠️ 故障排除

### 构建失败
1. 查看Actions运行日志
2. 检查Flutter和依赖版本
3. 验证代码语法和格式

### APK无法下载
1. 确认构建已完成
2. 检查Artifacts保留期限
3. 尝试重新运行构建

### 权限问题
1. 确认有仓库写权限
2. 检查GITHUB_TOKEN设置
3. 验证分支保护规则

---

🤖 **说明**: 所有构建都在GitHub提供的云端环境中进行，无需本地配置开发环境。
