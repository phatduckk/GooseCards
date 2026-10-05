import SwiftUI

struct ImageSearchView: View {
    let onSelect: (Data) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var query = ""
    @State private var photos: [UnsplashPhoto] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isDownloading = false

    private let columns = [GridItem(.adaptive(minimum: 110), spacing: 10)]

    var body: some View {
        NavigationStack {
            Group {
                if !UnsplashService.isConfigured {
                    ContentUnavailableView(
                        "Image Search Not Set Up",
                        systemImage: "key.slash",
                        description: Text("Add an Unsplash API key to Services/Secrets.swift to enable picture search.")
                    )
                } else if let errorMessage {
                    ContentUnavailableView(
                        "Oops",
                        systemImage: "wifi.slash",
                        description: Text(errorMessage)
                    )
                } else if photos.isEmpty && !isLoading && !query.isEmpty {
                    ContentUnavailableView.search(text: query)
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(photos) { photo in
                                AsyncImage(url: URL(string: photo.urls.thumb)) { phase in
                                    if let image = phase.image {
                                        image.resizable().scaledToFill()
                                    } else {
                                        Color(.tertiarySystemFill)
                                    }
                                }
                                .frame(height: 110)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .onTapGesture { select(photo) }
                            }
                        }
                        .padding()

                        Text("Photos from Unsplash")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.bottom)
                    }
                }
            }
            .overlay {
                if isLoading || isDownloading {
                    ProgressView()
                }
            }
            .navigationTitle("Search for a Picture")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, prompt: "island, volcano, triangle…")
            .onSubmit(of: .search, runSearch)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func runSearch() {
        guard UnsplashService.isConfigured else { return }
        isLoading = true
        errorMessage = nil
        Task {
            do {
                photos = try await UnsplashService.search(query: query)
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    private func select(_ photo: UnsplashPhoto) {
        isDownloading = true
        Task {
            do {
                let data = try await UnsplashService.downloadImageData(from: photo.urls.small)
                onSelect(ImageProcessing.downsample(data: data) ?? data)
                Haptics.success()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isDownloading = false
        }
    }
}
