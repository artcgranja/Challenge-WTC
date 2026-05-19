import Foundation
import SwiftUI
import Combine

@MainActor
class CRMViewModel: ObservableObject {
    @Published var customers: [Customer] = []
    @Published var filteredCustomers: [Customer] = []
    @Published var searchText = ""
    @Published var selectedTagFilter: String? = nil
    @Published var isLoading = false
    @Published var errorMessage: String?

    @Published var timeline: [TimelineEntry] = []
    @Published var isLoadingTimeline = false

    private let apiService = APIService.shared
    private var cancellables = Set<AnyCancellable>()

    var availableTags: [String] {
        Array(Set(customers.flatMap { $0.tags })).sorted()
    }

    init() {
        setupSearchAndFilter()
    }

    private func setupSearchAndFilter() {
        Publishers.CombineLatest3($customers, $searchText, $selectedTagFilter)
            .map { customers, search, tagFilter -> [Customer] in
                var filtered = customers

                if let tag = tagFilter {
                    filtered = filtered.filter { $0.tags.contains(tag) }
                }

                if !search.isEmpty {
                    filtered = filtered.filter { customer in
                        (customer.fullName ?? "").localizedCaseInsensitiveContains(search) ||
                        (customer.email ?? "").localizedCaseInsensitiveContains(search)
                    }
                }

                return filtered
            }
            .assign(to: &$filteredCustomers)
    }

    func fetchCustomers() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            customers = try await apiService.fetchCustomers()
        } catch {
            errorMessage = "Erro ao carregar clientes: \(error.localizedDescription)"
        }
    }

    func fetchTimeline(customerId: String) async {
        isLoadingTimeline = true
        defer { isLoadingTimeline = false }

        do {
            let response = try await apiService.fetchTimeline(customerId: customerId)
            var entries: [TimelineEntry] = response.messages.map { .message($0) }
            if let notes = response.notes {
                entries.append(contentsOf: notes.map { .note($0) })
            }
            timeline = entries.sorted { $0.date > $1.date }
        } catch {
            errorMessage = "Erro ao carregar timeline: \(error.localizedDescription)"
        }
    }

    func addNote(customerId: String, text: String) async {
        do {
            try await apiService.addNote(customerId: customerId, text: text)
            await fetchTimeline(customerId: customerId)
        } catch {
            errorMessage = "Erro ao adicionar nota: \(error.localizedDescription)"
        }
    }
}
