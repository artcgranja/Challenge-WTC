import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showLogoutAlert = false

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    // Profile Header Card
                    VStack(spacing: 18) {
                        // Avatar
                        ZStack {
                            if let avatarUrl = authViewModel.currentProfile?.avatarUrl,
                               let url = URL(string: avatarUrl) {
                                AsyncImage(url: url, transaction: Transaction(animation: .easeInOut)) { phase in
                                    switch phase {
                                    case .empty:
                                        initialsView
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .transition(.opacity)
                                    case .failure:
                                        initialsView
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                                .frame(width: Theme.avatarLG, height: Theme.avatarLG)
                                .clipShape(Circle())
                            } else {
                                initialsView
                            }
                        }
                        .overlay(
                            Circle()
                                .stroke(Theme.primaryGradient, lineWidth: 3)
                                .frame(width: Theme.avatarLG + 6, height: Theme.avatarLG + 6)
                        )
                        .modifier(ElevatedShadow())

                        VStack(spacing: 6) {
                            Text(authViewModel.currentProfile?.fullName ?? "Usuário")
                                .font(.title2)
                                .fontWeight(.bold)

                            Text(authViewModel.currentProfile?.email ?? "")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        // Status badge
                        HStack(spacing: 6) {
                            Circle()
                                .fill(statusColor)
                                .frame(width: 8, height: 8)

                            Text(statusText)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(statusColor)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(statusColor.opacity(0.1))
                        .cornerRadius(Theme.cornerLG)
                    }
                    .padding(.vertical, 24)
                    .frame(maxWidth: .infinity)
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(Theme.cornerLG)
                    .modifier(CardShadow())

                    // Info Section
                    VStack(spacing: 2) {
                        if let phone = authViewModel.currentProfile?.phone {
                            ProfileInfoRow(
                                icon: "phone.fill",
                                label: "Telefone",
                                value: phone,
                                iconColor: Theme.success
                            )
                        }

                        if let tags = authViewModel.currentProfile?.tags, !tags.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 8) {
                                    Image(systemName: "tag.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(Theme.primary)
                                        .frame(width: 30)
                                    Text("Tags")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(tags, id: \.self) { tag in
                                            TagView(tag: tag)
                                        }
                                    }
                                }
                            }
                            .padding(16)
                            .background(Color(UIColor.systemBackground))
                        }

                        if let createdAt = authViewModel.currentProfile?.createdAt {
                            ProfileInfoRow(
                                icon: "calendar",
                                label: "Membro desde",
                                value: createdAt.formatted(date: .long, time: .omitted),
                                iconColor: Theme.warning
                            )
                        }
                    }
                    .cornerRadius(Theme.cornerMD)
                    .modifier(CardShadow())

                    // Actions
                    VStack(spacing: 10) {
                        Button(action: {
                            Task { await authViewModel.refreshProfile() }
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 15, weight: .semibold))
                                Text("Atualizar Perfil")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(Theme.primary.opacity(0.1))
                            .foregroundColor(Theme.primary)
                            .cornerRadius(Theme.cornerMD)
                        }

                        Button(action: { showLogoutAlert = true }) {
                            HStack(spacing: 10) {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.system(size: 15, weight: .semibold))
                                Text("Sair")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(Theme.danger.opacity(0.08))
                            .foregroundColor(Theme.danger)
                            .cornerRadius(Theme.cornerMD)
                        }
                    }

                    // App info
                    VStack(spacing: 4) {
                        Text(Constants.appName)
                            .font(.footnote)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)

                        Text("Versão 1.0.0")
                            .font(.caption2)
                            .foregroundColor(.secondary.opacity(0.6))
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .background(Theme.screenBackground)
            .navigationTitle("Perfil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Text("Fechar").fontWeight(.medium)
                    }
                }
            }
            .alert("Sair", isPresented: $showLogoutAlert) {
                Button("Cancelar", role: .cancel) {}
                Button("Sair", role: .destructive) {
                    Task { await authViewModel.signOut() }
                }
            } message: {
                Text("Tem certeza que deseja sair?")
            }
        }
    }

    private var initials: String {
        guard let fullName = authViewModel.currentProfile?.fullName else { return "?" }
        let components = fullName.split(separator: " ")
        if components.count >= 2 {
            return "\(components[0].prefix(1))\(components[1].prefix(1))".uppercased()
        } else if let first = components.first {
            return String(first.prefix(1)).uppercased()
        }
        return "?"
    }

    private var statusColor: Color {
        guard let status = authViewModel.currentProfile?.status else { return .gray }
        switch status {
        case "active": return Theme.success
        case "inactive": return .gray
        case "pending": return Theme.warning
        default: return .gray
        }
    }

    private var initialsView: some View {
        ZStack {
            Circle()
                .fill(Theme.primaryGradient)
                .frame(width: Theme.avatarLG, height: Theme.avatarLG)

            Text(initials)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
    }

    private var statusText: String {
        guard let status = authViewModel.currentProfile?.status else { return "Desconhecido" }
        switch status {
        case "active": return "Ativo"
        case "inactive": return "Inativo"
        case "pending": return "Pendente"
        default: return status.capitalized
        }
    }
}

// MARK: - Profile Info Row

struct ProfileInfoRow: View {
    let icon: String
    let label: String
    let value: String
    var iconColor: Color = Theme.primary

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(value)
                    .font(.body)
                    .fontWeight(.medium)
            }

            Spacer()
        }
        .padding(16)
        .background(Color(UIColor.systemBackground))
    }
}

// MARK: - Tag View

struct TagView: View {
    let tag: String

    var body: some View {
        Text(tag)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(Theme.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Theme.primary.opacity(0.1))
            .cornerRadius(Theme.cornerLG)
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(AuthViewModel())
    }
}
