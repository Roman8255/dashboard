import SwiftUI

struct PhotosWidgetView: View {
    let styleId: String
    @ObservedObject private var photos = PhotoLibraryService.shared

    var body: some View {
        WidgetCard(showBackground: styleId != "single") {
            Group {
                if photos.authorizationDenied {
                    permissionView
                } else if photos.recentImages.isEmpty {
                    ProgressView()
                        .task { photos.loadPhotos() }
                } else if styleId == "collage" {
                    collageView
                } else {
                    singleView
                }
            }
        }
        .onAppear { photos.loadIfNeeded() }
    }

    private var permissionView: some View {
        VStack(spacing: 6) {
            Image(systemName: "photo")
                .font(.title2)
            Text("Povoliť fotky")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(8)
    }

    private var singleView: some View {
        Group {
            if let image = photos.recentImages.first {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            }
        }
        .clipped()
    }

    private var collageView: some View {
        let images = Array(photos.recentImages.prefix(4))
        return LazyVGrid(columns: [GridItem(.flexible(), spacing: 2), GridItem(.flexible(), spacing: 2)], spacing: 2) {
            ForEach(Array(images.enumerated()), id: \.offset) { _, image in
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                    .clipped()
            }
        }
        .padding(2)
    }
}
