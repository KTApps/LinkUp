//
//  PollActivityDateFormatting.swift
//  LinkUp
//

import SwiftUI

/// Shared activity date line for poll cards and More Details (time · day month year).
enum PollActivityDateFormatting {
    @ViewBuilder
    static func dateSubtitle(activityDate: Date?) -> some View {
        if let date = activityDate {
            HStack(spacing: 4) {
                Text(date, format: .dateTime.hour().minute())
                Text("·")
                Text(date, format: .dateTime.day().month().year())
            }
            .font(Typography.subheadline)
            .foregroundStyle(AuthTheme.secondary)
        } else {
            Text("No date set")
                .font(Typography.subheadline)
                .foregroundStyle(AuthTheme.secondary)
        }
    }
}
