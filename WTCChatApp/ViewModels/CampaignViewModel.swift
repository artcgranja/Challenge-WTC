import Foundation
import SwiftUI
import Combine

enum CampaignFilter: String, CaseIterable {
    case all = "Todas"
    case draft = "Rascunho"
    case sent = "Enviadas"
}

@MainActor
class CampaignViewModel: ObservableObject {
    @Published var campaigns: [Campaign] = []
    @Published var filteredCampaigns: [Campaign] = []
    @Published var segments: [Segment] = []
    @Published var sentMessages: [Message] = []
    @Published var filteredSentMessages: [Message] = []
    @Published var selectedFilter: CampaignFilter = .all
    @Published var messageFilter: MessagesViewModel.MessageFilter = .all
    @Published var messageSearchText = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let apiService = APIService.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        setupCampaignFilter()
        setupMessageFilter()
    }

    private func setupCampaignFilter() {
        Publishers.CombineLatest($campaigns, $selectedFilter)
            .map { campaigns, filter -> [Campaign] in
                switch filter {
                case .all: return campaigns
                case .draft: return campaigns.filter { $0.isDraft }
                case .sent: return campaigns.filter { $0.isSent }
                }
            }
            .assign(to: &$filteredCampaigns)
    }

    private func setupMessageFilter() {
        Publishers.CombineLatest3($sentMessages, $messageSearchText, $messageFilter)
            .map { messages, search, filter -> [Message] in
                var filtered = messages

                switch filter {
                case .chat: filtered = filtered.filter { $0.type == .chat }
                case .campaign: filtered = filtered.filter { $0.type == .campaign }
                default: break
                }

                if !search.isEmpty {
                    filtered = filtered.filter { message in
                        message.content.title.localizedCaseInsensitiveContains(search) ||
                        message.content.body.localizedCaseInsensitiveContains(search)
                    }
                }

                return filtered
            }
            .assign(to: &$filteredSentMessages)
    }

    func fetchCampaigns() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            campaigns = try await apiService.fetchCampaigns()
        } catch {
            errorMessage = "Erro ao carregar campanhas: \(error.localizedDescription)"
        }
    }

    func fetchSegments() async {
        do {
            segments = try await apiService.fetchSegments()
        } catch {
            errorMessage = "Erro ao carregar segmentos: \(error.localizedDescription)"
        }
    }

    func fetchSentMessages() async {
        do {
            sentMessages = try await apiService.fetchSentMessages()
        } catch {
            errorMessage = "Erro ao carregar mensagens: \(error.localizedDescription)"
        }
    }

    func createCampaign(name: String, segmentId: String, content: MessageContent, deeplink: String?) async -> Campaign? {
        isLoading = true
        defer { isLoading = false }

        do {
            let campaign = try await apiService.createCampaign(name: name, segmentId: segmentId, content: content, deeplink: deeplink)
            await fetchCampaigns()
            return campaign
        } catch {
            errorMessage = "Erro ao criar campanha: \(error.localizedDescription)"
            return nil
        }
    }

    func sendCampaign(id: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let _ = try await apiService.sendCampaign(id: id)
            await fetchCampaigns()
        } catch {
            errorMessage = "Erro ao enviar campanha: \(error.localizedDescription)"
        }
    }

    func sendMessage(type: String = "chat", recipientId: String? = nil, segmentTags: [String]? = nil, content: MessageContent) async -> Bool {
        isLoading = true
        defer { isLoading = false }

        do {
            let _ = try await apiService.sendOperatorMessage(type: type, recipientId: recipientId, segmentTags: segmentTags, content: content)
            return true
        } catch {
            errorMessage = "Erro ao enviar mensagem: \(error.localizedDescription)"
            return false
        }
    }
}
