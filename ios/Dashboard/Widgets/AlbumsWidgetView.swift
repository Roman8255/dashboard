import SwiftUI

struct AlbumsWidgetView: View {
    let styleId: String
    @ObservedObject private var photos = PhotoLibraryService.shared

    var body: some View {
        WidgetCard {
            Group {
                if photos.authorizationDenied {
                    VStack(spacing: 6) {
                        Image(systemName: "rectangle.stack")
                            .font(.title2)
                        Text("Povoliť fotky")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                } else if photos.albumCovers.isEmpty {
                    ProgressView()
                        .task { photos.loadPhotos() }
                } else if styleId == "cover" {
                    coverView
                } else {
                    gridView
                }
            }
        }
        .onAppear { photos.loadIfNeeded() }
    }

    private var coverView: some View {
        Group {
            if let cover = photos.albumCovers.first {
                Image(uiImage: cover)
                    .resizable()
                    .scaledToFill()
            }
        }
        .clipped()
    }

    private var gridView: some View {
        let covers = Array(photos.albumCovers.prefix(4))
        return LazyVGrid(columns: [GridItem(.flexible(), spacing: 3), GridItem(.flexible(), spacing: 3)], spacing: 3) {
            ForEach(Array(covers.enumerated()), id: \.offset) { _, cover in
                Image(uiImage: cover)
                    .resizable()
                    .scaledToFill()
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
        .padding(6)
    }
}
