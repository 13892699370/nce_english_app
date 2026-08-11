# 新概念英语学习打卡 App

一个基于 Flutter 的新概念英语学习打卡应用，支持 Android 和 iOS 双端。

## 功能

- 新概念英语课程按天学习与打卡
- 本地 Hive 数据存储
- 单词学习、认识/不认识复习记录
- 生词本
- 液态玻璃风格 UI
- 深色 / 浅色模式
- 英音 / 美音 TTS 单词发音
- 认识 / 不认识按钮本地反馈音效
- 完成当天任务后的全屏仪式感动画
- GitHub Actions 云端构建 APK 和未签名 IPA

## 本地运行

```bash
flutter pub get
flutter run
```

## 云端打包

项目已配置 GitHub Actions：

- 推送到 `main` 或 `master` 分支后自动构建
- 也可以在 GitHub Actions 页面手动运行 `Build APK & IPA`

构建完成后会生成两个 Artifacts：

- `android-apk`：Android 安装包
- `ios-unsigned-ipa`：iOS 未签名 IPA，需要使用 Sideloadly、AltStore、TrollStore 等工具自签安装

## 开源协议

本项目使用 MIT License 开源。
