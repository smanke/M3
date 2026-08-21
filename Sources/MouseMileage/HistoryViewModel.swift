import Combine
import Foundation

/// Feeds the mileage charts shown in the menu bar dropdown.
final class HistoryViewModel: ObservableObject {
    @Published var byHour: [MileageHistoryStore.Bucket] = []
    @Published var byDay: [MileageHistoryStore.Bucket] = []
    @Published var yearToDate: [MileageHistoryStore.Bucket] = []

    init() {
        refresh()
    }

    func refresh() {
        let history = MileageHistoryStore.shared
        byHour = history.todayByHour()
        byDay = history.last7Days()
        yearToDate = history.yearToDate()
    }
}
