//
//  STImageManager.swift
//  STBaseProject
//
//  Created by ST on 2025/1/13.
//

import UIKit
import AVFoundation
import Photos

// MARK: - 图片来源枚举
public enum STImageSource {
    case camera
    case photoLibrary
    case simulator
    case unknown
    
    public var description: String {
        switch self {
        case .camera:
            return "camera"
        case .photoLibrary:
            return "photo_library"
        case .simulator:
            return "simulator"
        case .unknown:
            return "unknown"
        }
    }
}

// MARK: - 统一图片管理器
public class STImageManager: NSObject {
    
    public static let shared = STImageManager()
    private var currentCompletion: STImageManagerCompletion?
    private var imagePickerController: UIImagePickerController?
    private var configuration: STImageManagerConfiguration = STImageManagerConfiguration()

    private override init() {
        super.init()
    }
    
    deinit {
        imagePickerController?.delegate = nil
        imagePickerController = nil
    }
    
    public func updateConfiguration(_ config: STImageManagerConfiguration) {
        self.configuration = config
    }
        
    /// 选择图片（相机或照片库）
    public func selectImage(from viewController: UIViewController,
                           source: STImageSource = .photoLibrary,
                           configuration: STImageManagerConfiguration? = nil,
                           completion: @escaping STImageManagerCompletion) {
        if let config = configuration {
            self.configuration = config
        }
        self.currentCompletion = completion
        switch source {
        case .camera:
            openCamera(from: viewController)
        case .photoLibrary:
            openPhotoLibrary(from: viewController)
        case .simulator:
            handleError(.deviceNotAvailable(.simulator))
        case .unknown:
            handleError(.unknown)
        }
    }
    
    /// 显示选择器（让用户选择相机或照片库）
    /// - Parameters:
    ///   - viewController: 源视图控制器
    ///   - configuration: 配置选项，包含自定义文本等设置
    ///   - completion: 完成回调
    public func showImagePicker(from viewController: UIViewController,
                               configuration: STImageManagerConfiguration? = nil,
                               completion: @escaping STImageManagerCompletion) {
        if let config = configuration {
            self.configuration = config
        }
        self.currentCompletion = completion
        let alert = UIAlertController(title: self.configuration.pickerTitle, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: self.configuration.cameraButtonTitle, style: .default) { _ in
            self.openCamera(from: viewController)
        })
        alert.addAction(UIAlertAction(title: self.configuration.photoLibraryButtonTitle, style: .default) { _ in
            self.openPhotoLibrary(from: viewController)
        })
        alert.addAction(UIAlertAction(title: self.configuration.cancelButtonTitle, style: .cancel) { _ in
            self.handleError(.userCancelled)
        })
        viewController.present(alert, animated: true)
    }
        
    private func openCamera(from viewController: UIViewController) {
        checkCameraPermission { [weak self] result in
            switch result {
            case .success:
                self?.presentImagePicker(sourceType: .camera, from: viewController)
            case .failure(let error):
                self?.handleError(error)
            }
        }
    }
    
    private func openPhotoLibrary(from viewController: UIViewController) {
        checkPhotoLibraryPermission { [weak self] result in
            switch result {
            case .success:
                self?.presentImagePicker(sourceType: .photoLibrary, from: viewController)
            case .failure(let error):
                self?.handleError(error)
            }
        }
    }
    
    private func presentImagePicker(sourceType: UIImagePickerController.SourceType, from viewController: UIViewController) {
        imagePickerController = UIImagePickerController()
        imagePickerController?.sourceType = sourceType
        imagePickerController?.allowsEditing = configuration.allowsEditing
        imagePickerController?.delegate = self
        if sourceType == .camera {
            imagePickerController?.cameraDevice = configuration.cameraDevice
            imagePickerController?.showsCameraControls = configuration.showsCameraControls
        }
        viewController.present(imagePickerController!, animated: true)
    }
    
    private func checkCameraPermission(completion: @escaping (Result<Void, STImageManagerError>) -> Void) {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            completion(.failure(.deviceNotAvailable(.camera)))
            return
        }
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            completion(.success(()))
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        completion(.success(()))
                    } else {
                        completion(.failure(.permissionDenied(.camera)))
                    }
                }
            }
        case .denied, .restricted:
            completion(.failure(.permissionDenied(.camera)))
        @unknown default:
            completion(.failure(.unknown))
        }
    }
    
    private func checkPhotoLibraryPermission(completion: @escaping (Result<Void, STImageManagerError>) -> Void) {
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            completion(.failure(.deviceNotAvailable(.photoLibrary)))
            return
        }
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .authorized:
            completion(.success(()))
        case .limited:
            completion(.success(()))
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { status in
                DispatchQueue.main.async {
                    if status == .authorized {
                        completion(.success(()))
                    } else {
                        completion(.failure(.permissionDenied(.photoLibrary)))
                    }
                }
            }
        case .denied, .restricted:
            completion(.failure(.permissionDenied(.photoLibrary)))
        @unknown default:
            completion(.failure(.unknown))
        }
    }
    
    private func handleError(_ error: STImageManagerError) {
        var model = STImageManagerModel()
        model.error = error
        currentCompletion?(model)
    }
}

// MARK: - UIImagePickerControllerDelegate
extension STImageManager: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        var model = STImageManagerModel()
        model.source = picker.sourceType == .camera ? .camera : .photoLibrary
        let imageKey = configuration.allowsEditing ? UIImagePickerController.InfoKey.editedImage : UIImagePickerController.InfoKey.originalImage
        guard let originalImage = info[imageKey] as? UIImage else {
            handleError(.unknown)
            picker.dismiss(animated: true)
            return
        }
        model.originalImage = originalImage
        if configuration.allowsEditing, let editedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            model.editedImage = editedImage
        } else {
            model.editedImage = originalImage
        }
        if let compressedData = UIImage.smartCompress(model.editedImage!, maxFileSize: configuration.maxFileSize) {
            model.imageData = compressedData
            #if DEBUG
            print("压缩后图片大小: \(compressedData.count / 1024) KB")
            #endif
        } else {
            model.error = .compressionFailed
        }
        if let type = model.editedImage!.getTypeString() {
            model.mimeType = "image/\(type)"
            model.fileName = "photo_\(Date().timeIntervalSince1970).\(type)"
        } else {
            model.mimeType = "image/\(configuration.imageFormat)"
            model.fileName = "photo_\(Date().timeIntervalSince1970).\(configuration.imageFormat)"
        }
        currentCompletion?(model)
        picker.dismiss(animated: true)
    }
    
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        var model = STImageManagerModel()
        model.error = .userCancelled
        currentCompletion?(model)
        picker.dismiss(animated: true)
    }
}

// MARK: - 数据模型
public struct STImageManagerModel {
    public var originalImage: UIImage?
    public var editedImage: UIImage?
    public var imageData: Data?
    public var fileName: String?
    public var mimeType: String?
    public var source: STImageSource?
    public var error: STImageManagerError?
    
    public init() {}
}

/// STImageManager 配置选项
public struct STImageManagerConfiguration {
    /// 是否允许编辑图片，默认为 true
    public var allowsEditing: Bool = true
    /// 是否显示相机控制界面，默认为 true
    public var showsCameraControls: Bool = true
    /// 相机设备类型，默认为后置摄像头
    public var cameraDevice: UIImagePickerController.CameraDevice = .rear
    /// 最大文件大小（KB），默认为 300KB
    public var maxFileSize: Int = 300
    /// 图片格式，默认为 "jpeg"
    public var imageFormat: String = "jpeg"
    /// 压缩质量，范围 0.0-1.0，默认为 0.8
    public var compressionQuality: CGFloat = 0.8
    /// 图片选择器弹窗标题，默认为 "选择图片来源"
    public var pickerTitle: String = "选择图片来源"
    /// 相机按钮文本，默认为 "相机"
    public var cameraButtonTitle: String = "相机"
    /// 照片库按钮文本，默认为 "照片库"
    public var photoLibraryButtonTitle: String = "照片库"
    /// 取消按钮文本，默认为 "取消"
    public var cancelButtonTitle: String = "取消"
    
    /// 初始化配置，使用默认值
    public init() {}
}

public enum STImageManagerError: LocalizedError {
    case permissionDenied(STImageSource)
    case deviceNotAvailable(STImageSource)
    case userCancelled
    case compressionFailed
    case unknown
    
    public var errorDescription: String? {
        switch self {
        case .permissionDenied(let source):
            return "Permission denied for \(source == .camera ? "camera" : "photo library")"
        case .deviceNotAvailable(let source):
            return "Device not available: \(source.description)"
        case .userCancelled:
            return "User cancelled"
        case .compressionFailed:
            return "Image compression failed"
        case .unknown:
            return "Unknown error occurred"
        }
    }
}

public typealias STImageManagerCompletion = (STImageManagerModel) -> Void

// MARK: - 上传能力
public extension STImageManager {
    func uploadImage(model: STImageManagerModel,
                     toURL urlString: String,
                     fieldName: String = "image",
                     parameters: [String: String] = [:],
                     completion: @escaping (Result<String, Error>) -> Void) {
        guard let data = model.imageData,
              let fileName = model.fileName,
              let mimeType = model.mimeType else {
            completion(.failure(NSError(domain: "STImageManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "invalid image model"])));
            return
        }
        upload(data: data,
               fileName: fileName,
               mimeType: mimeType,
               fieldName: fieldName,
               toURL: urlString,
               parameters: parameters,
               completion: completion)
    }

    func upload(data: Data,
                fileName: String,
                mimeType: String,
                fieldName: String = "image",
                toURL urlString: String,
                parameters: [String: String] = [:],
                completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "STImageManager", code: -2, userInfo: [NSLocalizedDescriptionKey: "invalid url"])));
            return
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = createFormDataBody(data: data,
                                             fileName: fileName,
                                             mimeType: mimeType,
                                             fieldName: fieldName,
                                             parameters: parameters,
                                             boundary: boundary)

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                if let data = data, let result = String(data: data, encoding: .utf8) {
                    completion(.success(result))
                } else {
                    completion(.failure(NSError(domain: "STImageManager", code: -3, userInfo: [NSLocalizedDescriptionKey: "invalid response"])));
                }
            }
        }
        task.resume()
    }

    private func createFormDataBody(data: Data,
                                    fileName: String,
                                    mimeType: String,
                                    fieldName: String,
                                    parameters: [String: String],
                                    boundary: String) -> Data {
        var body = Data()
        for (key, value) in parameters {
            body.st_appendString("--\(boundary)\r\n")
            body.st_appendString("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            body.st_appendString("\(value)\r\n")
        }
        body.st_appendString("--\(boundary)\r\n")
        body.st_appendString("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(fileName)\"\r\n")
        body.st_appendString("Content-Type: \(mimeType)\r\n\r\n")
        body.append(data)
        body.st_appendString("\r\n")
        body.st_appendString("--\(boundary)--\r\n")
        return body
    }
}

private extension Data {
    mutating func st_appendString(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
