//
//  ContentView.swift
//  RagTestIOS
//
//  Created by guinmoon on 19.10.2024.
//

import SwiftUI
import SimilaritySearchKit
import SimilaritySearchKitDistilbert
import SimilaritySearchKitMiniLMAll
import SimilaritySearchKitMiniLMMultiQA

struct ContentView: View {
    @State var inputText:String  = "The Birth of the Swatch"
    var search_url = Bundle.main.resourceURL?.appending(path: "06swatch.pdf")
    var searchResultsCount:Int = 3
    @State var loadIndexResult: String = ""
    @State var searchResults: String = ""
    
    @State private var chunkSize: Int = 256
    @State private var chunkOverlap: Int = 100
    @State private var currentModel: EmbeddingModelType = .minilmMultiQA
    @State private var comparisonAlgorithm: SimilarityMetricType = .dotproduct
    @State private var chunkMethod: TextSplitterType = .character
    
    

    
    var body: some View {
        ScrollView(showsIndicators: false){
            VStack {
                
                HStack{
                    Text("chunkSize:")
                    TextField("chunkSize", value: $chunkSize, formatter: NumberFormatter())
                }
                
                HStack{
                    Text("chunkOverlap:")
                    TextField("chunkOverlap", value: $chunkOverlap, formatter: NumberFormatter())
                }
                
                HStack{
                    Text("EmbeddingModelType:")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Picker("", selection: $currentModel) {
                        ForEach(SimilarityIndex.EmbeddingModelType.allCases, id: \.self) { option in
                            Text(String(describing: option))
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                HStack{
                    Text("SimilarityMetricType:")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Picker("", selection: $comparisonAlgorithm) {
                        ForEach(SimilarityIndex.SimilarityMetricType.allCases, id: \.self) { option in
                            Text(String(describing: option))
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                HStack{
                    Text("TextSplitterType:")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Picker("", selection: $chunkMethod) {
                        ForEach(TextSplitterType.allCases, id: \.self) { option in
                            Text(String(describing: option))
                        }
                    }
                    .pickerStyle(.menu)
                }
                

                
                Button(
                    action: {
                        Task{
                            await BuildIndex()
                        }
                    },
                    label: {
                        Text("Build index")
                            .font(.title2)
                    }
                )
                .padding(.top)
                
                Button(
                    action: {
                        print("b")
                    },
                    label: {
                        Text("Load index")
                            .font(.title2)
                    }
                )
                .padding(.bottom)
                
                Text(loadIndexResult)
                    .padding(.top)
                
                TextField("Search text", text: $inputText, axis: .vertical )
                    .onSubmit {
                        Task{
                            await search()
                        }
                    }
                    .textFieldStyle(.plain)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background {
                        RoundedRectangle(cornerRadius: 20)
#if os(macOS)
                            .stroke(Color(NSColor.systemGray), lineWidth: 0.2)
#else
                            .stroke(Color(UIColor.systemGray2), lineWidth: 0.2)
#endif
                            .background {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(.white.opacity(0.1))
                            }
                            .padding(.trailing, 2)
                        
                        
                    }
                    .lineLimit(1...5)
                
                Button(
                    action: {
                        Task{
                            await search()
                        }
                    },
                    label: {
                        Text("Search")
                            .font(.title2)
                    }
                )
                .padding()
                
                Text(searchResults)
                    .padding()
                
            }
            .padding()
        }
    }
    
    func BuildIndex() async{
        let start = DispatchTime.now()
        updateIndexComponents(currentModel:currentModel,comparisonAlgorithm:comparisonAlgorithm,chunkMethod:chunkMethod)
        await BuildNewIndex(search_url: search_url,
                            chunkSize: chunkSize,
                            chunkOverlap: chunkOverlap)
        let end = DispatchTime.now()   // конец замера времени
        let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds // наносекунды
        let timeInterval = Double(nanoTime) / 1_000_000_000 // преобразуем в секунды
        loadIndexResult = String(timeInterval) + " sec"
    }
    
    func search() async{
        let start = DispatchTime.now()
        let results = await searchIndexWithQuery(query: inputText, top: searchResultsCount)
        let end = DispatchTime.now()   // конец замера времени
        let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds // наносекунды
        let timeInterval = Double(nanoTime) / 1_000_000_000 // преобразуем в секунды

        searchResults = String(describing:results)
        print(results)
        
        print("Search time: \(timeInterval) sec")
    }
        
}

//#Preview {
//    ContentView()
//}
