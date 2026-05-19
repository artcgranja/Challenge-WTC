import SwiftUI

struct ComposeMessageSheet: View {
    @EnvironmentObject var campaignViewModel: CampaignViewModel
    @EnvironmentObject var crmViewModel: CRMViewModel
    @Environment(\.dismiss) private var dismiss

    var preselectedRecipientId: String? = nil
    var preselectedRecipientName: String? = nil

    @State private var recipientMode = 0
    @State private var recipientId = ""
    @State private var recipientName = ""
    @State private var selectedSegment: Segment? = nil
    @State private var messageTitle = ""
    @State private var messageBody = ""
    @State private var showImageField = false
    @State private var imageUrl = ""
    @State private var isSending = false
    @State private var showSegmentPicker = false
    @State private var showCustomerPicker = false

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
                        if preselectedRecipientName != nil {
                            HStack {
                                Image(systemName: "person.fill")
                                    .foregroundColor(Theme.primary)
                                Text(preselectedRecipientName!)
                                    .font(.system(size: 14, weight: .medium))
                                Spacer()
                            }
                            .padding(12)
                            .background(Color(red: 0.97, green: 0.98, blue: 0.99))
                            .cornerRadius(Theme.cornerSM)
                        } else {
                            Button(action: { showCustomerPicker = true }) {
                                HStack {
                                    Image(systemName: "person.fill")
                                        .foregroundColor(recipientId.isEmpty ? .secondary : Theme.primary)
                                    Text(recipientName.isEmpty ? "Selecionar cliente..." : recipientName)
                                        .font(.system(size: 14))
                                        .foregroundColor(recipientName.isEmpty ? .secondary : .primary)
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
        .modifier(LargeDetent())
        .sheet(isPresented: $showSegmentPicker) {
            SegmentPickerView(segments: campaignViewModel.segments, selectedSegment: $selectedSegment)
        }
        .sheet(isPresented: $showCustomerPicker) {
            CustomerPickerView(customers: crmViewModel.customers) { customer in
                recipientId = customer.userId
                recipientName = customer.displayName
            }
        }
        .onAppear {
            if preselectedRecipientId != nil {
                recipientMode = 0
            }
            Task {
                await campaignViewModel.fetchSegments()
                if crmViewModel.customers.isEmpty {
                    await crmViewModel.fetchCustomers()
                }
            }
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

// MARK: - Customer Picker

struct CustomerPickerView: View {
    let customers: [Customer]
    var onSelect: (Customer) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List(customers) { customer in
                Button(action: {
                    onSelect(customer)
                    dismiss()
                }) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Theme.primaryGradient)
                                .frame(width: 36, height: 36)
                            Text(customer.initials)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(customer.displayName)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.primary)
                            if let email = customer.email {
                                Text(email)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                    }
                }
            }
            .navigationTitle("Selecionar Cliente")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
    }
}

// MARK: - iOS 15 Compatibility

struct LargeDetent: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content.presentationDetents([.large])
        } else {
            content
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
                    .onAppear {
                        UITextView.appearance().backgroundColor = .clear
                    }
            }
        }
        .padding(12)
        .background(Color(red: 0.97, green: 0.98, blue: 0.99))
        .cornerRadius(Theme.cornerSM)
        .overlay(RoundedRectangle(cornerRadius: Theme.cornerSM).stroke(Color(red: 0.89, green: 0.91, blue: 0.94), lineWidth: 1))
    }
}
