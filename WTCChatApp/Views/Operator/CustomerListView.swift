import SwiftUI

struct CustomerListView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var crmViewModel: CRMViewModel
    @EnvironmentObject var campaignViewModel: CampaignViewModel
    @State private var selectedCustomer: Customer?

    var body: some View {
        NavigationView {
            ZStack {
                Theme.screenBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    tagFilterChips

                    SearchBar(text: $crmViewModel.searchText)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)

                    if crmViewModel.isLoading && crmViewModel.customers.isEmpty {
                        Spacer()
                        ProgressView().scaleEffect(1.1)
                        Spacer()
                    } else if crmViewModel.filteredCustomers.isEmpty {
                        EmptyStateView(
                            icon: "person.2",
                            message: "Nenhum cliente encontrado",
                            subtitle: "Seus clientes aparecerão aqui"
                        )
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 10) {
                                ForEach(crmViewModel.filteredCustomers) { customer in
                                    CustomerRowView(customer: customer)
                                        .onTapGesture { selectedCustomer = customer }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                        }
                        .refreshable {
                            await crmViewModel.fetchCustomers()
                        }
                    }
                }
                .navigationTitle("Clientes")
                .navigationBarTitleDisplayMode(.large)

                NavigationLink(
                    destination: Group {
                        if let customer = selectedCustomer {
                            CustomerDetailView(customer: customer)
                                .environmentObject(crmViewModel)
                                .environmentObject(campaignViewModel)
                        }
                    },
                    isActive: Binding(
                        get: { selectedCustomer != nil },
                        set: { if !$0 { selectedCustomer = nil } }
                    )
                ) { EmptyView() }
            }
        }
        .task {
            await crmViewModel.fetchCustomers()
        }
    }

    private var tagFilterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                FilterChip(title: "Todos", isSelected: crmViewModel.selectedTagFilter == nil) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        crmViewModel.selectedTagFilter = nil
                    }
                }
                ForEach(crmViewModel.availableTags, id: \.self) { tag in
                    FilterChip(title: tag.capitalized, isSelected: crmViewModel.selectedTagFilter == tag) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            crmViewModel.selectedTagFilter = tag
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }
}

struct CustomerRowView: View {
    let customer: Customer

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Theme.primaryGradient)
                    .frame(width: Theme.avatarSM, height: Theme.avatarSM)
                Text(customer.initials)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(customer.displayName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    Circle()
                        .fill(customer.statusColor)
                        .frame(width: 8, height: 8)
                }

                HStack(spacing: 4) {
                    ForEach(customer.tags.prefix(3), id: \.self) { tag in
                        Text(tag)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Theme.primary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Theme.primary.opacity(0.1))
                            .cornerRadius(10)
                    }
                }
            }

            Spacer()

            Text("\(customer.score)")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(customer.scoreColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(customer.scoreColor.opacity(0.1))
                .cornerRadius(10)
        }
        .padding(14)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(Theme.cornerMD)
        .modifier(CardShadow())
    }
}
