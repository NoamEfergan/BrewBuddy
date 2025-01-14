import CoffeeTheme
import Models
import SwiftData
import SwiftUI

public struct CoffeeListScreen: View {
  @Environment(\.modelContext) private var modelContext
  @Query(sort: [SortDescriptor(\CoffeeDataModel.name, comparator: .localizedStandard)])
  private var coffees: [CoffeeDataModel]
  public var onDelete: (() -> Void)?

  public init(onDelete: (() -> Void)? = nil) {
    self.onDelete = onDelete
  }

  public var body: some View {
    NavigationStack {
      Form {
        ForEach(coffees) { coffee in
          NavigationLink(destination: CoffeeDetailScreen(coffee: coffee)) {
            CoffeeListItemView(name: coffee.name,
                               roasterName: coffee.roasterName,
                               score: coffee.rating)
          }
          .listRowBackground(CoffeeTheme.AccentColor.highlight)
        }
        .onDelete { indexSet in
          for index in indexSet {
            modelContext.delete(coffees[index])
            onDelete?()
          }
        }
      }
      .foregroundStyle(CoffeeTheme.AccentColor.text)
      .scrollContentBackground(.hidden)
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
