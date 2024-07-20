import SwiftUI

// 1. Component Models
struct ServerComponent: Codable, Identifiable {
    let id: String
    let type: String
    let properties: [String: String]
    let children: [ServerComponent]?
}

struct ServerResponse: Codable {
    let components: [ServerComponent]
}

// 2. Server-Driven Container View
struct ServerDrivenView: View {
    let components: [ServerComponent]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(components) { component in
                    switch component.type {
                    case "planetCard":
                        planetCard(component)
                    case "galaxyStats":
                        galaxyStats(component)
                    case "exploreButton":
                        exploreButton(component)
                    case "carousel":
                        carouselComponent(component)
                    case "hscroll":
                        hscrollComponent(component)
                    default:
                        Text("Unknown component")
                    }
                }
            }
            .padding(15)
        }
        .background(
            LinearGradient(gradient: Gradient(colors: [.black, .purple.opacity(0.3)]), startPoint: .top, endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)
        )
    }
    
    @ViewBuilder
    func planetCard(_ component: ServerComponent) -> some View {
        VStack (spacing: 0){
            AsyncImage(url: URL(string: component.properties["imageUrl"] ?? "")) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                case .failure:
                    Image(systemName: "photo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                @unknown default:
                    EmptyView()
                }
            }
            .frame(height: 200)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white, lineWidth: 4))
            .shadow(radius: 10)
            .padding(5)
            
            Text(component.properties["name"] ?? "")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(component.properties["description"] ?? "")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.bottom, 28)
        }
        .frame(maxWidth: .infinity)
        .background(Color.black)
        .cornerRadius(20)
        .padding()
    }
    
    @ViewBuilder
    func galaxyStats(_ component: ServerComponent) -> some View {
        VStack {
            Text(component.properties["statName"] ?? "")
                .font(.headline)
                .foregroundColor(.gray)
            
            Text(component.properties["value"] ?? "")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .padding()
        .background(Color.purple.opacity(0.3))
        .cornerRadius(15)
    }
    
    @ViewBuilder
    func exploreButton(_ component: ServerComponent) -> some View {
        Button(action: {
            print("Explore button tapped")
        }) {
            Text(component.properties["title"] ?? "Explore")
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(LinearGradient(gradient: Gradient(colors: [.purple, .blue]), startPoint: .leading, endPoint: .trailing))
                .cornerRadius(15)
        }
    }
    @ViewBuilder
    func carouselComponent(_ component: ServerComponent) -> some View {
        TabView {
            ForEach(component.children ?? []) { child in
                switch child.type {
                case "planetCard":
                    planetCard(child)
                case "galaxyStats":
                    galaxyStats(child)
                default:
                    Text("Unknown carousel item")
                }
            }
        }
        .frame(height: 300)
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
    }
    
    @ViewBuilder
    func hscrollComponent(_ component: ServerComponent) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 15) {
                ForEach(component.children ?? []) { child in
                    switch child.type {
                    case "planetCard":
                        planetCard(child)
                            .frame(width: 250)
                    case "galaxyStats":
                        galaxyStats(child)
                            .frame(width: 200)
                    default:
                        Text("Unknown hscroll item")
                    }
                }
            }
        }
    }
}

// 3. ContentView
struct ContentView: View {
    @State private var components: [ServerComponent] = []
    
    var body: some View {
        ServerDrivenView(components: components)
            .onAppear(perform: fetchComponents)
    }
    
    func fetchComponents() {
        guard let url = URL(string: "https://oooop.free.beeceptor.com/components") else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                if let decodedResponse = try? JSONDecoder().decode(ServerResponse.self, from: data) {
                    DispatchQueue.main.async {
                        self.components = decodedResponse.components
                    }
                    return
                }
            }
            print("Fetch failed: \(error?.localizedDescription ?? "Unknown error")")
            self.useMockData()
        }.resume()
    }
    
    func useMockData() {
        let mockJSON = """
        {
          "components": [
            {
              "id": "1",
              "type": "carousel",
              "properties": {},
              "children": [
                {
                  "id": "1a",
                  "type": "planetCard",
                  "properties": {
                    "name": "Mars",
                    "description": "The Red Planet",
                    "imageUrl": "https://example.com/mars.jpg"
                  }
                },
                {
                  "id": "1b",
                  "type": "planetCard",
                  "properties": {
                    "name": "Jupiter",
                    "description": "The Giant Planet",
                    "imageUrl": "https://example.com/jupiter.jpg"
                  }
                }
              ]
            },
            {
              "id": "2",
              "type": "hscroll",
              "properties": {},
              "children": [
                {
                  "id": "2a",
                  "type": "galaxyStats",
                  "properties": {
                    "statName": "Known Exoplanets",
                    "value": "4,395"
                  }
                },
                {
                  "id": "2b",
                  "type": "galaxyStats",
                  "properties": {
                    "statName": "Milky Way Diameter",
                    "value": "100,000 ly"
                  }
                }
              ]
            },
            {
              "id": "3",
              "type": "exploreButton",
              "properties": {
                "title": "Explore the Cosmos"
              }
            }
          ]
        }
        """
        
        if let data = mockJSON.data(using: .utf8) {
            if let decodedResponse = try? JSONDecoder().decode(ServerResponse.self, from: data) {
                DispatchQueue.main.async {
                    self.components = decodedResponse.components
                }
            }
        }
    }
}

// 4. Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
