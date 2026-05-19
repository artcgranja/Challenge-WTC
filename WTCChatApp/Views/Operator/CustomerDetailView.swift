import SwiftUI

struct CustomerDetailView: View {
    let customer: Customer
    @EnvironmentObject var crmViewModel: CRMViewModel
    @EnvironmentObject var campaignViewModel: CampaignViewModel
    @State private var showComposeSheet = false
    @State private var showNoteAlert = false
    @State private var noteText = ""

    var body: some View {
        ZStack {
            Theme.screenBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    profileCard
                    timelineSection
                }
                .padding(16)
                .padding(.bottom, 80)
            }
            .refreshable {
                await crmViewModel.fetchTimeline(customerId: customer.id)
            }

            VStack {
                Spacer()
                Button(action: { showNoteAlert = true }) {
                    HStack {
                        Image(systemName: "plus")
                            .font(.system(size: 15, weight: .semibold))
                        Text("Adicionar Nota")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(Theme.primaryGradient)
                    .cornerRadius(Theme.cornerMD)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .navigationTitle(customer.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showComposeSheet = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 12))
                        Text("Enviar")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Theme.primaryGradient)
                    .cornerRadius(Theme.cornerLG)
                }
            }
        }
        .sheet(isPresented: $showComposeSheet) {
            ComposeMessageSheet(preselectedRecipientId: customer.userId, preselectedRecipientName: customer.displayName)
                .environmentObject(campaignViewModel)
        }
        .alert("Adicionar Nota", isPresented: $showNoteAlert) {
            TextField("Escreva sua nota...", text: $noteText)
            Button("Cancelar", role: .cancel) { noteText = "" }
            Button("Salvar") {
                let text = noteText
                noteText = ""
                Task { await crmViewModel.addNote(customerId: customer.id, text: text) }
            }
        }
        .task {
            await crmViewModel.fetchTimeline(customerId: customer.id)
        }
    }

    private var profileCard: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Theme.primaryGradient)
                    .frame(width: 72, height: 72)
                Text(customer.initials)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
            }

            Text(customer.displayName)
                .font(.system(size: 20, weight: .bold))
            if let email = customer.email {
                Text(email)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 6) {
                ForEach(customer.tags, id: \.self) { tag in
                    Text(tag)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(Theme.primary.opacity(0.1))
                        .cornerRadius(10)
                }
            }

            Divider().padding(.top, 4)

            HStack {
                statItem(value: "\(customer.score)", label: "Score", color: customer.scoreColor)
                Spacer()
                statItem(
                    value: "\(crmViewModel.timeline.filter { if case .message = $0 { return true }; return false }.count)",
                    label: "Mensagens",
                    color: Theme.primary
                )
                Spacer()
                statItem(
                    value: "\(crmViewModel.timeline.filter { if case .note = $0 { return true }; return false }.count)",
                    label: "Notas",
                    color: Theme.warning
                )
            }
            .padding(.horizontal, 8)
        }
        .padding(20)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(Theme.cornerMD)
        .modifier(CardShadow())
    }

    private func statItem(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
    }

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Timeline")
                .font(.system(size: 16, weight: .semibold))
                .padding(.horizontal, 4)

            if crmViewModel.isLoadingTimeline {
                HStack { Spacer(); ProgressView(); Spacer() }
                    .padding(.top, 20)
            } else if crmViewModel.timeline.isEmpty {
                EmptyStateView(icon: "clock", message: "Nenhuma atividade", subtitle: "A timeline do cliente aparecerá aqui")
                    .frame(height: 200)
            } else {
                ForEach(crmViewModel.timeline) { entry in
                    TimelineItemView(entry: entry)
                }
            }
        }
    }
}

struct TimelineItemView: View {
    let entry: TimelineEntry

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(entry.iconColor.opacity(0.1))
                    .frame(width: 32, height: 32)
                Image(systemName: entry.icon)
                    .font(.system(size: 14))
                    .foregroundColor(entry.iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
                Text(entry.subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                Text(entry.date.timeAgo())
                    .font(.system(size: 11))
                    .foregroundColor(.secondary.opacity(0.7))
                    .padding(.top, 2)
            }

            Spacer()
        }
        .padding(14)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(Theme.cornerMD)
        .modifier(CardShadow())
    }
}
