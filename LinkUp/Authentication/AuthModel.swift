//
//  AuthModel.swift
//  LinkUp
//
//  Created by Kelvin Mahaja on 20/02/2026.
//

import Foundation

/// User profile data stored in Firestore (AuthenticationData map).
/// Codable for encoding/decoding to/from Firestore.
struct AuthModel: Identifiable, Codable {
    let id: String
    let username: String
    let email: String

    var initial: String {
        username.first?.uppercased() ?? ""
    }
}
