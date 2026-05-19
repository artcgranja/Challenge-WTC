import SwiftUI

struct ComposeMessageSheet: View {
    @EnvironmentObject var campaignViewModel: CampaignViewModel
    @Environment(\.dismiss) private var dismiss

    var preselectedRecipientId: String? = nil
    var preselectedRecipientName: String? = nil

    @State private var recipientMode = 0
    @State private var recipientId = ""
    @State private var selectedSegment: Segment? = nil
    @State private var messageTitle = ""
    @State private var messageBody = ""
    @State private var showImageField = false
    @State private var imageUrl = ""
    @State private var isSending = false
    @State private var showSegmentPicker = false

    var canSend: Bool {
        !messageTitle.isEmpty && !messageBody.isEmpty &&
        (recipientMode == 0 ? !(preselectedRecipientId ?? recipientId).isEmpty : selectedSegment != nil)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    Text("Nova Mensagem")
                        .font(.system(size: 18, weight: .bold))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if preselectedRecipientId == nil {
                        Picker("", selection: $recipientMode) {
                            Text("Cliente").tag(0)
                            Text("Segmento").tag(1)
                        }
                        .pickerStyle(.segmented)
                    }

                    if recipientMode == 0 {
                        if let name = preselectedRecipientName {
                            HStack {
                                Image(systemName: "person.fill")
                                    .foregroundColor(Theme.primary)
                                Text(name)
                                    .font(.system(size: 14, weight: .medium))
                                Spacer()
                            }
                            .padding(12)
                            .background(Color(red: 0.97, green: 0.98, blue: 0.99))
                            .cornerRadius(Theme.cornerSM)
                        }
                    } else {
                        Button(action: { showSegmentPicker = true }) {
                            HStack {
                                Text(selectedSegment?.name ?? "Selecionar segmento...")
                                    .font(.system(size: 14))
                                    .foregroundColor(selectedSegment != nil ? .primary : .secondary)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.secondary)
                            }
                            .padding(12)
                            .background(Color(red: 0.97, green: 0.98, blue: 0.99))
                            .cornerRadius(Theme.cornerSM)
                            .overlay(RoundedRectangle(cornerRadius: Theme.cornerSM).stroke(Color(red: 0.89, green: 0.91, blue: 0.94), lineWidth: 1))
                        }
                    }

                    LabeledField(label: "Título", text: $messageTitle, placeholder: "Título da mensagem")
                    LabeledTextEditor(label: "Mensagem", text: $messageBody, placeholder: "Escreva sua mensagem...")

                    HStack(spacing: 8) {
                        Button(action: { withAnimation { showImageField.toggle() } }) {
                            HStack(spacing: 4) {
                                Image(systemName: "photo")
                                    .font(.system(size: 12))
                                Text("Imagem")
                                    .font(.system(size: 12))
                            }
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(UIColor.tertiarySystemFill))
                            .cornerRadius(Theme.cornerSM)
                        }
                    }

                    if showImageField {
                        LabeledField(label: "URL da imagem", text: $imageUrl, placeholder: "https://...")
                    }

                    Button(action: { Task { await send() } }) {
                        HStack {
                            if isSending {
                                ProgressView().tint(.white)
                            } else {
                                Text("Enviar Mensagem")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(canSend && !isSending ? Theme.primaryGradient : LinearGradient(colors: [.gray], startPoint: .leading, endPoint: .trailing))
                        .cornerRadius(Theme.cornerMD)
                    }
                    .disabled(!canSend || isSending)
                }
                .padding(16)
            }
            .navigationBarHidden(true)
        }
        .presentationDetents([.large])
        .sheet(isPresented: $showSegmentPicker) {
            SegmentPickerView(segments: campaignViewModel.segments, selectedSegment: $selectedSegment)
        }
        .onAppear {
            if preselectedRecipientId != nil {
                recipientMode = 0
            }
            Task { await campaignViewModel.fetchSegments() }
        }
    }

    private func send() async {
        isSending = true
        defer { isSending = false }

        let content = MessageContent(
            title: messageTitle,
            body: messageBody,
            imageUrl: imageUrl.isEmpty ? nil : imageUrl
        )

        let success: Bool
        if recipientMode == 0 {
            let rid = preselectedRecipientId ?? recipientId
            success = await campaignViewModel.sendMessage(type: "chat", recipientId: rid, content: content)
        } else {
            let tags = selectedSegment?.tags ?? []
            success = await campaignViewModel.sendMessage(type: "chat", segmentTags: tags, content: content)
        }

        if success {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            dismiss()
        }
    }
}

// MARK: - Reusable Form Fields

struct LabeledField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            TextField(placeholder, text: $text)
                .font(.system(size: 14))
        }
        .padding(12)
        .background(Color(red: 0.97, green: 0.98, blue: 0.99))
        .cornerRadius(Theme.cornerSM)
        .overlay(RoundedRectangle(cornerRadius: Theme.cornerSM).stroke(Color(red: 0.89, green: 0.91, blue: 0.94), lineWidth: 1))
    }
}

struct LabeledTextEditor: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary.opacity(0.5))
                        .padding(.top, 8)
                        .padding(.leading, 4)
                }
                TextEditor(text: $text)
                    .font(.system(size: 14))
                    .frame(minHeight: 80)
                    .scrollContentBackground(.hidden)
            }
        }
        .padding(12)
        .background(Color(red: 0.97, green: 0.98, blue: 0.99))
        .cornerRadius(Theme.cornerSM)
        .overlay(RoundedRectangle(cornerRadius: Theme.cornerSM).stroke(Color(red: 0.89, green: 0.91, blue: 0.94), lineWidth: 1))
    }
}
