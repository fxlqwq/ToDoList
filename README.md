# ToDoList-Flutter

一个功能完整的Flutter待办事项应用，支持智能通知提醒、数据备份和项目组管理。

## 📱 项目简介

这是一个现代化的Flutter待办事项管理应用，采用Material Design设计语言，提供直观的用户界面和强大的功能。应用支持任务分类、优先级管理、智能通知提醒、ZIP格式数据备份、项目组统计等功能，帮助用户高效管理日常任务。

## 🔧 构建方式

### 环境要求
- Flutter SDK 3.5.4+
- Dart SDK ^3.5.4
- Android SDK (API 21+)
- Java 11+

### 快速开始

1. **克隆项目**
```bash
git clone https://github.com/fxlqwq/ToDoList.git
cd ToDoList
```

2. **安装依赖**
```bash
flutter pub get
```

3. **运行调试版本**
```bash
flutter run
```

### 发布构建

#### 准备签名密钥（首次）
```bash
# 创建 keystore 目录
mkdir -p android/keystore

# 生成发布密钥（请妥善保管密码！）
keytool -genkey -v -keystore android/keystore/release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias release

# 创建密钥配置文件
cat > android/key.properties << EOF
storePassword=你的密钥库密码
keyPassword=你的密钥密码
keyAlias=release
storeFile=keystore/release-key.jks
EOF
```

#### 构建发布版本
```bash
# 构建 APK
flutter build apk --release

# 构建 App Bundle（推荐用于 Google Play）
flutter build appbundle --release

# 构建安装包位置
# APK: build/app/outputs/flutter-apk/app-release.apk
# Bundle: build/app/outputs/bundle/release/app-release.aab
```

#### 自动化构建脚本
项目提供了自动化构建脚本 `build-release.sh`：
```bash
chmod +x build-release.sh
./build-release.sh
```

### 版本管理

更新版本号前修改 `pubspec.yaml`：
```yaml
version: 1.8.7  # 格式：主版本.次版本.修订版本
```

### 签名注意事项

⚠️ **重要**：为了确保应用能够正常更新而不需要卸载重装：

1. **密钥一致性**：在所有构建环境中使用相同的 `release-key.jks` 文件
2. **密钥备份**：务必备份 `android/keystore/` 目录和密码
3. **团队协作**：团队成员需要共享相同的签名密钥
4. **版本递增**：每次发布都要递增版本号

### 项目结构
```
ToDoList/
├── lib/
│   ├── models/          # 数据模型
│   ├── screens/         # 页面组件
│   ├── services/        # 业务逻辑服务
│   ├── utils/           # 工具类
│   └── widgets/         # 自定义组件
├── android/
│   ├── keystore/        # 签名密钥（需要创建）
│   └── key.properties   # 密钥配置（需要创建）
└── assets/              # 静态资源
```

## 界面预览
<img width="640" height="360" alt="MuMu-20250722-130311-643" src="https://github.com/user-attachments/assets/8f7c79e1-a3a6-4e80-84c0-2b21b28286a4" />

## 🌟 v1.8.7 最新更新

### 🔧 数据备份系统优化
- � **ZIP备份修复**：彻底解决ZIP格式备份导入时的编码问题，使用UTF-8确保数据完整性
- 🔄 **导入兼容性**：支持同时导入ZIP和JSON格式的备份文件，向后兼容旧格式
- � **备份页面修复**：修复备份文件列表页面的类型转换错误，显示正常
- � **详细日志**：添加详细的导入过程日志，便于调试和问题排查
- ✅ **签名配置**：完善发布签名配置，确保应用更新的连续性

### 📊 统计功能增强
- � **项目组统计**：新增项目组统计页面，支持分项目查看详细数据
- � **统计导航**：在总体统计页面可以点击项目组查看单独统计
- 📋 **数据完整性**：统计页面显示项目组完成率、任务分布等详细信息

### 🛠️ 技术改进
- � **签名一致性**：配置统一的发布签名，避免不同设备构建时出现签名冲突
- � **构建文档**：完善README构建说明，包含详细的环境配置和发布流程
- � **编码标准化**：统一使用UTF-8编码处理所有文本数据，避免字符集问题
- 📐 **智能宽高比调整**：根据任务内容（子任务数量、描述长度）自适应调整卡片尺寸
- 👆 **子任务交互改进**：增大子任务复选框点击区域，从8-10px增至10-12px，提升操作体验
- 💾 **视图模式持久化**：记住用户偏好的视图模式设置，重启应用后自动恢复
- ✅ **完成状态统一**：卡片视图和紧凑视图现在也支持点击完成状态图标快速切换任务状态

### 🛠️ 技术改进
- 📊 **宽高比算法重构**：基础比例调整至1.2-1.5，根据内容动态调整0.8-1.1倍数
- 🎯 **响应式布局优化**：针对不同屏幕尺寸(小于400px、600px、800px)精细化调整
- 🔄 **数据同步增强**：修复子任务状态切换的调试日志和错误处理机制
- ⚡ **性能优化**：减少不必要的重绘，提升滑动和交互流畅度

### 📋 用户体验提升
- 🎨 **视觉一致性**：统一所有视图模式的任务完成状态切换交互
- 📱 **移动端适配**：优化小屏设备上的点击区域和视觉效果
- 🔍 **内容展示优化**：网格卡片更好地平衡内容展示与空间利用
- 💡 **操作反馈改进**：更清晰的任务状态变更视觉反馈

## 🌟 v1.8.0 重大更新

### ✨ 全新功能
- 📊 **统计功能**：详细的任务完成数据分析，包含总体概览、分类统计、优先级统计、时间统计和子任务统计
- 🎨 **多种视图模式**：支持列表、卡片、网格、紧凑四种显示方式，满足不同使用场景
- 📋 **卡片视图**：信息丰富的卡片布局，显示任务详情、子任务进度和状态指示
- 🗂️ **网格视图**：紧凑的网格布局，适合快速浏览大量任务
- 📄 **紧凑视图**：最简模式，节省屏幕空间，适合小屏设备

### 🛠️ 技术改进
- 🏗️ **视图架构优化**：模块化的视图组件，支持灵活切换
- 📊 **统计算法增强**：深度分析任务数据，提供多维度统计信息
- 🎯 **交互体验升级**：卡片视图支持点击编辑、长按删除
- 🔄 **状态管理完善**：统一的视图模式管理和数据同步

### 📋 功能特性
- 📈 **数据统计**：任务完成率、分类分布、优先级分析、时间统计
- 🎨 **视图切换**：右上角视图按钮，快速切换显示模式
- 📊 **可视化图表**：圆形进度图、线性进度条、统计卡片
- 🎯 **智能分析**：自动计算逾期任务、今日任务、子任务完成度

## 🌟 v1.7.2 功能更新

### ✨ 全新功能
- 🔄 **子任务拖拽排序**：支持通过拖拽手柄重新排列子任务顺序
- ✏️ **增强子任务编辑**：改进编辑体验，支持点击直接编辑子任务内容
- 🗑️ **子任务删除功能**：为每个子任务添加独立的删除按钮
- 🎯 **可重排序列表**：使用Flutter ReorderableListView实现流畅的拖拽体验

### 🛠️ 重要修复
- 💾 **子任务状态同步优化**：修复主界面子任务完成状态无法正确同步到数据库的问题
- 🔄 **直接数据库更新**：子任务状态变更现在直接更新数据库，无需通过完整任务更新
- ⚡ **性能优化**：减少不必要的数据库操作，提升子任务操作响应速度
- 🎨 **UI交互改进**：优化子任务编辑和删除的用户体验

### 🔧 技术改进
- 🏗️ **可重排序组件**：新增ReorderableSubtaskList组件支持拖拽排序
- 📊 **状态管理优化**：改进子任务的编辑状态管理和数据同步机制
- 🔄 **数据库优化**：优化子任务order字段的更新逻辑
- 🎯 **回调函数增强**：为TodoCard添加更多子任务操作回调函数

## 🌟 v1.7.1 功能更新

### ✨ 全新功能
- ✏️ **子任务编辑功能**：点击子任务可直接编辑内容，支持实时保存和取消
- 🎯 **灵活编辑体验**：子任务编辑采用内联方式，无需跳转到新页面
- 📝 **快速文本编辑**：支持Enter键保存、ESC键取消，符合用户操作习惯
- 🔧 **编辑状态管理**：编辑模式下显示保存/取消按钮，清晰的操作指引

### 🛠️ 技术改进
- 🏗️ **组件重构优化**：SubtaskWidget转换为StatefulWidget，支持编辑状态管理
- 📊 **状态同步机制**：编辑内容实时同步到数据库，确保数据一致性
- 🎨 **UI/UX优化**：编辑模式下自动聚焦输入框，提升用户体验
- 🔄 **版本管理完善**：统一更新所有文件版本号到1.7.1

## 🌟 v1.7.0 功能更新

### ✨ 全新功能
- 📋 **长按复制任务**：长按任务卡片即可快速复制任务，包括所有子任务和附件
- 🎯 **智能复制逻辑**：复制时自动重置ID、添加"(副本)"标识、重置完成状态和提醒设置
- 📝 **Markdown实时预览修复**：修复编辑模式下Markdown预览无法显示当前输入内容的问题
- 🔧 **滑动删除优化**：修复向左滑动删除时出现双重确认框的bug，现在只显示一个确认框

### 🛠️ 重要修复
- 💾 **数据库约束修复**：解决复制任务时主键约束失败导致的错误
- 🎨 **用户体验改进**：复制任务后显示清晰的成功反馈，包含复制任务的标题
- 🔄 **预览同步优化**：Markdown预览现在能实时显示用户正在输入的内容
- 🎯 **交互逻辑统一**：删除操作统一由主屏幕处理确认框，避免重复弹窗

### 🔧 技术改进
- 🏗️ **复制算法重构**：使用直接实例化而非copyWith方法，确保ID正确重置
- 📊 **错误处理增强**：添加详细的复制失败日志和用户提示
- 🎨 **代码质量提升**：清理未使用的方法，优化组件交互逻辑
- 🔄 **实时更新机制**：优化Markdown预览的状态同步机制

## 🌟 v1.6.0 功能更新

### 🛠️ 重要修复
- 🔧 **任务创建修复**：修复了创建新任务时子任务和附件无法保存的关键问题
- 💾 **数据持久化优化**：重构TodoProvider.addTodo方法，现在返回完整任务对象确保ID正确传递
- 🎯 **保存逻辑改进**：优化任务保存流程，子任务和附件现在能正确关联到新创建的任务

### ✨ 新增功能
- 📋 **批量添加子任务**：支持粘贴多行文本，每行自动创建一个子任务
- 🎯 **智能文本解析**：自动忽略空行，支持任意长度文本（超长自动截断）
- 💡 **用户友好界面**：批量添加对话框包含清晰操作说明和示例
- ⚡ **一键添加**：例如粘贴"更新ubuntu\n重装windows"可快速创建两个子任务

### 🔧 技术改进
- 🏗️ **错误处理增强**：添加详细错误消息和用户反馈机制
- 📊 **数据流优化**：移除不可靠的任务查找逻辑，直接使用返回的任务对象
- 🎨 **代码质量提升**：修复编译警告，遵循Flutter最佳实践
- 🔄 **向后兼容**：保持现有编辑功能完整性，不破坏任何现有功能

## 🌟 v1.5.9 功能更新

### 🔧 启动逻辑优化
- 🎯 **首次启动逻辑**：修复首次启动画面显示异常问题，统一使用PreferencesService管理启动状态
- 🎯 **交互式子任务完成**：在主界面直接点击子任务圆圈即可切换完成状态，无需进入编辑页面
- 🔧 **状态管理优化**：扩展TodoProvider添加toggleSubtaskCompletion方法，支持子任务状态实时同步
- 🎨 **界面响应优化**：修复编译错误，更新已弃用的API，提升应用稳定性

## 🌟 v1.5.8 重大功能更新 ### ✨ 新增核心功能
- 📋 **子任务系统**：每个任务支持多个子任务，带完成进度跟踪
- 📎 **附件功能**：支持图片、音频录制和文本笔记附件
- 📝 **Markdown支持**：任务描述支持Markdown格式，预览/编辑模式切换
- 🎯 **完整中文化**：所有界面元素全面中文本地化

### 📊 增强功能
- 🔄 **进度可视化**：子任务完成进度条显示
- 🎨 **富文本编辑**：Markdown快捷工具栏（粗体、斜体、标题、列表等）
- 📱 **多媒体支持**：集成相机拍照、相册选择、音频录制功能
- 💾 **数据库升级**：SQLite架构升级至版本2，支持新功能表结构

### ✨ 新增核心功能
- 📋 **子任务系统**：每个任务支持多个子任务，带完成进度跟踪
- 📎 **附件功能**：支持图片、音频录制和文本笔记附件
- 📝 **Markdown支持**：任务描述支持Markdown格式，预览/编辑模式切换
- 🎯 **完整中文化**：所有界面元素全面中文本地化

### 📊 增强功能
- 🔄 **进度可视化**：子任务完成进度条显示
- 🎨 **富文本编辑**：Markdown快捷工具栏（粗体、斜体、标题、列表等）
- 📱 **多媒体支持**：集成相机拍照、相册选择、音频录制功能
- � **数据库升级**：SQLite架构升级至版本2，支持新功能表结构

### �🔧 技术改进
- 🏗️ **新增数据模型**：Subtask和Attachment模型完整实现
- 🛠️ **服务层扩展**：AttachmentService处理文件操作和多媒体功能
- 🎛️ **UI组件丰富**：新增SubtaskWidget、AttachmentWidget、MarkdownWidget
- 📱 **Android兼容性**：更新到compileSdk 35，minSdk 24以支持flutter_sound

### 🎨 用户体验增强
- ✅ **任务展开视图**：点击任务卡片查看完整子任务和附件列表
- 🎵 **音频播放控制**：内置音频播放器，支持播放/暂停控制
- 🖼️ **图片预览**：点击图片附件可全屏预览
- 📝 **文本笔记对话框**：快速创建和查看文本笔记
- 🎯 **主界面子任务交互**：直接在任务卡片上完成子任务切换

## ✨ 功能特性

### 📝 任务管理
- **任务创建和编辑**：快速创建任务，支持标题、描述、截止日期等信息
- **智能分类系统**：支持6种预设分类（个人、工作、健康、购物、学习、其他）
- **优先级设置**：三级优先级系统（高、中、低）
- **任务状态管理**：完成、删除、编辑任务状态
- **子任务功能**：每个任务支持创建多个子任务，独立完成状态管理
- **批量子任务添加**：支持粘贴多行文本快速创建多个子任务
- **进度跟踪**：实时显示子任务完成进度百分比
- **附件支持**：为任务添加图片、音频录制、文本笔记等附件
- **Markdown描述**：任务描述支持Markdown格式，提供富文本编辑体验
- **主界面交互**：直接在主界面点击子任务圆圈完成状态切换
- **数据完整性**：创建和编辑任务时子任务、附件正确保存

### 🔔 智能通知系统
- **精准时间提醒**：支持精确到分钟的提醒设置
- **后台通知保障**：即使应用关闭也能准时提醒
- **电池优化管理**：自动请求电池优化白名单权限
- **多重调度策略**：使用三种备用通知调度方案确保可靠性
- **系统级权限申请**：自动弹出系统权限对话框
- **锁屏通知显示**：支持在锁屏界面显示提醒
- **自定义通知样式**：使用应用图标和个性化消息

### 🚀 首次使用体验
- **使用指南**：首次启动时显示5步使用教程
- **智能权限申请**：一次性申请所有必要权限
- **偏好设置管理**：记住用户选择，避免重复提示
- **平滑引导流程**：从使用指南到权限申请的无缝体验

### 🎨 用户界面
- **现代化设计**：Material Design 3.0设计语言
- **渐变按钮**：美观的添加任务按钮，支持动画效果
- **响应式布局**：适配不同屏幕尺寸
- **主题系统**：统一的颜色主题和样式
- **流畅动画**：丰富的交互动画效果
- **菜单增强**：支持重新查看使用指南和应用信息

### 📊 数据管理
- **本地数据库**：使用SQLite进行数据持久化
- **实时数据同步**：基于Provider的状态管理
- **数据安全性**：完善的错误处理和数据验证
- **偏好设置存储**：使用SharedPreferences管理用户偏好
- **任务统计**：查看任务完成情况和统计信息

### 🔍 分类和筛选
- **分类筛选**：按类别快速筛选任务
- **优先级筛选**：按优先级查看重要任务
- **状态筛选**：查看完成/未完成任务
- **搜索功能**：快速找到特定任务
- **实时筛选**：清除筛选按钮快速重置所有筛选条件

## 🛠️ 技术栈

### 前端框架
- **Flutter 3.24.5**：跨平台移动应用开发框架
- **Dart**：编程语言

### 状态管理
- **Provider 6.x**：轻量级状态管理解决方案
- **ChangeNotifier**：数据变更通知机制

### 数据存储
- **SQLite**：本地关系型数据库
- **sqflite 2.4.1**：Flutter SQLite插件
- **SharedPreferences**：用户偏好设置存储
- **shared_preferences 2.2.2**：偏好设置插件

### 通知系统
- **flutter_local_notifications 17.2.4**：本地通知插件
- **timezone 0.9.4**：时区处理

### 权限管理
- **permission_handler 11.3.1**：权限请求和管理
- **电池优化权限**：Android原生权限处理
- **通知权限**：系统级权限申请

### UI组件
- **Material Design**：Google Material设计组件
- **font_awesome_flutter**：Font Awesome图标库
- **flutter_staggered_animations**：流畅的交错动画
- **flutter_markdown**：Markdown渲染和编辑支持
- **Intl**：国际化支持

### 多媒体功能
- **flutter_sound 9.11.2**：音频录制和播放
- **image_picker 1.1.2**：相机拍照和相册选择
- **file_picker 8.1.2**：文件选择和管理
- **path_provider 2.1.4**：文件路径管理
- **uuid 4.5.1**：唯一标识符生成

### 开发工具
- **ProGuard**：Release版本代码混淆
- **Gradle**：Android构建系统

## 📦 项目结构

```
lib/
├── main.dart                 # 应用入口，全局错误处理
├── models/
│   ├── todo.dart            # 任务数据模型，包含验证逻辑
│   ├── subtask.dart         # 子任务数据模型
│   └── attachment.dart      # 附件数据模型
├── screens/
│   ├── splash_screen.dart       # 启动画面
│   ├── home_screen.dart         # 主页面，任务列表展示
│   ├── add_edit_todo_screen.dart # 添加/编辑任务页面
│   ├── notification_settings_screen.dart # 通知设置页面
│   └── preferences_test_screen.dart # 偏好设置调试页面（仅调试模式）
├── services/
│   ├── database_service.dart    # 数据库服务，SQLite操作
│   ├── notification_service.dart # 通知服务，包含错误处理
│   ├── notification_helper.dart  # 通知辅助类
│   ├── battery_optimization_service.dart # 电池优化权限管理
│   ├── preferences_service.dart # 偏好设置服务
│   ├── attachment_service.dart  # 附件服务，文件和多媒体操作
│   └── todo_provider.dart       # 任务数据提供者，状态管理
├── utils/
│   └── app_theme.dart          # 应用主题配置
└── widgets/
    ├── todo_card.dart           # 任务卡片组件
    ├── category_filter_chip.dart # 分类筛选组件
    ├── priority_filter_chip.dart # 优先级筛选组件
    ├── stats_card.dart          # 统计卡片组件
    ├── notification_permission_dialog.dart # 权限请求对话框
    ├── usage_guide_dialog.dart  # 使用指南对话框
    ├── subtask_widget.dart      # 子任务组件
    ├── attachment_widget.dart   # 附件显示和管理组件
    └── markdown_widget.dart     # Markdown编辑和预览组件

android/
├── app/
│   ├── src/main/
│   │   ├── kotlin/com/fxl/todo_list_app/
│   │   │   └── MainActivity.kt      # Android原生代码，电池优化权限处理
│   │   ├── res/
│   │   │   ├── mipmap-*/ic_launcher.png # 应用图标（各分辨率）
│   │   │   └── drawable/
│   │   │       └── ic_notification.xml   # 通知图标
│   │   └── AndroidManifest.xml          # Android权限配置
│   ├── build.gradle                     # 应用级构建配置
│   └── proguard-rules.pro              # ProGuard混淆规则
└── build.gradle                        # 项目级构建配置
```

## 🚀 快速开始

### 环境要求

- Flutter SDK 3.24.5 或更高版本
- Dart SDK 3.0 或更高版本
- Android Studio 或 VS Code
- Android SDK (用于Android开发)
- JDK 8 或更高版本

### 安装步骤

1. **克隆项目**
   ```bash
   git clone https://github.com/fxlqwq/ToDoList-Notice-Flutter.git
   cd ToDoList-Notice-Flutter
   ```

2. **安装依赖**
   ```bash
   flutter pub get
   ```

3. **检查环境**
   ```bash
   flutter doctor
   ```

4. **运行应用**
   
   **Debug模式**：
   ```bash
   flutter run
   ```
   
   **Release模式**：
   ```bash
   flutter run --release
   ```

### 构建发布版本

**构建APK**：
```bash
flutter build apk --release
```

**构建AAB (推荐用于Google Play)**：
```bash
flutter build appbundle --release
```

## ⚙️ 配置说明

### Android权限配置

应用需要以下权限（已在 `AndroidManifest.xml` 中配置）：

```xml
<!-- 通知权限 -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<!-- 精确闹钟权限 -->
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
<uses-permission android:name="android.permission.USE_EXACT_ALARM" />
<!-- 电池优化相关权限 -->
<uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<!-- 后台运行权限 -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />
<!-- 设备启动完成权限 -->
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
<!-- 振动权限 -->
<uses-permission android:name="android.permission.VIBRATE" />
<!-- 网络状态权限 -->
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

### ProGuard配置

为确保Release版本正常运行，项目已配置ProGuard规则：

```proguard
# 保护Flutter本地通知插件
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.dexterous.flutterlocalnotifications.models.** { *; }

# 保护泛型信息
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod
```

## 🔧 核心功能实现

### 🚀 首次启动流程
1. **使用指南展示**：5步交互式教程介绍应用功能
2. **权限智能申请**：自动请求通知、精确闹钟和电池优化权限
3. **系统对话框**：弹出原生Android电池优化权限对话框
4. **偏好记录**：使用SharedPreferences记录用户选择

### 🔔 通知系统设计

#### 权限管理策略
- **BatteryOptimizationService**：专门处理电池优化权限
- **Android原生集成**：通过MainActivity.kt处理系统级权限
- **多重权限申请**：通知权限 + 精确闹钟权限 + 电池优化权限

#### 调度策略
1. **主要方法**：`AndroidScheduleMode.exactAllowWhileIdle` - 允许在设备休眠时唤醒
2. **备用方法**：`AndroidScheduleMode.alarmClock` - 闹钟级别的高优先级调度  
3. **最终备用**：`AndroidScheduleMode.exact` - 普通精确调度

#### 通知增强功能
- **锁屏显示**：支持在锁屏界面显示通知
- **全屏意图**：重要通知可全屏显示
- **声音振动**：自定义通知声音和振动模式
- **图标样式**：使用应用图标和自定义样式

### 💾 数据管理架构

#### 数据库设计
```sql
-- 主任务表
CREATE TABLE todos (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  description TEXT,
  category TEXT NOT NULL,
  priority TEXT NOT NULL,
  due_date TEXT,
  reminder_date TEXT,
  is_completed INTEGER DEFAULT 0,
  use_markdown INTEGER DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

-- 子任务表 (v2.0新增)
CREATE TABLE subtasks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  todo_id INTEGER NOT NULL,
  title TEXT NOT NULL,
  is_completed INTEGER DEFAULT 0,
  order_index INTEGER NOT NULL,
  created_at TEXT NOT NULL,
  FOREIGN KEY (todo_id) REFERENCES todos (id) ON DELETE CASCADE
);

-- 附件表 (v2.0新增)  
CREATE TABLE attachments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  todo_id INTEGER NOT NULL,
  file_name TEXT NOT NULL,
  file_path TEXT NOT NULL,
  file_size INTEGER,
  attachment_type TEXT NOT NULL,
  text_content TEXT,
  created_at TEXT NOT NULL,
  FOREIGN KEY (todo_id) REFERENCES todos (id) ON DELETE CASCADE
);
```

#### 偏好设置管理
- `first_launch`：是否首次启动
- `notification_permission_asked`：是否已请求通知权限
- `usage_guide_shown`：是否已显示使用指南
- `notification_enabled`：通知是否已启用
- `last_used_date`：最后使用日期

### 🎯 状态管理架构
- **Provider模式**：全局状态管理
- **ChangeNotifier**：数据变更通知机制
- **异步处理**：完善的异步操作错误处理
- **数据同步**：实时数据持久化

## 🌟 v1.5.5 重大更新

### ✨ 新增核心功能
- 📋 **子任务系统**：每个任务支持多个子任务，带完成进度跟踪
- � **附件功能**：支持图片、音频录制和文本笔记附件
- � **Markdown支持**：任务描述支持Markdown格式，预览/编辑模式切换
- 🎯 **完整中文化**：所有界面元素全面中文本地化

### 📊 增强功能
- � **进度可视化**：子任务完成进度条显示
- 🎨 **富文本编辑**：Markdown快捷工具栏（粗体、斜体、标题、列表等）
- 📱 **多媒体支持**：集成相机拍照、相册选择、音频录制功能
- 💾 **数据库升级**：SQLite架构升级至版本2，支持新功能表结构

### � 技术改进
- �️ **新增数据模型**：Subtask和Attachment模型完整实现
- �️ **服务层扩展**：AttachmentService处理文件操作和多媒体功能
- 🎛️ **UI组件丰富**：新增SubtaskWidget、AttachmentWidget、MarkdownWidget
- � **Android兼容性**：更新到compileSdk 35，minSdk 24以支持flutter_sound

### 🎨 用户体验增强
- ✅ **任务展开视图**：点击任务卡片查看完整子任务和附件列表
- 🎵 **音频播放控制**：内置音频播放器，支持播放/暂停控制
- �️ **图片预览**：点击图片附件可全屏预览
- � **文本笔记对话框**：快速创建和查看文本笔记

## 🔧 核心功能实现（历史版本）

### 通知系统设计（v1.4.x）

1. **时区处理**：使用 `timezone` 包处理不同时区的时间转换
2. **权限管理**：动态请求通知和精确闹钟权限
3. **错误恢复**：多层错误捕获和恢复机制
4. **调度模式**：支持 `exactAllowWhileIdle` 和 `alarmClock` 两种调度模式

### 数据库设计

- 使用Provider进行状态管理
- ChangeNotifier实现数据变更通知
- 异步操作错误处理
- 数据持久化同步

## 🐛 故障排除

### ❌ 通知不工作

#### 权限相关
1. **检查通知权限**：确保已授予POST_NOTIFICATIONS权限
2. **精确闹钟权限**：Android 12+需要SCHEDULE_EXACT_ALARM权限
3. **电池优化**：确保应用已加入电池优化白名单
4. **后台运行权限**：检查应用是否允许后台运行

#### 系统相关
1. **时区问题**：检查设备时区设置是否正确
2. **系统版本**：确保Android版本支持所需功能
3. **厂商限制**：部分厂商ROM可能有额外限制
4. **勿扰模式**：检查系统勿扰模式设置

#### 调试步骤
```bash
# 查看应用日志
adb logcat | grep "todo_list_app"

# 检查通知权限
adb shell dumpsys notification

# 查看电池优化状态
adb shell dumpsys deviceidle whitelist
```

### 💥 Release版本崩溃

1. **ProGuard规则**：确保已正确配置混淆规则
2. **权限问题**：检查生产环境权限配置
3. **日志分析**：使用 `adb logcat` 查看崩溃日志
4. **依赖冲突**：检查第三方库版本兼容性

### 💾 数据库问题

1. **初始化失败**：检查数据库文件权限和存储空间
2. **数据丢失**：确保正确处理数据库升级和迁移
3. **性能问题**：优化数据库查询语句和索引
4. **并发问题**：确保数据库操作的线程安全

### 🔋 电池优化相关

1. **权限申请失败**：检查targetSdkVersion和权限配置
2. **白名单添加失败**：确保用户手动允许了权限
3. **厂商定制**：不同厂商可能有不同的电池优化策略
4. **系统版本兼容**：Android 6.0以下不需要此权限

## 📱 应用截图

### 主要界面
- 🏠 主页面：任务列表和统计信息
- ➕ 添加任务：创建和编辑任务界面
- 🔔 通知设置：通知权限和设置管理
- 📚 使用指南：5步交互式教程

### 权限申请流程
- 🎯 使用指南展示
- 🔐 通知权限申请
- 🔋 电池优化权限对话框
- ✅ 权限配置完成

## 🤝 贡献指南

1. Fork 项目
2. 创建功能分支：`git checkout -b feature/amazing-feature`
3. 提交更改：`git commit -m 'Add amazing feature'`
4. 推送分支：`git push origin feature/amazing-feature`
5. 提交 Pull Request

## 📄 开源协议

本项目采用 MIT 协议 - 查看 [LICENSE](LICENSE) 文件了解详情

## 🙏 致谢

- [Flutter团队](https://flutter.dev) - 优秀的跨平台框架
- [Material Design](https://material.io) - 设计指导原则
- [Flutter Community](https://flutter.dev/community) - 丰富的插件生态
- [Permission Handler](https://pub.dev/packages/permission_handler) - Android权限管理
- [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications) - 本地通知支持
- [SharedPreferences](https://pub.dev/packages/shared_preferences) - 偏好设置存储

## 📞 联系方式

- GitHub: [@fxlqwq](https://github.com/fxlqwq)
- 项目链接: [https://github.com/fxlqwq/ToDoList-Notice-Flutter](https://github.com/fxlqwq/ToDoList-Notice-Flutter)

## 📈 版本历史

### v1.5.7 (当前版本)
- 🚀 修复首次启动画面逻辑冲突问题
- 🎯 添加主界面交互式子任务完成功能
- 🔧 优化TodoProvider状态管理和数据同步
- 🎨 修复编译错误和已弃用API使用
- 💡 提升用户体验和界面响应性

### v1.5.6
- ✨ 添加子任务系统和进度跟踪
- 📎 集成多媒体附件功能（图片、音频、文本）
- 📝 支持Markdown格式任务描述
- 🌏 完整中文本地化
- 🗃️ 数据库架构升级至版本2

### v1.5.0
- ✨ 添加首次使用指南
- 🔋 集成电池优化权限管理
- 🔐 实现智能权限申请系统
- 💾 添加偏好设置管理
- 📱 Android原生权限处理

### v1.4.2
- 🔧 改进通知系统稳定性
- 🛡️ 增强错误处理机制
- 🎨 优化用户界面体验

### v1.0.0
- 🎉 首个正式版本发布
- 📝 基础任务管理功能
- 🔔 本地通知提醒
- 💾 SQLite数据存储

---

⭐ 如果这个项目对您有帮助，请给它一个星标！

💡 **提示**：首次安装后，请按照应用的使用指南完成权限设置，以获得最佳的通知体验。
