//
//  PollCardMediaPager.swift
//  LinkUp
//

import SwiftUI
import MapKit

/// Width:height for poll media (portrait). Landscape uploads are cropped with fill inside this box.
private let pollMediaAspectWidth: CGFloat = 9
private let pollMediaAspectHeight: CGFloat = 16

/// Full-bleed poll media: empty filler, optional image, optional map; two-page autoplay when both exist.
struct PollCardMediaPager: View {
    let poll: Poll
    @Binding var pageIndex: Int
    var onSingleTap: () -> Void
    var onDoubleTap: () -> Void

    @State private var autoplayTask: Task<Void, Never>?
    @State private var mapPosition: MapCameraPosition = .automatic

    private var hasImage: Bool {
        guard let s = poll.imageURL, !s.isEmpty, URL(string: s) != nil else { return false }
        return true
    }

    private var hasMap: Bool { poll.hasActivityLocation }

    private var dualPage: Bool { hasImage && hasMap }

    private var coordinate: CLLocationCoordinate2D? {
        guard let lat = poll.activityLatitude, let lon = poll.activityLongitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    var body: some View {
        GeometryReader { geo in
            let w = max(geo.size.width, 1)
            let portraitH = w * pollMediaAspectHeight / pollMediaAspectWidth
            ZStack {
                AuthTheme.background

                ZStack {
                    Group {
                        if !hasImage && !hasMap {
                            emptyFiller
                        } else if hasImage && !hasMap {
                            imageLayer(width: w, height: portraitH)
                        } else if !hasImage && hasMap {
                            mapLayer(width: w, height: portraitH)
                        } else {
                            if pageIndex == 0 {
                                imageLayer(width: w, height: portraitH)
                            } else {
                                mapLayer(width: w, height: portraitH)
                            }
                        }
                    }
                    .frame(width: w, height: portraitH)
                    .clipped()
                }
                .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
                .clipped()

                PollMediaTapOverlayView(
                    onSingleTap: onSingleTap,
                    onDoubleTap: dualPage ? onDoubleTap : {}
                )
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .onAppear {
            syncMapCamera()
            startAutoplayIfNeeded()
        }
        .onDisappear {
            autoplayTask?.cancel()
            autoplayTask = nil
        }
        .onChange(of: poll.id) { _, _ in
            autoplayTask?.cancel()
            autoplayTask = nil
            pageIndex = 0
            syncMapCamera()
            startAutoplayIfNeeded()
        }
        .onChange(of: poll.imageURL) { _, _ in
            autoplayTask?.cancel()
            autoplayTask = nil
            pageIndex = 0
            startAutoplayIfNeeded()
        }
        .onChange(of: poll.activityLatitude) { _, _ in
            syncMapCamera()
            autoplayTask?.cancel()
            autoplayTask = nil
            pageIndex = 0
            startAutoplayIfNeeded()
        }
        .onChange(of: poll.activityLongitude) { _, _ in
            syncMapCamera()
            autoplayTask?.cancel()
            autoplayTask = nil
            pageIndex = 0
            startAutoplayIfNeeded()
        }
    }

    private var emptyFiller: some View {
        LinearGradient(
            colors: [
                AuthTheme.background,
                AuthTheme.primary.opacity(0.08),
                AuthTheme.accent.opacity(0.06),
                AuthTheme.background
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    @ViewBuilder
    private func imageLayer(width: CGFloat, height: CGFloat) -> some View {
        if let urlString = poll.imageURL, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: width, height: height)
                        .clipped()
                case .failure, .empty:
                    Rectangle()
                        .fill(AuthTheme.primary.opacity(0.1))
                        .frame(width: width, height: height)
                        .overlay {
                            ProgressView()
                                .tint(AuthTheme.primary)
                        }
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: width, height: height)
            .clipped()
        } else {
            emptyFiller
        }
    }

    @ViewBuilder
    private func mapLayer(width: CGFloat, height: CGFloat) -> some View {
        if let coord = coordinate {
            Map(position: $mapPosition) {
                Annotation("", coordinate: coord) {
                    Circle()
                        .fill(AuthTheme.accent)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .strokeBorder(AuthTheme.background, lineWidth: 2)
                        )
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .frame(width: width, height: height)
            .clipped()
        } else {
            emptyFiller
        }
    }

    private func syncMapCamera() {
        guard let coord = coordinate else {
            mapPosition = .automatic
            return
        }
        mapPosition = .region(
            MKCoordinateRegion(
                center: coord,
                span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
            )
        )
    }

    private func startAutoplayIfNeeded() {
        autoplayTask?.cancel()
        guard dualPage else { return }
        autoplayTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                guard !Task.isCancelled else { break }
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        pageIndex = pageIndex == 0 ? 1 : 0
                    }
                }
            }
        }
    }
}

// MARK: - UIKit tap overlay (single vs double tap without double-firing single)

struct PollMediaTapOverlayView: UIViewRepresentable {
    var onSingleTap: () -> Void
    var onDoubleTap: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onSingle: onSingleTap, onDouble: onDoubleTap)
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = true

        let doubleTap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDouble))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.delegate = context.coordinator
        doubleTap.cancelsTouchesInView = false

        let singleTap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleSingle))
        singleTap.numberOfTapsRequired = 1
        singleTap.require(toFail: doubleTap)
        singleTap.delegate = context.coordinator
        singleTap.cancelsTouchesInView = false

        view.addGestureRecognizer(doubleTap)
        view.addGestureRecognizer(singleTap)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.onSingle = onSingleTap
        context.coordinator.onDouble = onDoubleTap
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var onSingle: () -> Void
        var onDouble: () -> Void

        init(onSingle: @escaping () -> Void, onDouble: @escaping () -> Void) {
            self.onSingle = onSingle
            self.onDouble = onDouble
        }

        @objc func handleSingle() {
            onSingle()
        }

        @objc func handleDouble() {
            onDouble()
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            true
        }
    }
}
