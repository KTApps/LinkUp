//
//  PollsView.swift
//  LinkUp
//

import SwiftUI

private let headerBarHeight: CGFloat = 44
private let headerBottomPadding: CGFloat = 10

/// Main poll page: vertical list of poll cards (hardcoded data).
/// Custom header with settings (top left); content scrolls underneath the header like the tab bar.
struct PollsView: View {
    @State private var polls: [Poll] = HardcodedPolls.sample

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                ScrollView {
                    VStack(spacing: geometry.size.height * 0.03) {
                        ForEach(polls.indices, id: \.self) { index in
                            PollCardView(poll: $polls[index])
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, geometry.size.width * 0.05)
                    .padding(.top, headerBarHeight + headerBottomPadding + geometry.safeAreaInsets.top)
                    .padding(.bottom, geometry.size.height * 0.03)
                }

                pollsHeader(safeAreaTop: geometry.safeAreaInsets.top)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AuthTheme.background)
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private func pollsHeader(safeAreaTop: CGFloat) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(AuthTheme.secondary)

                Text("username")
                    .font(.subheadline)
                    .foregroundStyle(AuthTheme.primary)

                Spacer()

                Button {
                    // TODO: open bar chart / stats
                } label: {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(AuthTheme.secondary)
                }
                .buttonStyle(.plain)

                Button {
                    // TODO: open settings
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(AuthTheme.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .frame(height: headerBarHeight)
            .padding(.top, safeAreaTop)
            .padding(.bottom, headerBottomPadding)
            .background(AuthTheme.background)
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .background(AuthTheme.background)
        .ignoresSafeArea(edges: .top)
    }
}

#Preview {
    NavigationStack {
        PollsView()
    }
}
