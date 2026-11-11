import SwiftData
import SwiftUI

struct CalendarView: View {
    @Query private var recordings: [Recording]
    @State private var month: Date = CalendarView.calendar.startOfMonth(for: .now)

    /// Called when a day with recordings is tapped. The Day screen comes later.
    var onSelectDay: (Date) -> Void = { _ in }

    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 1 // weeks start on Sunday
        return calendar
    }()

    private var calendar: Calendar { Self.calendar }

    var body: some View {
        ZStack {
            Color.paper.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // Same style and position as the date line on Home.
                Text(month, format: .dateTime.year())
                    .font(.dateLine)
                    .tracking(1)
                    .foregroundStyle(Color.inkMuted)

                header
                    .padding(.top, 8)

                LineArt.squiggleDivider
                    .stroke(Color.ink, style: .pen(Metrics.strokeFine))
                    .frame(height: 12)
                    .padding(.top, 18)

                weekdayRow
                    .padding(.top, 24)

                dayGrid
                    .padding(.top, 6)
            }
            // Matches Home's top padding so the year lines up with the date line.
            .padding(.top, 29)
            .padding(.horizontal, Metrics.gutter)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .center, spacing: 4) {
            Text(month.formatted(.dateTime.month(.wide)).lowercased())
                .font(.month)
                .foregroundStyle(Color.ink)
                .frame(height: 46)

            Spacer(minLength: 0)

            chevronButton(LineArt.chevronLeft, label: "Previous month", by: -1)
            chevronButton(LineArt.chevronRight, label: "Next month", by: 1)
        }
        // Lets the arrow drawings line up with the grid edge.
        .padding(.trailing, -10)
    }

    private func chevronButton(_ shape: SVGPathShape, label: String, by offset: Int) -> some View {
        Button {
            if let next = calendar.date(byAdding: .month, value: offset, to: month) {
                month = next
            }
        } label: {
            shape
                .stroke(Color.ink, style: .pen(Metrics.strokeLine))
                .frame(width: 22, height: 22)
                .frame(width: Metrics.tapTarget, height: Metrics.tapTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    // MARK: Grid

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    private var weekdayRow: some View {
        HStack(spacing: 0) {
            ForEach(Array(["S", "M", "T", "W", "T", "F", "S"].enumerated()), id: \.offset) { _, letter in
                Text(letter)
                    .font(.weekday)
                    .foregroundStyle(Color.inkMuted)
                    .frame(maxWidth: .infinity)
            }
        }
        .accessibilityHidden(true)
    }

    private var dayGrid: some View {
        let recorded = Set(recordings.map { calendar.startOfDay(for: $0.startedAt) })
        let today = calendar.startOfDay(for: .now)

        return LazyVGrid(columns: columns, spacing: 4) {
            ForEach(Array(cells.enumerated()), id: \.offset) { _, day in
                if let day {
                    DayCell(
                        date: day,
                        isToday: day == today,
                        isUpcoming: day > today,
                        hasRecording: recorded.contains(day),
                        onTap: { onSelectDay(day) }
                    )
                } else {
                    Color.clear.frame(height: Metrics.dayCell)
                }
            }
        }
    }

    /// Leading blanks for the days before the 1st, then each day of the month.
    private var cells: [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: month) else { return [] }
        let leading = (calendar.component(.weekday, from: month) - calendar.firstWeekday + 7) % 7
        let days = range.compactMap { calendar.date(byAdding: .day, value: $0 - 1, to: month) }
        return Array(repeating: nil, count: leading) + days
    }
}

private struct DayCell: View {
    let date: Date
    let isToday: Bool
    let isUpcoming: Bool
    let hasRecording: Bool
    let onTap: () -> Void

    var body: some View {
        if hasRecording {
            Button(action: onTap) { content }
                .buttonStyle(.plain)
                .accessibilityLabel(label)
        } else {
            content
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(label)
        }
    }

    private var content: some View {
        ZStack {
            if isToday {
                LineArt.todayCircle
                    .stroke(Color.ink, style: .pen(Metrics.strokeFine))
                    .frame(width: 40, height: 38)
            }

            Text(date, format: .dateTime.day())
                .font(isToday ? .dayToday : .day)
                .foregroundStyle(isUpcoming ? Color.inkFaint : Color.ink)
        }
        .frame(maxWidth: .infinity)
        .frame(height: Metrics.dayCell)
        .overlay(alignment: .bottom) {
            if hasRecording {
                Circle()
                    .fill(Color.ink)
                    .frame(width: Metrics.dayDot, height: Metrics.dayDot)
                    .padding(.bottom, 3)
            }
        }
        .contentShape(Rectangle())
    }

    private var label: String {
        var parts = [date.formatted(.dateTime.month(.wide).day())]
        if isToday { parts.append("today") }
        if hasRecording { parts.append("has recordings") }
        return parts.joined(separator: ", ")
    }
}

private extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        self.date(from: dateComponents([.year, .month], from: date)) ?? startOfDay(for: date)
    }
}

#Preview {
    CalendarView()
        .modelContainer(for: Recording.self, inMemory: true)
}
