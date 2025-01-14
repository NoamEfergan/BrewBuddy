import Models
import SwiftData
import SwiftUI
import CoffeeTheme

public struct CoffeeListScreen: View {
  @Query(sort: [SortDescriptor(\CoffeeDataModel.name, comparator: .localizedStandard)])
  private var coffees: [CoffeeDataModel]
  
  public init() {}
  
  public var body: some View {
    NavigationStack {
      Form {
        ForEach(coffees) { coffee in
          NavigationLink(destination: Text("test")) {
            CoffeeListItemView(name: coffee.name,
                               roasterName: coffee.roasterName,
                               score: coffee.rating)
          }
          .listRowBackground(CoffeeTheme.AccentColor.highlight)
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
