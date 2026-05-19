import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var showForgotPassword = false
    @State private var resetEmail = ""
    @State private var logoScale: CGFloat = 0.8
    @State private var formOpacity: Double = 0

    var body: some View {
        ZStack {
            Theme.heroGradient
                .ignoresSafeArea()

            // Decorative circles
            GeometryReader { geo in
                Circle()
                    .fill(Color.white.opacity(0.06))
                    .frame(width: geo.size.width * 0.7)
                    .offset(x: -geo.size.width * 0.2, y: -geo.size.height * 0.15)

                Circle()
                    .fill(Color.white.opacity(0.04))
                    .frame(width: geo.size.width * 0.5)
                    .offset(x: geo.size.width * 0.55, y: geo.size.height * 0.6)
            }
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 36) {
                    Spacer().frame(height: 40)

                    // Logo
                    VStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.15))
                                .frame(width: 110, height: 110)

                            Image(systemName: "bubble.left.and.bubble.right.fill")
                                .font(.system(size: 48, weight: .medium))
                                .foregroundStyle(.white)
                        }
                        .scaleEffect(logoScale)
                        .onAppear {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                                logoScale = 1.0
                            }
                        }

                        Text(Constants.appName)
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Text("Conecte-se com seus clientes")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.75))
                    }

                    // Login card
                    VStack(spacing: 22) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Email")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)

                            HStack(spacing: 12) {
                                Image(systemName: "envelope")
                                    .foregroundColor(.secondary)
                                    .frame(width: 20)

                                TextField("seu@email.com", text: $email)
                                    .textContentType(.emailAddress)
                                    .autocapitalization(.none)
                                    .keyboardType(.emailAddress)
                            }
                            .padding()
                            .background(Theme.cardBackground)
                            .cornerRadius(Theme.cornerSM)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Senha")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)

                            HStack(spacing: 12) {
                                Image(systemName: "lock")
                                    .foregroundColor(.secondary)
                                    .frame(width: 20)

                                SecureField("••••••••", text: $password)
                                    .textContentType(.password)
                            }
                            .padding()
                            .background(Theme.cardBackground)
                            .cornerRadius(Theme.cornerSM)
                        }

                        HStack {
                            Spacer()
                            Button(action: { showForgotPassword = true }) {
                                Text("Esqueci minha senha")
                                    .font(.footnote)
                                    .fontWeight(.medium)
                                    .foregroundColor(Theme.primary)
                            }
                        }

                        Button(action: {
                            Task { await authViewModel.signIn(email: email, password: password) }
                        }) {
                            Group {
                                if authViewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Entrar")
                                        .font(.headline)
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                (email.isEmpty || password.isEmpty) ?
                                AnyShapeStyle(Theme.primary.opacity(0.4)) :
                                AnyShapeStyle(Theme.primaryGradient)
                            )
                            .cornerRadius(Theme.cornerMD)
                            .modifier(ElevatedShadow())
                        }
                        .disabled(authViewModel.isLoading || email.isEmpty || password.isEmpty)

                        if let errorMessage = authViewModel.errorMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(Theme.danger)
                                Text(errorMessage)
                                    .font(.footnote)
                                    .foregroundColor(Theme.danger)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Theme.danger.opacity(0.08))
                            .cornerRadius(Theme.cornerSM)
                        }
                    }
                    .padding(24)
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(Theme.cornerXL)
                    .modifier(ElevatedShadow())
                    .padding(.horizontal, 20)
                    .opacity(formOpacity)
                    .onAppear {
                        withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                            formOpacity = 1
                        }
                    }

                    Spacer().frame(height: 40)
                }
            }
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView(isPresented: $showForgotPassword)
                .environmentObject(authViewModel)
        }
    }
}

// MARK: - Forgot Password View

struct ForgotPasswordView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Binding var isPresented: Bool
    @State private var email = ""
    @State private var showSuccess = false

    var body: some View {
        NavigationView {
            ZStack {
                Theme.screenBackground.ignoresSafeArea()

                VStack(spacing: 24) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(Theme.primaryGradient)
                        .padding(.top, 20)

                    Text("Digite seu email para receber instruções de recuperação de senha")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Email")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)

                        HStack(spacing: 12) {
                            Image(systemName: "envelope")
                                .foregroundColor(.secondary)
                                .frame(width: 20)

                            TextField("seu@email.com", text: $email)
                                .textContentType(.emailAddress)
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                        }
                        .padding()
                        .background(Theme.cardBackground)
                        .cornerRadius(Theme.cornerSM)
                    }
                    .padding(.horizontal)

                    Button(action: {
                        Task {
                            await authViewModel.resetPassword(email: email)
                            showSuccess = true
                        }
                    }) {
                        Group {
                            if authViewModel.isLoading {
                                ProgressView()
                            } else {
                                Text("Enviar")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(email.isEmpty ? Color.gray.opacity(0.3) : Theme.primary)
                        .cornerRadius(Theme.cornerMD)
                    }
                    .padding(.horizontal)
                    .disabled(authViewModel.isLoading || email.isEmpty)

                    Spacer()
                }
            }
            .navigationTitle("Recuperar Senha")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fechar") { isPresented = false }
                }
            }
            .alert("Email Enviado", isPresented: $showSuccess) {
                Button("OK") { isPresented = false }
            } message: {
                Text("Verifique sua caixa de entrada para recuperar sua senha.")
            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(AuthViewModel())
    }
}
