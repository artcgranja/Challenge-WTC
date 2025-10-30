//
//  AuthViewModel.swift
//  WTCChatApp
//
//  Created by WTC Challenge
//

import Foundation
import SwiftUI
import Supabase

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var currentProfile: Profile?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let supabaseService = SupabaseService.shared

    init() {
        Task {
            await checkSession()
        }
    }

    // MARK: - Authentication

    func checkSession() async {
        isLoading = true
        defer { isLoading = false }

        do {
            if let session = await supabaseService.getCurrentSession() {
                currentUser = session.user
                isAuthenticated = true
                await loadProfile()
            } else {
                isAuthenticated = false
            }
        }
    }

    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let user = try await supabaseService.signIn(email: email, password: password)
            currentUser = user
            isAuthenticated = true
            await loadProfile()
        } catch {
            errorMessage = "Erro ao fazer login: \(error.localizedDescription)"
            print("Sign in error: \(error)")
        }
    }

    func signOut() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await supabaseService.signOut()
            currentUser = nil
            currentProfile = nil
            isAuthenticated = false

            // Cleanup realtime subscriptions
            await RealtimeService.shared.cleanup()
        } catch {
            errorMessage = "Erro ao fazer logout: \(error.localizedDescription)"
            print("Sign out error: \(error)")
        }
    }

    func resetPassword(email: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await supabaseService.resetPassword(email: email)
            errorMessage = "Email de recuperação enviado! Verifique sua caixa de entrada."
        } catch {
            errorMessage = "Erro ao enviar email: \(error.localizedDescription)"
            print("Reset password error: \(error)")
        }
    }

    // MARK: - Profile

    private func loadProfile() async {
        guard let userId = currentUser?.id else { return }

        do {
            currentProfile = try await supabaseService.fetchProfile(userId: userId)
        } catch {
            print("Error loading profile: \(error)")
            // If profile doesn't exist, we might need to create one
            // For now, just log the error
        }
    }

    func refreshProfile() async {
        await loadProfile()
    }
}
