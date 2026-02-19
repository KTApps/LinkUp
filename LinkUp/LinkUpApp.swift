//
//  LinkUpApp.swift
//  LinkUp
//
//  Created by Kelvin Mahaja on 19/02/2026.
//

import SwiftUI
import Firebase

@main
struct LinkUpApp: App {
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
