//
//  ContentView.swift
//  LinkUp
//
//  Created by Kelvin Mahaja on 19/02/2026.
//

import SwiftUI

/// Main app view when the user is logged in.
struct ContentView: View {
    @ObservedObject var authState: AuthState

    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
    }
}

#Preview {
    ContentView(authState: AuthState())
}
