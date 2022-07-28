//
//  ContentView.swift
//  TaskGroup
//
//  Created by Skorobogatow, Christian on 28/7/22.
//

import SwiftUI

class TaskGroupDataManager {
    static let instance = TaskGroupDataManager()
    private init() {}
    
    let url = "https://picsum.photos/300"
    
    func fetchImagesWithAsyncLet() async  throws-> [UIImage]{
        
        
        
        async let fetchImage1 = fetchImage(urlString: url)
        async let fetchImage2 = fetchImage(urlString: url)
        async let fetchImage3 = fetchImage(urlString: url)
        async let fetchImage4 = fetchImage(urlString: url)
        
        
        
        let (image1, image2, image3, image4) = await (try fetchImage1,
                                                      try fetchImage2,
                                                      try fetchImage3,
                                                      try fetchImage4)
        
        return [image1, image2, image3, image4]
        
    }
    
    func fetchImagesWithTaskGroup()  async  throws-> [UIImage] {
        let urlStrings = ["https://picsum.photos/300",
                          "https://picsum.photos/300",
                          "https://picsum.photos/300",
                          "https://picsum.photos/300",
                          "https://picsum.photos/300"]
        
        
        return try await withThrowingTaskGroup(of: UIImage?.self) { group in
            
            var images: [UIImage] = []
            images.reserveCapacity(urlStrings.count)
            
            for urlString in urlStrings {
                group.addTask {
                    try? await self.fetchImage(urlString: urlString)
                }
            }
            
            for try await image in group {
                if let image = image {
                    images.append(image)
                }
            }
            
            return images
        }
    }
    
    private func fetchImage(urlString: String) async throws -> UIImage {
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url, delegate: nil)
            
            if let image = UIImage(data: data) {
                return image
            } else {
                throw URLError(.badURL)
            }
            
        } catch  {
            throw error
        }
    }
    
}


class TaskGroupViewModel: ObservableObject {
    
    @Published var images: [UIImage] = []
    let manager = TaskGroupDataManager.instance
    
    func getImages() async {
        if let images = try? await manager.fetchImagesWithTaskGroup() {
            self.images.append(contentsOf: images)
        }
    }
}


struct ContentView: View {
    
    @StateObject var viewModel = TaskGroupViewModel()
    
    
    let columns = [GridItem(.flexible()),
                   GridItem(.flexible())]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns) {
                    ForEach(viewModel.images, id: \.self) { image in
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 150)
                    }
                }
            }
            .navigationTitle("Async Let 🥳")
            .task {
                await viewModel.getImages()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
