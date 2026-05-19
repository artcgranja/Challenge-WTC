import SwiftUI
import UserNotifications

@main
struct WTCChatAppApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var notificationService = NotificationService.shared

    init() {
        Task {
            await NotificationService.shared.requestAuthorization()
        }
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        configureAppearance()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .environmentObject(notificationService)
                .overlay(
                    Group {
                        if notificationService.shouldShowInAppNotification,
                           let notification = notificationService.currentInAppNotification {
                            VStack {
                                InAppNotificationView(
                                    notification: notification,
                                    onTap: {
                                        notificationService.dismissInAppNotification()
                                    },
                                    onDismiss: {
                                        notificationService.dismissInAppNotification()
                                    }
                                )
                                .padding(.top, 50)
                                .transition(.move(edge: .top).combined(with: .opacity))
                                .animation(.spring(response: 0.4, dampingFraction: 0.75), value: notificationService.shouldShowInAppNotification)

                                Spacer()
                            }
                        }
                    }
                )
        }
    }

    private func configureAppearance() {
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithDefaultBackground()
        navAppearance.titleTextAttributes = [.font: UIFont.systemFont(ofSize: 17, weight: .semibold)]
        navAppearance.largeTitleTextAttributes = [.font: UIFont.systemFont(ofSize: 34, weight: .bold)]
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance

        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithDefaultBackground()
        UITabBar.appearance().standardAppearance = tabAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabAppearance
        }

        UITabBar.appearance().tintColor = UIColor(Theme.primary)
    }
}

// MARK: - Content View

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        Group {
            if authViewModel.isLoading {
                SplashView()
            } else if authViewModel.isAuthenticated {
                if authViewModel.currentProfile?.isOperator == true {
                    OperatorTabView()
                        .environmentObject(authViewModel)
                        .transition(.opacity)
                } else {
                    MainTabView()
                        .environmentObject(authViewModel)
                        .transition(.opacity)
                }
            } else {
                LoginView()
                    .environmentObject(authViewModel)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authViewModel.isAuthenticated)
    }
}

// MARK: - Splash View

struct SplashView: View {
    @State private var scale: CGFloat = 0.85
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            Theme.heroGradient
                .ignoresSafeArea()

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 120, height: 120)

                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 52, weight: .medium))
                        .foregroundColor(.white)
                }
                .scaleEffect(scale)

                Text(Constants.appName)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.1)
            }
            .opacity(opacity)
            .onAppear {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                    scale = 1.0
                }
                withAnimation(.easeOut(duration: 0.4)) {
                    opacity = 1
                }
            }
        }
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedTab = 0
    @State private var showNotifications = false

    var body: some View {
        TabView(selection: $selectedTab) {
            MessagesListView()
                .environmentObject(authViewModel)
                .tabItem {
                    Label("Mensagens", systemImage: "message.fill")
                }
                .tag(0)

            Button(action: {
                showNotifications = true
            }) {
                EmptyView()
            }
            .tabItem {
                Label("Notificações", systemImage: "bell.fill")
            }
            .tag(1)
        }
        .tint(Theme.primary)
        .sheet(isPresented: $showNotifications) {
            NotificationsView()
                .environmentObject(authViewModel)
        }
        .onChange(of: selectedTab) { newValue in
            if newValue == 1 {
                showNotifications = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    selectedTab = 0
                }
            }
        }
    }
}

// MARK: - Operator Tab View

struct OperatorTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var crmViewModel = CRMViewModel()
    @StateObject private var campaignViewModel = CampaignViewModel()
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            CustomerListView()
                .environmentObject(authViewModel)
                .environmentObject(crmViewModel)
                .environmentObject(campaignViewModel)
                .tabItem {
                    Label("CRM", systemImage: "person.2.fill")
                }
                .tag(0)

            CampaignListView()
                .environmentObject(authViewModel)
                .environmentObject(campaignViewModel)
                .tabItem {
                    Label("Campanhas", systemImage: "megaphone.fill")
                }
                .tag(1)

            OperatorMessagesView()
                .environmentObject(authViewModel)
                .environmentObject(campaignViewModel)
                .tabItem {
                    Label("Mensagens", systemImage: "message.fill")
                }
                .tag(2)

            ProfileView()
                .environmentObject(authViewModel)
                .tabItem {
                    Label("Perfil", systemImage: "person.fill")
                }
                .tag(3)
        }
        .tint(Theme.primary)
    }
}

// MARK: - Notification Delegate

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    private override init() {
        super.init()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        if let messageIdString = userInfo["messageId"] as? String,
           let messageId = UUID(uuidString: messageIdString) {
            NotificationCenter.default.post(
                name: NSNotification.Name("NavigateToMessage"),
                object: nil,
                userInfo: ["messageId": messageId]
            )
        }
        completionHandler()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AuthViewModel())
    }
}
