import SwiftUI

struct CampaignListView: View {
    @EnvironmentObject var campaignViewModel: CampaignViewModel
    @State private var showCreateSheet = false
    @State private var editingCampaign: Campaign? = nil
    @State private var sendConfirmationCampaign: Campaign? = nil

    var body: some View {
        NavigationView {
            ZStack {
                Theme.screenBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    campaignFilterChips

                    if campaignViewModel.isLoading && campaignViewModel.campaigns.isEmpty {
                        Spacer()
                        ProgressView().scaleEffect(1.1)
                        Spacer()
                    } else if campaignViewModel.filteredCampaigns.isEmpty {
                        EmptyStateView(
                            icon: "megaphone",
                            message: "Nenhuma campanha",
                            subtitle: "Crie sua primeira campanha"
                        )
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 10) {
                                ForEach(campaignViewModel.filteredCampaigns) { campaign in
                                    CampaignCardView(
                                        campaign: campaign,
                                        segmentName: campaignViewModel.segmentName(for: campaign.segmentId),
                                        onSend: { sendConfirmationCampaign = campaign },
                                        onEdit: { editingCampaign = campaign }
                                    )
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                        }
                        .refreshable {
                            await campaignViewModel.fetchCampaigns()
                        }
                    }
                }
                .navigationTitle("Campanhas")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showCreateSheet = true }) {
                            HStack(spacing: 4) {
                                Image(systemName: "plus")
                                    .font(.system(size: 12, weight: .semibold))
                                Text("Nova")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Theme.primaryGradient)
                            .cornerRadius(Theme.cornerMD)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            CreateCampaignSheet()
                .environmentObject(campaignViewModel)
        }
        .sheet(item: $editingCampaign) { campaign in
            CreateCampaignSheet(editingCampaign: campaign)
                .environmentObject(campaignViewModel)
        }
        .alert("Enviar Campanha?", isPresented: Binding(
            get: { sendConfirmationCampaign != nil },
            set: { if !$0 { sendConfirmationCampaign = nil } }
        )) {
            Button("Cancelar", role: .cancel) {}
            Button("Enviar") {
                if let campaign = sendConfirmationCampaign {
                    Task { await campaignViewModel.sendCampaign(id: campaign.id) }
                }
            }
        } message: {
            Text("Enviar a campanha \"\(sendConfirmationCampaign?.name ?? "")\" agora?")
        }
        .task {
            await campaignViewModel.fetchSegments()
            await campaignViewModel.fetchCampaigns()
        }
    }

    private var campaignFilterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(CampaignFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.rawValue,
                        isSelected: campaignViewModel.selectedFilter == filter
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            campaignViewModel.selectedFilter = filter
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }
}

struct CampaignCardView: View {
    let campaign: Campaign
    var segmentName: String = "-"
    var onSend: () -> Void
    var onEdit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(campaign.isSent ? "ENVIADA" : "RASCUNHO")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(campaign.isSent ? Theme.success : Theme.warning)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background((campaign.isSent ? Theme.success : Theme.warning).opacity(0.1))
                        .cornerRadius(10)

                    Text(campaign.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)

                    Text("Segmento: \(segmentName)")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }

                Spacer()

                if campaign.isSent, let count = campaign.messageCount {
                    VStack(spacing: 0) {
                        Text("\(count)")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(Theme.primary)
                        Text("enviadas")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(16)

            if campaign.isSent {
                Divider().padding(.horizontal, 16)
                HStack {
                    if let sentAt = campaign.sentAt {
                        Text("Enviada em \(sentAt.formatted(date: .numeric, time: .omitted))")
                    }
                    Spacer()
                    if let sentBy = campaign.sentBy {
                        Text("por \(sentBy)")
                    }
                }
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }

            if campaign.isDraft {
                Divider().padding(.horizontal, 16)
                HStack(spacing: 8) {
                    Button(action: onSend) {
                        Text("Enviar Agora")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(10)
                            .background(Theme.primaryGradient)
                            .cornerRadius(10)
                    }
                    Button(action: onEdit) {
                        Text("Editar")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(10)
                            .background(Color(UIColor.tertiarySystemFill))
                            .cornerRadius(10)
                    }
                }
                .padding(16)
            }
        }
        .background(Color(UIColor.systemBackground))
        .cornerRadius(Theme.cornerMD)
        .overlay(
            campaign.isDraft ?
                HStack {
                    Rectangle().fill(Theme.warning).frame(width: 3)
                    Spacer()
                }
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerMD))
                : nil
        )
        .modifier(CardShadow())
    }
}

extension Campaign: Hashable {
    static func == (lhs: Campaign, rhs: Campaign) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
