//
//  StartView.swift
//  LinkUp
//
//  Created by Kelvin Mahaja on 20/02/2026.
//

import SwiftUI

/// Root container: owns the single AuthState and passes it to StartView.
struct RootView: View {
    @StateObject private var authState = AuthState()

    var body: some View {
        StartView(authState: authState)
            .onAppear {
                Task { await authState.restoreSession() }
            }
    }
}

/// Decides what to show first: main app when logged in, otherwise LogInView.
struct StartView: View {
    @ObservedObject var authState: AuthState

    var body: some View {
        Group {
            if authState.userSession != nil {
                ContentView(authState: authState)
            } else {
                LogInView(authState: authState)
            }
        }
    }
}

#Preview {
    StartView(authState: AuthState())
}
