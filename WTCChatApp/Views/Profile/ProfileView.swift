//
//  ProfileView.swift
//  WTCChatApp
//
//  Created by WTC Challenge
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showLogoutAlert = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Profile Header
                    VStack(spacing: 16) {
                        // Avatar
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
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.blue, Color.purple]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 3
                                    )
                            )
                            .shadow(radius: 10)
                        } else {
                            initialsView
                                .shadow(radius: 10)
                        }

                        // Name
                        Text(authViewModel.currentProfile?.fullName ?? "Usuário")
                            .font(.title2)
                            .fontWeight(.bold)

                        // Email
                        Text(authViewModel.currentProfile?.email ?? "")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        // Status badge
                        HStack {
                            Circle()
                                .fill(statusColor)
                                .frame(width: 8, height: 8)

                            Text(statusText)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(20)
                    }
                    .padding(.top, 20)

                    // Profile Info
                    VStack(spacing: 16) {
                        // Phone
                        if let phone = authViewModel.currentProfile?.phone {
                            ProfileInfoRow(
                                icon: "phone.fill",
                                label: "Telefone",
                                value: phone
                            )
                        }

                        // Tags
                        if let tags = authViewModel.currentProfile?.tags, !tags.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "tag.fill")
                                        .foregroundColor(.blue)
                                    Text("Tags")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(tags, id: \.self) { tag in
                                            TagView(tag: tag)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.vertical, 8)
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(12)
                        }

                        // Created date
                        if let createdAt = authViewModel.currentProfile?.createdAt {
                            ProfileInfoRow(
                                icon: "calendar",
                                label: "Membro desde",
                                value: createdAt.formatted(date: .long, time: .omitted)
                            )
                        }
                    }
                    .padding(.horizontal)

                    // Actions
                    VStack(spacing: 12) {
                        // Refresh profile button
                        Button(action: {
                            Task {
                                await authViewModel.refreshProfile()
                            }
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Atualizar Perfil")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(12)
                        }

                        // Logout button
                        Button(action: {
                            showLogoutAlert = true
                        }) {
                            HStack {
                                Image(systemName: "arrow.right.square")
                                Text("Sair")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .foregroundColor(.red)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)

                    // App info
                    VStack(spacing: 4) {
                        Text(Constants.appName)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("Versão 1.0.0")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Perfil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fechar") {
                        dismiss()
                    }
                }
            }
            .alert("Sair", isPresented: $showLogoutAlert) {
                Button("Cancelar", role: .cancel) {}
                Button("Sair", role: .destructive) {
                    Task {
                        await authViewModel.signOut()
                    }
                }
            } message: {
                Text("Tem certeza que deseja sair?")
            }
        }
    }

    private var initials: String {
        guard let fullName = authViewModel.currentProfile?.fullName else {
            return "?"
        }

        let components = fullName.split(separator: " ")
        if components.count >= 2 {
            let first = components[0].prefix(1)
            let last = components[1].prefix(1)
            return "\(first)\(last)".uppercased()
        } else if let first = components.first {
            return String(first.prefix(1)).uppercased()
        }

        return "?"
    }

    private var statusColor: Color {
        guard let status = authViewModel.currentProfile?.status else {
            return .gray
        }

        switch status {
        case "active":
            return .green
        case "inactive":
            return .gray
        case "pending":
            return .orange
        default:
            return .gray
        }
    }

    private var initialsView: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue, Color.purple]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 100, height: 100)

            Text(initials)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
    }

    private var statusText: String {
        guard let status = authViewModel.currentProfile?.status else {
            return "Desconhecido"
        }

        switch status {
        case "active":
            return "Ativo"
        case "inactive":
            return "Inativo"
        case "pending":
            return "Pendente"
        default:
            return status.capitalized
        }
    }
}

// MARK: - Profile Info Row

struct ProfileInfoRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(value)
                    .font(.body)
            }

            Spacer()
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Tag View

struct TagView: View {
    let tag: String

    var body: some View {
        Text(tag)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue, Color.purple]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(20)
    }
}

// MARK: - Preview

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(AuthViewModel())
    }
}
