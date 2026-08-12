//
//  STImage+PhotoLibrary.swift
//  STMedia
//
//  Created by 寒江孤影 on 2018/3/14.
//

import UIKit
import Photos
import STBaseProject

extension UIImage {

    // MARK: - 网络与相册

    /// 从远端 URL 异步加载图片
    /// - Parameter url: 图片地址
    /// - Returns: 加载成功的 `UIImage`，失败抛出 `STImageError.invalidData`
    public static func load(from url: URL) async throws -> UIImage {
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let image = UIImage(data: data) else { throw STImageError.invalidData }
        return image
    }

    /// 保存图片到系统相册（需要 `NSPhotoLibraryAddUsageDescription`）
    /// - Throws: 无权限时抛出 `STImageError.photoLibraryPermissionDenied`
    @available(iOS 14, *)
    public func saveToPhotoLibrary() async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            throw STImageError.photoLibraryPermissionDenied
        }
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: self)
        }
    }
}
