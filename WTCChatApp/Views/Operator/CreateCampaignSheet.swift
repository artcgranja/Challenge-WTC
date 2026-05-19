import SwiftUI

struct CreateCampaignSheet: View {
    @EnvironmentObject var campaignViewModel: CampaignViewModel
    @Environment(\.dismiss) private var dismiss

    var editingCampaign: Campaign? = nil

    @State private var name = ""
    @State private var selectedSegment: Segment? = nil
    @State private var messageTitle = ""
    @State private var messageBody = ""
    @State private var deeplink = ""
    @State private var isSaving = false
    @State private var showSegmentPicker = false
    @State private var showSendConfirmation = false

    var canSave: Bool {
        !name.isEmpty && selectedSegment != nil && !messageTitle.isEmpty && !messageBody.isEmpty
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    Text("Nova Campanha")
                        .font(.system(size: 18, weight: .bold))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    LabeledField(label: "Nome da campanha", text: $name, placeholder: "Ex: Black Friday 2026")

                    Button(action: { showSegmentPicker = true }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Segmento")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                                Text(selectedSegment?.name ?? "Selecionar segmento...")
                                    .font(.system(size: 14))
                                    .foregroundColor(selectedSegment != nil ? .primary : .secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.secondary)
                        }
                        .padding(12)
                        .background(Color(red: 0.97, green: 0.98, blue: 0.99))
                        .cornerRadius(Theme.cornerSM)
                        .overlay(RoundedRectangle(cornerRadius: Theme.cornerSM).stroke(Color(red: 0.89, green: 0.91, blue: 0.94), lineWidth: 1))
                    }

                    LabeledField(label: "Título da mensagem", text: $messageTitle, placeholder: "Título que o cliente verá")
                    LabeledTextEditor(label: "Corpo da mensagem", text: $messageBody, placeholder: "Escreva o conteúdo da campanha...")
                    LabeledField(label: "Deeplink (opcional)", text: $deeplink, placeholder: "deeplink://products")

                    HStack(spacing: 10) {
                        Button(action: { Task { await saveDraft() } }) {
                            HStack {
                                if isSaving {
                                    ProgressView().tint(.secondary)
                                } else {
                                    Text("Salvar Rascunho")
                                        .font(.system(size: 14, weight: .semibold))
                                }
                            }
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(14)
                            .background(Color(UIColor.tertiarySystemFill))
                            .cornerRadius(Theme.cornerMD)
                        }
                        .disabled(!canSave || isSaving)

                        Button(action: { showSendConfirmation = true }) {
                            Text("Criar e Enviar")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(14)
                                .background(canSave && !isSaving ? Theme.campaignGradient : LinearGradient(colors: [.gray], startPoint: .leading, endPoint: .trailing))
                                .cornerRadius(Theme.cornerMD)
                        }
                        .disabled(!canSave || isSaving)
                    }
                }
                .padding(16)
            }
            .navigationBarHidden(true)
        }
        .presentationDetents([.large])
        .sheet(isPresented: $showSegmentPicker) {
            SegmentPickerView(segments: campaignViewModel.segments, selectedSegment: $selectedSegment)
        }
        .alert("Enviar Campanha?", isPresented: $showSendConfirmation) {
            Button("Cancelar", role: .cancel) {}
            Button("Enviar") { Task { await createAndSend() } }
        } message: {
            Text("A campanha será enviada imediatamente para o segmento \"\(selectedSegment?.name ?? "")\".")
        }
        .onAppear {
            Task { await campaignViewModel.fetchSegments() }
            if let campaign = editingCampaign {
                name = campaign.name
                messageTitle = campaign.content.title
                messageBody = campaign.content.body
                deeplink = campaign.deeplink ?? ""
            }
        }
    }

    private func saveDraft() async {
        guard let segmentId = selectedSegment?.id else { return }
        isSaving = true
        defer { isSaving = false }

        let content = MessageContent(title: messageTitle, body: messageBody)
        let _ = await campaignViewModel.createCampaign(
            name: name, segmentId: segmentId, content: content,
            deeplink: deeplink.isEmpty ? nil : deeplink
        )
        dismiss()
    }

    private func createAndSend() async {
        guard let segmentId = selectedSegment?.id else { return }
        isSaving = true
        defer { isSaving = false }

        let content = MessageContent(title: messageTitle, body: messageBody)
        if let campaign = await campaignViewModel.createCampaign(
            name: name, segmentId: segmentId, content: content,
            deeplink: deeplink.isEmpty ? nil : deeplink
        ) {
            await campaignViewModel.sendCampaign(id: campaign.id)
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        dismiss()
    }
}
