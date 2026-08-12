# STMedia

> **A feature-rich iOS media-processing Swift package** — image processing, QR/barcode scanning, camera & photo library, screenshot detection and rich `UIImage`/`UIView` extensions. Supports Swift Package Manager.

[![License](https://img.shields.io/badge/license-MIT-green?style=flat)](https://github.com/i-stack/STMedia/blob/main/LICENSE)
[![Platform](https://img.shields.io/badge/platform-iOS%2013%2B-lightgrey?style=flat)](https://github.com/i-stack/STMedia)
[![Swift](https://img.shields.io/badge/Swift-5.0%20%7C%205.9-orange?style=flat-square)](https://www.swift.org)
[![SPM](https://img.shields.io/badge/SPM-supported-brightgreen?style=flat)](https://github.com/i-stack/STMedia)
[![Xcode](https://img.shields.io/badge/Xcode-12%2B-147EFB?style=flat)](https://developer.apple.com/xcode/)

**STMedia** is an open-source **iOS media toolkit** written in **Swift**, providing image processing (compress / crop / scale / rotate / watermark / format conversion), a customizable QR & barcode scanner, full camera/photo-library flows, screenshot detection and a rich set of `UIImage` / `UIView` extensions.

STMedia 是一个功能丰富的 iOS 媒体处理 Swift 包，提供图片处理、扫码、截图、相机/相册流程以及实用的 `UIImage` / `UIView` 扩展。

## 📋 目录 | Table of Contents

- [特性 | Features](#features)
- [系统要求 | Requirements](#requirements)
- [安装方式 | Installation](#installation)
- [快速开始 | Quick Start](#quick-start)
  - [图片处理 | Image](#image)
  - [图片管理 | Image Manager](#image-manager)
  - [扫码 | Scanning](#scanning)
  - [截图 | Screenshot](#screenshot)
  - [权限 | Permissions](#permissions)
- [Info.plist 配置 | Info.plist](#info-plist)
- [依赖项 | Dependencies](#dependencies)
- [许可证 | License](#license)

<a id="features"></a>
## 🎯 特性 | Features

| 类别 | 能力 |
| --- | --- |
| 图片处理 | 判空、压缩、裁剪、缩放、旋转、格式识别与 PNG/JPEG 转换 |
| 水印 | 文字水印、图片水印，支持位置与透明度 |
| 图片管理 | 相机拍照、相册选择、保存至相册、权限请求 |
| 扫码 | 二维码 / 条形码扫描，可自定义扫描界面与区域 |
| 截图 | 监听系统截图通知、获取当前屏幕截图、预览浮层 |
| UI 扩展 | 丰富的 `UIImage` 与 `UIView` 扩展方法 |

<a id="installation"></a>
## 🚀 安装方式 | Installation

### Swift Package Manager

在 `Package.swift` 中声明依赖：

```swift
dependencies: [
    .package(url: "https://github.com/i-stack/STMedia.git", from: "1.0.0"),
],
targets: [
    .target(
        name: "YourApp",
        dependencies: [.product(name: "STMedia", package: "STMedia")]
    )
]
```

或在 Xcode 中选择 `File ▸ Add Package Dependencies...`，输入 `https://github.com/i-stack/STMedia.git`。

<a id="quick-start"></a>
## ⚡ 快速开始 | Quick Start

<a id="image"></a>
### 图片处理 | Image

```swift
import STMedia

// 判空
let isEmpty = UIImage.isEmpty(image)

// 压缩 / 裁剪 / 缩放 / 旋转
let compressed = image.st_compressImage(quality: 0.8)
let cropped   = image.st_cropImage(to: CGRect(x: 0, y: 0, width: 100, height: 100))
let scaled    = image.st_scaleImage(to: CGSize(width: 200, height: 200))
let rotated   = image.st_rotateImage(angle: 90)

// 格式识别与转换
let format = image.st_imageFormat
let pngData  = image.st_convertToPNG()
let jpegData = image.st_convertToJPEG(quality: 0.8)

// 水印
let watermarked = image.st_addTextWatermark(
    text: "STMedia", position: .bottomRight, fontSize: 16, color: .white
)
let finalImage = image.st_addImageWatermark(
    watermark: UIImage(named: "logo"), position: .topLeft, alpha: 0.7
)
```

<a id="image-manager"></a>
### 图片管理 | Image Manager

```swift
import STMedia

// 相机拍照
STImageManager.shared.takePhoto(from: .camera) { result in
    switch result {
    case .success(let image):  self.imageView.image = image
    case .failure(let error):  print("拍照失败: \(error)")
    }
}

// 相册选择
STImageManager.shared.selectImage(from: .photoLibrary) { result in
    switch result {
    case .success(let image):  self.imageView.image = image
    case .failure(let error):  print("选择图片失败: \(error)")
    }
}

// 保存至相册
STImageManager.shared.saveImageToPhotoLibrary(image) { result in
    switch result {
    case .success:        print("图片保存成功")
    case .failure(let e): print("保存失败: \(e)")
    }
}
```

<a id="scanning"></a>
### 扫码 | Scanning

```swift
import STMedia

// 基础扫码
let scanManager = STScanManager()
scanManager.scanType = .STScanTypeQrCode
scanManager.presentVC = self
scanManager.scanFinishBlock = { result in
    print("扫描结果: \(result)")
}
scanManager.startScan()

// 自定义扫码界面
var config = STScanViewConfiguration()
config.scanAreaMargin = 80.0
config.borderColor = .systemBlue
config.cornerColor = .systemRed
config.tipText = "请将二维码放入扫描框内"
config.tipTextColor = .white

let scanView = STScanView(frame: view.bounds, configuration: config)
view.addSubview(scanView)
scanView.startScanning()
```

<a id="screenshot"></a>
### 截图 | Screenshot

```swift
import STMedia

NotificationCenter.default.addObserver(
    self,
    selector: #selector(userDidTakeScreenshot),
    name: UIApplication.userDidTakeScreenshotNotification,
    object: nil
)

@objc func userDidTakeScreenshot() {
    guard let screenshot = STScreenShot.st_imageWithScreenshot() else { return }
    let preview = STScreenShot.st_showScreenshotImage(rect: CGRect(x: 0, y: 0, width: 200, height: 200))
    view.addSubview(preview)
    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
        preview.removeFromSuperview()
    }
}

deinit { NotificationCenter.default.removeObserver(self) }
```

<a id="permissions"></a>
### 权限 | Permissions

```swift
STImageManager.shared.requestCameraPermission { granted in
    print(granted ? "相机权限已授权" : "相机权限被拒绝")
}

STImageManager.shared.requestPhotoLibraryPermission { granted in
    print(granted ? "相册权限已授权" : "相册权限被拒绝")
}
```

<a id="info-plist"></a>
## 🔧 Info.plist 配置 | Info.plist

使用前请在 `Info.plist` 添加相应权限描述：

```xml
<key>NSCameraUsageDescription</key>
<string>需要访问相机来拍照</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>需要访问相册来选择图片</string>

<key>NSPhotoLibraryAddUsageDescription</key>
<string>需要访问相册来保存图片</string>
```

<a id="dependencies"></a>
## 📦 依赖项 | Dependencies

- `STBaseProject` — 基础工具库（仓库 `Package.swift` 以本地 `path: "../STBaseProject"` 引用，发布时改为远程 URL）
- `UIKit` / `Photos` / `AVFoundation` — 系统框架

<a id="license"></a>
## 📄 许可证 | License

本项目采用 MIT 许可证，详见 [LICENSE](LICENSE)。

---

**STMedia** — an iOS media-processing toolkit for Swift. Keywords: *iOS, Swift, UIImage, scanning, camera, photo library, screenshot, watermark, Swift Package Manager*.
