//
//  ContentView.swift
//  LinkUp
//
//  Created by Kelvin Mahaja on 19/02/2026.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authState = AuthState()

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
    ContentView()
}
