import Photos
import UIKit

@MainActor
final class PhotoLibraryService: ObservableObject {
    static let shared = PhotoLibraryService()

    @Published private(set) var recentImages: [UIImage] = []
    @Published private(set) var albumCovers: [UIImage] = []
    @Published private(set) var authorizationDenied = false

    private init() {}

    func loadIfNeeded() {
        guard recentImages.isEmpty else { return }
        loadPhotos()
    }

    func loadPhotos() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .authorized, .limited:
            authorizationDenied = false
            fetchAssets()
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] newStatus in
                Task { @MainActor in
                    if newStatus == .authorized || newStatus == .limited {
                        self?.authorizationDenied = false
                        self?.fetchAssets()
                    } else {
                        self?.authorizationDenied = true
                    }
                }
            }
        default:
            authorizationDenied = true
        }
    }

    private func fetchAssets() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = 8

        let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        let manager = PHImageManager.default()
        let targetSize = CGSize(width: 400, height: 400)
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true

        var images: [UIImage] = []
        assets.enumerateObjects { asset, _, _ in
            manager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options) { image, _ in
                if let image {
                    Task { @MainActor in
                        images.append(image)
                        if images.count <= 8 {
                            self.recentImages = images
                        }
                    }
                }
            }
        }

        fetchAlbumCovers()
    }

    private func fetchAlbumCovers() {
        let collections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: nil)
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true

        var covers: [UIImage] = []
        collections.enumerateObjects { collection, index, stop in
            guard index < 6 else {
                stop.pointee = true
                return
            }
            let assets = PHAsset.fetchAssets(in: collection, options: nil)
            guard let asset = assets.firstObject else { return }

            manager.requestImage(for: asset, targetSize: CGSize(width: 300, height: 300), contentMode: .aspectFill, options: options) { image, _ in
                if let image {
                    Task { @MainActor in
                        covers.append(image)
                        self.albumCovers = covers
                    }
                }
            }
        }
    }
}
