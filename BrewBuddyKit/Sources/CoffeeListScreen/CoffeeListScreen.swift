import CoffeeTheme
import CommonUI
import Models
import SwiftData
import SwiftUI

public struct CoffeeListScreen: View {
    @Query(sort: [SortDescriptor(\CoffeeDataModel.name, comparator: .localizedStandard)])
    private var coffees: [CoffeeDataModel]
    private var onDelete: (() -> Void)?
    private let onNavigateToAdd: (() -> Void)?
    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
    ]

    public init(onDelete: (() -> Void)? = nil, onNavigateToAdd: (() -> Void)? = nil) {
        self.onDelete = onDelete
        self.onNavigateToAdd = onNavigateToAdd
    }

    public var body: some View {
        NavigationStack {
            Group {
                if coffees.isEmpty {
                    EmptyStatePopToAddView(onNavigateToAdd: onNavigateToAdd)
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(coffees) { coffee in
                                NavigationLink(destination: CoffeeDetailScreen(coffee: coffee)) {
                                    CoffeeListItemView(name: coffee.name,
                                                       roasterName: coffee.roasterName,
                                                       score: coffee.rating)
                                        .frame(height: 120)
                                        .frame(maxWidth: .infinity)
                                        .background(CoffeeTheme.AccentColor.highlight)
                                        .cornerRadius(18)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .foregroundStyle(CoffeeTheme.AccentColor.text)
            .background(CoffeeTheme.AccentColor.background)
        }
    }
}

#Preview("Loaded state") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: CoffeeDataModel.self, configurations: config)
    for coffee in [CoffeeDataModel].mockCoffees {
        container.mainContext.insert(coffee)
    }

    return NavigationView { CoffeeListScreen() }
        .modelContainer(container)
}

#Preview("Empty state") {
    CoffeeListScreen()
}
