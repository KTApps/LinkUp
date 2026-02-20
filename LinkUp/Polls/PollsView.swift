//
//  PollsView.swift
//  LinkUp
//

import SwiftUI

/// Main poll page: vertical list of poll cards (hardcoded data).
/// Responsive: GeometryReader, proportional padding/spacing, ScrollView. AuthTheme throughout.
struct PollsView: View {
    @State private var polls: [Poll] = HardcodedPolls.sample

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: geometry.size.height * 0.03) {
                        ForEach(polls.indices, id: \.self) { index in
                            PollCardView(poll: $polls[index])
                        }
                    }
                    .padding(.horizontal, geometry.size.width * 0.05)
                    .padding(.vertical, geometry.size.height * 0.03)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AuthTheme.background)
            .navigationTitle("Polls")
            .toolbarTitleDisplayMode(.inline)
            .toolbarBackground(AuthTheme.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

#Preview {
    NavigationStack {
        PollsView()
    }
}
