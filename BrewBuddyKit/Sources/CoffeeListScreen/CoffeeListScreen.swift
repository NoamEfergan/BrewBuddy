import CoffeeTheme
import Models
import SwiftData
import SwiftUI

public struct CoffeeListScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\CoffeeDataModel.name, comparator: .localizedStandard)])
    private var coffees: [CoffeeDataModel]
    public var onDelete: (() -> Void)?
    let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
    ]

    public init(onDelete: (() -> Void)? = nil) {
        self.onDelete = onDelete
    }

    public var body: some View {
        NavigationStack {
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
            .foregroundStyle(CoffeeTheme.AccentColor.text)
            .background(CoffeeTheme.AccentColor.background)
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: CoffeeDataModel.self, configurations: config)
    for coffee in [CoffeeDataModel].mockCoffees {
        container.mainContext.insert(coffee)
    }

    return NavigationView { CoffeeListScreen() }
        .modelContainer(container)
}
