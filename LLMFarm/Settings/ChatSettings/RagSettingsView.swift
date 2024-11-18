//
//  RagSettingsView.swift
//  LLMFarm
//
//  Created by guinmoon on 20.10.2024.
//

import SwiftUI
import SimilaritySearchKit
import SimilaritySearchKitDistilbert
import SimilaritySearchKitMiniLMAll
import SimilaritySearchKitMiniLMMultiQA

struct RagSettingsView: View {
    @State var ragDir: String
    
    @State var inputText:String  = ""
    var searchUrl:URL
    var ragUrl:URL
    var searchResultsCount:Int = 3
    @State var loadIndexResult: String = ""
    @State var searchResults: String = ""
    
    
    @Binding private var chunkSize: Int
    @Binding private var chunkOverlap: Int 
    @Binding private var currentModel: EmbeddingModelType 
    @Binding private var comparisonAlgorithm: SimilarityMetricType 
    @Binding private var chunkMethod: TextSplitterType
    @Binding private var ragTop: Int
    
    init (  ragDir:String,
            chunkSize: Binding<Int>,
            chunkOverlap: Binding<Int>,
            currentModel: Binding<EmbeddingModelType>,
            comparisonAlgorithm: Binding<SimilarityMetricType>,
            chunkMethod: Binding<TextSplitterType>,
            ragTop:Binding<Int>){
        self.ragDir = ragDir
        self.ragUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(ragDir) ?? URL(fileURLWithPath: "")
        self.searchUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(ragDir+"/docs") ?? URL(fileURLWithPath: "")
        self._chunkSize = chunkSize
        self._chunkOverlap = chunkOverlap
        self._currentModel = currentModel
        self._comparisonAlgorithm = comparisonAlgorithm
        self._chunkMethod  = chunkMethod
        self._ragTop = ragTop
    }

    
    var body: some View {
        ScrollView(showsIndicators: false){
            VStack {
                GroupBox(label:
                            Text("RAG Settings")
                ) {
                    HStack {
                        Text("Chunk Size:")
                            .frame(maxWidth: 100, alignment: .leading)
                        TextField("size..", value: $chunkSize, format:.number)
                            .frame( alignment: .leading)
                            .multilineTextAlignment(.trailing)
                            .textFieldStyle(.plain)
                             #if os(iOS)
                            .keyboardType(.numbersAndPunctuation)
                             #endif
                    }   
//                    .padding(.horizontal, 5)
                    
                    HStack {
                        Text("Chunk Overlap:")
                            .frame(maxWidth: 100, alignment: .leading)
                        TextField("size..", value: $chunkOverlap, format:.number)
                            .frame( alignment: .leading)
                            .multilineTextAlignment(.trailing)
                            .textFieldStyle(.plain)
                             #if os(iOS)
                            .keyboardType(.numbersAndPunctuation)
                             #endif
                    }   
//                    .padding(.horizontal, 5)

                    
                    HStack{
                        Text("Embedding Model:")
                            .frame(maxWidth: 100, alignment: .leading)
                        Picker("", selection: $currentModel) {
                            ForEach(SimilarityIndex.EmbeddingModelType.allCases, id: \.self) { option in
                                Text(String(describing: option))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .pickerStyle(.menu)
                    }
                    
                    HStack{
                        Text("Similarity Metric:")
                            .frame(maxWidth: 120, alignment: .leading)
                        Picker("", selection: $comparisonAlgorithm) {
                            ForEach(SimilarityIndex.SimilarityMetricType.allCases, id: \.self) { option in
                                Text(String(describing: option))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .pickerStyle(.menu)
                    }
                    
                    HStack{
                        Text("Text Splitter:")
                            .frame(maxWidth: 120, alignment: .leading)
                        Picker("", selection: $chunkMethod) {
                            ForEach(TextSplitterType.allCases, id: \.self) { option in
                                Text(String(describing: option))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .pickerStyle(.menu)
                    }
                    
                    HStack {
                        Text("Max RAG answers count:")
                            .frame(maxWidth: 100, alignment: .leading)
                        TextField("count..", value: $ragTop, format:.number)
                            .frame( alignment: .leading)
                            .multilineTextAlignment(.trailing)
                            .textFieldStyle(.plain)
                             #if os(iOS)
                            .keyboardType(.numbersAndPunctuation)
                             #endif
                    }

                }
//                .padding(.horizontal, 1)

                GroupBox(label:
                            Text("RAG Debug")
                ) {
                    HStack{
                        Button(
                            action: {
                                Task{
                                    await BuildIndex(ragURL: ragUrl)
                                }
                            },
                            label: {
                                Text("Rebuild index")
                                    .font(.title2)
                            }
                        )
                        .padding()
                        
                        Button(
                            action: {
                                Task{
                                    await LoadIndex(ragURL: ragUrl)
                                }
                            },
                            label: {
                                Text("Load index")
                                    .font(.title2)
                            }
                        )
                        .padding()
                    }
                    
                    Text(loadIndexResult)
//                        .padding(.top)
                    
                    TextField("Search text", text: $inputText, axis: .vertical )
                        .onSubmit {
                            Task{
                                await Search()
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
                    
//                    Button(
//                        action: {
//                            Task{
//                                await Search()
//                            }
//                        },
//                        label: {
//                            Text("Search")
//                                .font(.title2)
//                        }
//                    )
//                    .padding()
                    
                    Button(
                        action: {
                            Task{
                                await GeneratePrompt()
                            }
                        },
                        label: {
                            Text("Search and Generate Prompt")
                                .font(.title2)
                        }
                    )
//                    .padding()
                    
                    Text(searchResults)
                        .padding()
                        .textSelection(.enabled)
                }
//                .padding(.horizontal, 1)
                
            }
//            .padding()
        }
    }
    
    func BuildIndex(ragURL: URL) async{
        let start = DispatchTime.now()
        updateIndexComponents(currentModel:currentModel,comparisonAlgorithm:comparisonAlgorithm,chunkMethod:chunkMethod)
        await BuildNewIndex(searchUrl: searchUrl,
                            chunkSize: chunkSize,
                            chunkOverlap: chunkOverlap)
        let end = DispatchTime.now()   // конец замера времени
        let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds // наносекунды
        let timeInterval = Double(nanoTime) / 1_000_000_000 // преобразуем в секунды
        loadIndexResult = String(timeInterval) + " sec"
        saveIndex(url: ragURL, name: "RAG_index")
    }
    
    func LoadIndex(ragURL: URL) async{
        updateIndexComponents(currentModel:currentModel,comparisonAlgorithm:comparisonAlgorithm,chunkMethod:chunkMethod)
        await loadExistingIndex(url: ragURL, name: "RAG_index")
        loadIndexResult =  "Loaded"
    }
    
    func Search() async{
        let start = DispatchTime.now()
        let results = await searchIndexWithQuery(query: inputText, top: searchResultsCount)
        let end = DispatchTime.now()   // конец замера времени
        let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds // наносекунды
        let timeInterval = Double(nanoTime) / 1_000_000_000 // преобразуем в секунды
                
        
        searchResults = String(describing:results)
        print(results)
        
        print("Search time: \(timeInterval) sec")
    }
    
    
    func GeneratePrompt() async{
        let start = DispatchTime.now()
        let results = await searchIndexWithQuery(query: inputText, top: searchResultsCount)
        let end = DispatchTime.now()   // конец замера времени
        let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds // наносекунды
        let timeInterval = Double(nanoTime) / 1_000_000_000 // преобразуем в секунды
        
        if results == nil{
            return
        }
        
        let llmPrompt = SimilarityIndex.exportLLMPrompt(query: inputText, results: results!)
        
        searchResults = llmPrompt
        print(llmPrompt)
        
        print("Search time: \(timeInterval) sec")
    }
}

//#Preview {
//    RagSettingsView()
//}
