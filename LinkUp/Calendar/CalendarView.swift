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
    private let calendar = Calendar.current
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
                proxy.scrollTo(currentMonthStart, anchor: .top)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AuthTheme.background)
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
                ZStack {
                    if isToday {
                        Circle()
                            .fill(AuthTheme.accent.opacity(0.15))
                            .frame(width: 36, height: 36)
                    }
                    Text("\(day)")
                        .font(dayCellFont)
                        .foregroundStyle(isToday ? AuthTheme.accent : AuthTheme.primary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 36)
            } else {
                Color.clear
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
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
    CalendarView()
        .background(AuthTheme.background)
}
