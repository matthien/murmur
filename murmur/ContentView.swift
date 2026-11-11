import SwiftData
import SwiftUI

/// Home and Calendar side by side. A horizontal drag slides both screens,
/// and the bottom labels follow along with a sliding underline.
struct ContentView: View {
    @State private var page: Page = .home
    @State private var dragOffset: CGFloat = 0
    /// Decided on the first movement of each drag so vertical drags never swipe.
    @State private var dragIsHorizontal: Bool?
    /// Days pushed from the Calendar.
    @State private var dayPath: [Date] = []
    @State private var transcriptions = TranscriptionQueue()

    var body: some View {
        NavigationStack(path: $dayPath) {
            pages
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: Date.self) { day in
                    DayPager(day: day)
                }
        }
        .environment(transcriptions)
    }

    private var pages: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let progress = Self.progress(page: page, dragOffset: dragOffset, width: width)

            ZStack(alignment: .bottom) {
                HStack(spacing: 0) {
                    HomeView().frame(width: width)
                    CalendarView(onSelectDay: { dayPath.append($0) }).frame(width: width)
                }
                .frame(width: width, alignment: .leading)
                .offset(x: -CGFloat(page.rawValue) * width + dragOffset)

                PageLabels(progress: progress) { go(to: $0) }
                    // 36pt above the screen's bottom edge, never inside the safe area.
                    .padding(.bottom, max(0, 36 - geo.safeAreaInsets.bottom))
            }
            .contentShape(Rectangle())
            .simultaneousGesture(swipe(width: width))
        }
        .background(Color.paper.ignoresSafeArea())
    }

    // MARK: Swipe

    private func swipe(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                if dragIsHorizontal == nil {
                    dragIsHorizontal = abs(value.translation.width) > abs(value.translation.height)
                }
                guard dragIsHorizontal == true else { return }

                let dx = value.translation.width
                // Resist dragging past either end.
                let pastEdge = (page == .home && dx > 0) || (page == .calendar && dx < 0)
                dragOffset = pastEdge ? dx / 4 : dx
            }
            .onEnded { value in
                defer { dragIsHorizontal = nil }
                guard dragIsHorizontal == true else { return }

                let dx = value.translation.width
                let commit: CGFloat = 48
                let target: Page
                if page == .home, dx < -commit {
                    target = .calendar
                } else if page == .calendar, dx > commit {
                    target = .home
                } else {
                    // Settle on whichever screen is more than half visible.
                    let progress = Self.progress(page: page, dragOffset: dragOffset, width: width)
                    target = progress > 0.5 ? .calendar : .home
                }
                go(to: target)
            }
    }

    private func go(to target: Page) {
        withAnimation(.timingCurve(0.22, 1, 0.36, 1, duration: 0.32)) {
            page = target
            dragOffset = 0
        }
    }

    /// 0 when Home fills the screen, 1 when Calendar does.
    private static func progress(page: Page, dragOffset: CGFloat, width: CGFloat) -> CGFloat {
        guard width > 0 else { return CGFloat(page.rawValue) }
        let raw = (CGFloat(page.rawValue) * width - dragOffset) / width
        return min(max(raw, 0), 1)
    }
}

enum Page: Int, CaseIterable {
    case home, calendar

    var label: String {
        switch self {
        case .home: "record"
        case .calendar: "calendar"
        }
    }
}

/// The "record" and "calendar" labels, with an underline that slides between
/// them as the screens move.
private struct PageLabels: View {
    let progress: CGFloat
    let select: (Page) -> Void

    private var current: Page { progress < 0.5 ? .home : .calendar }

    var body: some View {
        GeometryReader { geo in
            let half = geo.size.width / 2

            HStack(spacing: 0) {
                ForEach(Page.allCases, id: \.self) { page in
                    Button { select(page) } label: {
                        Text(page.label)
                            .font(.tab)
                            .foregroundStyle(page == current ? Color.ink : Color.inkMuted)
                            .frame(width: half, height: Metrics.tapTarget)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(page == current ? .isSelected : [])
                }
            }
            .overlay(alignment: .bottomLeading) {
                LineArt.tabUnderline
                    .stroke(Color.ink, style: .pen(Metrics.strokeLine))
                    .frame(width: 64, height: 10)
                    // Centred under the "record" label, then travels one label width.
                    .offset(x: half / 2 - 32 + progress * half, y: 2)
                    .accessibilityHidden(true)
            }
        }
        .frame(height: Metrics.tapTarget)
        .padding(.horizontal, Metrics.gutter)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Recording.self, inMemory: true)
}
