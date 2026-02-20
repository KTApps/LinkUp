//
//  Input.swift
//  LinkUp
//
//  Created by Kelvin Mahaja on 20/02/2026.
//

import SwiftUI

/// Reusable text input for email, password, username. Use secureField: true for passwords.
struct Input: View {
    @Binding var text: String
    let title: String
    let placeholder: String
    var secureField: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            if secureField {
                SecureField(placeholder, text: $text)
                    .textFieldStyle(.plain)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .autocapitalization(.none)
            } else {
                TextField(placeholder, text: $text)
                    .textFieldStyle(.plain)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .autocapitalization(.none)
            }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        Input(text: .constant(""), title: "Email", placeholder: "name@example.com")
        Input(text: .constant(""), title: "Password", placeholder: "••••••••", secureField: true)
    }
    .padding()
}
