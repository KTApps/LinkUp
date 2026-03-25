//
//  CalendarView.swift
//  LinkUp
//

import SwiftUI

private let monthTitleFont = Font.title2.weight(.semibold)
private let weekdayHeaderFont = Font.caption
private let dayCellFont = Font.subheadline
private let monthsRange = 12
private let weekdaySymbols = ["S", "M", "T", "W", "T", "F", "S"]

private var monthYearFormatter: DateFormatter {
    let f = DateFormatter()
    f.dateFormat = "MMMM yyyy"
    return f
}

/// Scrollable calendar showing multiple months (1–2 visible at a time). Display-only; AuthTheme.
struct CalendarView: View {
    @ObservedObject var authState: AuthState
    private let calendar = Calendar.current
    @State private var myConfirmations: [PollConfirmation] = []
    @State private var confirmationRates: [String: Double] = [:]
    @State private var selectedPollForDetails: Poll?
    private var monthsToShow: [Date] {
        guard let start = calendar.date(byAdding: .month, value: -monthsRange, to: Date()),
              let end = calendar.date(byAdding: .month, value: monthsRange, to: Date()) else {
            return [Date()]
        }
        var dates: [Date] = []
        var current = calendar.startOfMonth(start)
        let endStart = calendar.startOfMonth(end)
        while current <= endStart {
            dates.append(current)
            current = calendar.date(byAdding: .month, value: 1, to: current) ?? current
        }
        return dates
    }

    private var currentMonthStart: Date {
        calendar.startOfMonth(Date())
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 28) {
                    ForEach(monthsToShow, id: \.self) { monthStart in
                        monthBlock(monthStart: monthStart)
                            .id(monthStart)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .onAppear {
                // Defer scroll so LazyVStack has laid out the current month
                DispatchQueue.main.async {
                    proxy.scrollTo(currentMonthStart, anchor: .top)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AuthTheme.background)
        .task {
            await loadConfirmations()
        }
        .overlay {
            if let poll = selectedPollForDetails {
                ZStack {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .overlay(Color.black.opacity(0.15))
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.easeOut(duration: 0.25)) {
                                selectedPollForDetails = nil
                            }
                        }
                    MoreDetailsPopupView(
                        poll: poll,
                        showUnconfirmButton: true,
                        onUnconfirm: {
                            Task {
                                try? await authState.unconfirmVote(pollId: poll.id)
                                await loadConfirmations()
                            }
                            withAnimation(.easeOut(duration: 0.25)) {
                                selectedPollForDetails = nil
                            }
                        },
                        onClose: {
                            withAnimation(.easeOut(duration: 0.25)) {
                                selectedPollForDetails = nil
                            }
                        }
                    )
                }
            }
        }
    }

    private func monthBlock(monthStart: Date) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(monthYearFormatter.string(from: monthStart))
                .font(monthTitleFont)
                .foregroundStyle(AuthTheme.primary)

            weekdayHeaders

            dayGrid(monthStart: monthStart)
        }
    }

    private var weekdayHeaders: some View {
        HStack(spacing: 0) {
            ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                Text(symbol)
                    .font(weekdayHeaderFont)
                    .fontWeight(.black)
                    .foregroundStyle(AuthTheme.accent)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func dayGrid(monthStart: Date) -> some View {
        let numberOfDays = calendar.range(of: .day, in: .month, for: monthStart)?.count ?? 0
        let firstWeekday = calendar.component(.weekday, from: monthStart)
        let leadingBlanks = (firstWeekday - calendar.firstWeekday + 7) % 7
        let totalCells = leadingBlanks + numberOfDays
        let rows = (totalCells + 6) / 7

        return VStack(spacing: 8) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<7, id: \.self) { col in
                        let index = row * 7 + col
                        dayCell(
                            index: index,
                            leadingBlanks: leadingBlanks,
                            numberOfDays: numberOfDays,
                            monthStart: monthStart
                        )
                    }
                }
            }
        }
    }

    private func dayCell(index: Int, leadingBlanks: Int, numberOfDays: Int, monthStart: Date) -> some View {
        let dayNumber: Int? = {
            if index < leadingBlanks { return nil }
            let day = index - leadingBlanks + 1
            return day <= numberOfDays ? day : nil
        }()
        let isToday: Bool = {
            guard let day = dayNumber else { return false }
            var comps = calendar.dateComponents([.year, .month], from: monthStart)
            comps.day = day
            guard let date = calendar.date(from: comps) else { return false }
            return calendar.isDateInToday(date)
        }()

        return Group {
            if let day = dayNumber {
                let date = dayDate(monthStart: monthStart, day: day)
                let dayConfirmations = myConfirmations.filter { calendar.isDate($0.activityDate, inSameDayAs: date) }
                ZStack {
                    if isToday {
                        Circle()
                            .fill(AuthTheme.accent.opacity(0.15))
                            .frame(width: 36, height: 36)
                    }
                    Text("\(day)")
                        .font(dayCellFont)
                        .foregroundStyle(isToday ? AuthTheme.accent : AuthTheme.primary)
                    if let first = dayConfirmations.first {
                        Circle()
                            .fill(dotColor(for: first.pollId))
                            .frame(width: 6, height: 6)
                            .offset(y: 14)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .contentShape(Rectangle())
                .onTapGesture {
                    guard let first = dayConfirmations.first else { return }
                    Task {
                        if let poll = try? await authState.fetchPollById(pollId: first.pollId) {
                            await MainActor.run {
                                selectedPollForDetails = poll
                            }
                        }
                    }
                }
            } else {
                Color.clear
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
            }
        }
    }

    private func dayDate(monthStart: Date, day: Int) -> Date {
        var comps = calendar.dateComponents([.year, .month], from: monthStart)
        comps.day = day
        return calendar.date(from: comps) ?? monthStart
    }

    private func dotColor(for pollId: String) -> Color {
        let rate = confirmationRates[pollId] ?? 0
        if rate > 0.79 { return .green }
        if rate >= 0.60 { return .orange }
        return .red
    }

    private func loadConfirmations() async {
        do {
            let confirmations = try await authState.fetchMyPositiveConfirmations()
            var rates: [String: Double] = [:]
            for confirmation in confirmations {
                if rates[confirmation.pollId] == nil {
                    rates[confirmation.pollId] = try await authState.fetchPositiveConfirmationRate(pollId: confirmation.pollId)
                }
            }
            await MainActor.run {
                myConfirmations = confirmations
                confirmationRates = rates
            }
        } catch {
            await MainActor.run {
                myConfirmations = []
                confirmationRates = [:]
            }
        }
    }
}

private extension Calendar {
    func startOfMonth(_ date: Date) -> Date {
        let comps = dateComponents([.year, .month], from: date)
        return self.date(from: comps) ?? date
    }
}

#Preview {
    CalendarView(authState: AuthState())
        .background(AuthTheme.background)
}
