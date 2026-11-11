import SwiftData
import SwiftUI

/// Pages horizontally between days that have recordings, earliest on the left.
/// Opens on the day tapped in the Calendar.
struct DayPager: View {
    let initialDay: Date

    @Query private var recordings: [Recording]

    init(day: Date) {
        initialDay = CalendarView.calendar.startOfDay(for: day)
    }

    private var days: [Date] {
        let calendar = CalendarView.calendar
        var days = Set(recordings.map { calendar.startOfDay(for: $0.startedAt) })
        days.insert(initialDay)
        return days.sorted()
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    ForEach(days, id: \.self) { day in
                        DayView(day: day)
                            .containerRelativeFrame(.horizontal)
                            .id(day)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollIndicators(.hidden)
            .onAppear { proxy.scrollTo(initialDay) }
        }
        .background(Color.paper.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }
}
