//
//  AuthViewModel.swift
//  WTCChatApp
//
//  Created by WTC Challenge
//

import Foundation
import SwiftUI

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentProfile: Profile?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let apiService = APIService.shared

    init() {
        Task {
            await checkSession()
        }
    }

    // MARK: - Authentication

    func checkSession() async {
        isLoading = true
        defer { isLoading = false }

        guard apiService.isLoggedIn else {
            isAuthenticated = false
            return
        }

        do {
            let profile = try await apiService.fetchProfile()
            currentProfile = profile
            isAuthenticated = true

            if let userId = apiService.currentUserId {
                WebSocketService.shared.connect(userId: userId)
            }
        } catch {
            isAuthenticated = false
            apiService.logout()
        }
    }

    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response = try await apiService.login(email: email, password: password)
            currentProfile = Profile(
                id: UUID(uuidString: response.userId) ?? UUID(),
                fullName: response.fullName,
                email: response.email,
                phone: response.phone,
                avatarUrl: response.avatarUrl,
                tags: response.tags ?? [],
                status: response.status ?? "active",
                role: response.role,
                createdAt: Date()
            )
            isAuthenticated = true

            WebSocketService.shared.connect(userId: response.userId)
        } catch {
            errorMessage = "Erro ao fazer login: \(error.localizedDescription)"
            print("Sign in error: \(error)")
        }
    }

    func signOut() async {
        isLoading = true
        defer { isLoading = false }

        apiService.logout()
        currentProfile = nil
        isAuthenticated = false
        WebSocketService.shared.cleanup()
    }

    func resetPassword(email: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        errorMessage = "Funcionalidade de recuperação de senha disponível em breve."
    }

    // MARK: - Profile

    func refreshProfile() async {
        do {
            currentProfile = try await apiService.fetchProfile()
        } catch {
            print("Error loading profile: \(error)")
        }
    }
}
