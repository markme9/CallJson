//
//  ContentView.swift
//  CallJson
//
//  Created by mark me on 10/30/22.
//

import SwiftUI
import Combine

struct Model: Identifiable, Codable {
    var id: Int
    var title: String
    var url: String
}

class ViewModel:  ObservableObject {
    
    @Published var data: [Model] = []
    @Published var searchResults: String = ""
    
    var anyCancelable = Set<AnyCancellable>()
    
    func getImage() {
        
        guard let url = URL(string: "https://jsonplaceholder.typicode.com/photos") else { return }
        
        URLSession.shared.dataTaskPublisher(for: url)
            .receive(on: DispatchQueue.main)
            .tryMap { (data, response) -> Data in
                guard let response = response as? HTTPURLResponse, response.statusCode >= 200 && response.statusCode <= 300 else { throw URLError(.badServerResponse)}
                    
                return data
            }
            .decode(type: [Model].self, decoder: JSONDecoder())
            .sink { completion in
                print(completion)
            } receiveValue: { [weak self] returnData in
                self?.data = returnData
            }
            .store(in: &anyCancelable)
        
    }
    
    var filterResult: [Model] {
        if searchResults.isEmpty {
            return data
        }else {
            return data.filter{$0.title.contains(searchResults)}
        }
    }
}

struct ContentView: View {
    
    @StateObject var vm = ViewModel()
    
    var body: some View {
        NavigationView {
            List {
                ForEach(self.vm.filterResult) { item in
                    let url = URL(string: item.url)
                    AsyncImage(url: url) { image in
                        HStack {
                            image
                                .resizable()
                                .frame(width: 100, height: 100)
                                .cornerRadius(10)
                            
                            Text(item.title)
                                .font(.headline)
                        }
                    } placeholder: {
                        ProgressView()
                    }
                }
            }
            .navigationTitle(Text("Images"))
            .searchable(text: $vm.searchResults)
            .onAppear {
                vm.getImage()
            }
            
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
