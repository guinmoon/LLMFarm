//
//  RAG.swift
//  RagTestIOS
//
//  Created by guinmoon on 19.10.2024.
//

import Foundation
import SimilaritySearchKit
import SimilaritySearchKitDistilbert
import SimilaritySearchKitMiniLMAll
import SimilaritySearchKitMiniLMMultiQA


private var currentModel: EmbeddingModelType = .distilbert
private var comparisonAlgorithm: SimilarityMetricType = .dotproduct
private var chunkMethod: TextSplitterType = .character
private var storage: VectorStoreType = .json
private var searchQuery: String = ""
private var searchResultsCount: Int = 5
private var searchResults: [SimilarityIndex.SearchResult]?
private var chunkSize: Int = 256
private var chunkOverlap: Int = 100
private var filePickerURLs: [URL] = []
private var folderItem: DiskItem?
private var folderContents: [DiskItem]?
private var folderTextIds: [String]?
private var folderTextChunks: [String]?
private var folderTextMetadata: [[String: String]]?
private var folderTokensCount: Int?
private var folderCharactersCount: Int?
private var clock = ContinuousClock()
private var folderScanTime: Duration = Duration(secondsComponent: 0, attosecondsComponent: 0)
private var scanProgress: Int = 0
private var scanTotal: Int = 100
private var textSplitTime: Duration = Duration(secondsComponent: 0, attosecondsComponent: 0)
private var embeddingElapsedTime: Duration = Duration(secondsComponent: 0, attosecondsComponent: 0)
private var searchElapsedTime: Duration = Duration(secondsComponent: 0, attosecondsComponent: 0)
private var isLoading: Bool = false
private var isSearching: Bool = false
private var progressStage: String = ""
private var progressCurrent: Double = 0
private var progressTotal: Double = 100

var files = Files()

private var embeddingModel: any EmbeddingsProtocol = DistilbertEmbeddingsCPUandGPU()
private var distanceMetric: any DistanceMetricProtocol = CosineSimilarity()
private var currentTokenizer: any TokenizerProtocol = BertTokenizer()
private var currentSplitter: any TextSplitterProtocol = TokenSplitter(withTokenizer: BertTokenizer())

private var similarityIndex: SimilarityIndex?



public func updateIndexComponents(currentModel: EmbeddingModelType,
                                   comparisonAlgorithm: SimilarityMetricType,
                                   chunkMethod: TextSplitterType) {
    switch currentModel {
    case .distilbert:
        embeddingModel = DistilbertEmbeddings()
        currentTokenizer = BertTokenizer()
    case .minilmAll:
        embeddingModel = MiniLMEmbeddings()
        currentTokenizer = BertTokenizer()
    case .minilmMultiQA:
        embeddingModel = MultiQAMiniLMEmbeddings()
        currentTokenizer = BertTokenizer()
    case .native:
//        embeddingModel = NativeContextualEmbeddings()
        embeddingModel = DistilbertEmbeddings()
        currentTokenizer = NativeTokenizer()
    }

    switch comparisonAlgorithm {
    case .dotproduct:
        distanceMetric = DotProduct()
    case .cosine:
        distanceMetric = CosineSimilarity()
    case .euclidian:
        distanceMetric = EuclideanDistance()
    }

    switch chunkMethod {
    case .token:
        currentSplitter = TokenSplitter(withTokenizer: currentTokenizer)
    case .character:
        currentSplitter = CharacterSplitter(withSeparator: " ")
    case .recursive:
        currentSplitter = RecursiveTokenSplitter(withTokenizer: currentTokenizer)
    }
}

private func fetchFolderContents(url: URL) async {
    isLoading = true
    progressStage = "Scanning"
    progressTotal = Double(filePickerURLs.count)
    progressCurrent = 0
    var folderContentsToShow: [DiskItem] = []
    let elapsedTime = await clock.measure {
//        for url in filePickerURLs {
            progressCurrent += 1
            let isDirectory = Files.isDirectory(url: url)
            if isDirectory {
                folderItem = await files.scanDirectory(url: url)
                if let folder = folderItem {
                    folderContentsToShow.append(folder)
                }
            } else {
                if let childItem = await files.scanFile(url: url) {
                    folderContentsToShow.append(childItem)
                }
            }
//        }
    }
    folderScanTime = elapsedTime
    folderContents = folderContentsToShow.sorted(by: { item1, item2 in
        item1.diskSize > item2.diskSize
    })
    isLoading = false
}

func getTokenLength(_ text: String) -> Int {
    // Arbitrary code to get the token length of the given text
    return BertTokenizer().tokenize(text: text).count
}

private func splitTextFromFiles(chunkSize: Int, chunkOverlap: Int) async {
    isLoading = true
    progressStage = "Splitting"
    progressCurrent = 0

    let elapsedTime = clock.measure {
        guard let folderContents = folderContents else { return }
        let fileInfoArray: [Files.FileTextContents] = Files.extractText(fromDiskItems: folderContents)

        // Create an empty array to store the chunked FileTextContents objects
        var chunkedFileInfoArray: [Files.FileTextContents] = []
        var chunkTextArray: [String] = []
        var chunkTokensArray: [[String]] = []
        var chunkTextIds: [UUID] = []
        var chunkTextMetadata: [[String: String]] = []

        progressTotal = Double(fileInfoArray.count)
        for fileInfo in fileInfoArray {
            progressCurrent += 1
            let (chunks, tokens) = currentSplitter.split(text: fileInfo.text, chunkSize: chunkSize, overlapSize: chunkOverlap)
            for (idx, chunk) in chunks.enumerated() {
                // needs a fixed UUID every time
                let uuid = UUID()
                let newFileInfo = Files.FileTextContents(id: uuid, text: chunk, fileUrl: fileInfo.fileUrl)
                chunkedFileInfoArray.append(newFileInfo)
                chunkTextArray.append(chunk)
                chunkTokensArray.append(tokens?[idx] ?? currentTokenizer.tokenize(text: chunk))
                chunkTextIds.append(uuid)
                chunkTextMetadata.append(["source": fileInfo.fileUrl.absoluteString])
            }
        }

        // Calculate the total number of characters and tokens
        var totalCharacters = 0
        var totalTokens = 0
        for chunk in chunkTextArray {
            totalCharacters += chunk.count
        }
        for tokens in chunkTokensArray {
            totalTokens += tokens.count
        }

        // Calculate the average chunk text length
        let averageChunkTextLength = Double(totalCharacters) / Double(chunkTextArray.count)
        let averageChunkTokenLength = Double(totalTokens) / Double(chunkTokensArray.count)
        print("Average chunk character length: \(averageChunkTextLength)")
        print("Average chunk token length: \(averageChunkTokenLength)")

        print("Total characters: \(totalCharacters)")
        print("Total tokens: \(totalTokens)")

        folderCharactersCount = totalCharacters
        folderTokensCount = totalTokens

        print("Split \(fileInfoArray.count) files into \(chunkTextArray.count) chunks")

        folderTextIds = chunkTextIds.map { $0.uuidString }
        folderTextChunks = chunkTextArray
        folderTextMetadata = chunkTextMetadata
    }

    textSplitTime = elapsedTime

    isLoading = false
}

private func generateIndexFromChunks() async {
    guard let folderTextIds = folderTextIds,
        let folderTextChunks = folderTextChunks,
        let folderTextMetadata = folderTextMetadata else { return }

    isLoading = true
    progressStage = "Vectorizing"
    progressCurrent = 0.0
    progressTotal = Double(folderTextChunks.count)
    // Loads the model, can be done ahead of time
    let elapsedTime = await clock.measure {
        let index = await SimilarityIndex(model: embeddingModel, metric: distanceMetric)

        await index.addItems(ids: folderTextIds, texts: folderTextChunks, metadata: folderTextMetadata) { _ in
            progressCurrent += 1
        }

        print("Built index with \(index.indexItems.count) items")

        similarityIndex = index
    }

    embeddingElapsedTime = elapsedTime

    isLoading = false
}

public func searchIndexWithQuery(query: String, top: Int) async -> [SimilarityIndex.SearchResult]?{
    isSearching = true
    var searchResults:[SimilarityIndex.SearchResult]?
    let elapsedTime = await clock.measure {
        let results = await similarityIndex?.search(query, top: top, metric: distanceMetric)
        searchResults = results
    }

    searchElapsedTime = elapsedTime

    isSearching = false
    return searchResults
}

struct PineconeExport: Codable {
    let vectors: [PineconeIndexItem]
}

struct PineconeIndexItem: Codable {
    let id: String
    let metadata: [String: String]
    let values: [Float]
}

func exportIndex(_ index: SimilarityIndex, url: URL) {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted

    // Map items into Pinecone import structure
    var pineconeIndexItems: [PineconeIndexItem] = []
    for item in index.indexItems {
        let pineconeItem = PineconeIndexItem(
            id: item.id,
            metadata: [
                "text": item.text,
                "source": item.metadata["source"] ?? "",
            ],
            values: item.embedding
        )
        pineconeIndexItems.append(pineconeItem)
    }

    let pineconeExport = PineconeExport(vectors: pineconeIndexItems)

    do {
        let data = try encoder.encode(pineconeExport)
//        let savePanel = NSSavePanel()
//        savePanel.nameFieldStringValue = "\(index.indexName)_\(String(describing: currentModel))_\(index.dimension).json"
//        savePanel.allowedContentTypes = [.json]
//        savePanel.allowsOtherFileTypes = false
//        savePanel.canCreateDirectories = true
//
//        savePanel.begin { response in
//            if response == .OK, let url = savePanel.url {
//                do {
//                    try data.write(to: url)
//                } catch {
//                    print("Error writing index to file:", error)
//                }
//            }
//        }
        do {
            try data.write(to: url)
        } catch {
            print("Error writing index to file:", error)
        }
    } catch {
        print("Error encoding index:", error)
    }
}

func saveIndex(url: URL, name: String){
    guard let index = similarityIndex else { return }
    do{
        let res = try index.saveIndex(toDirectory: url, name: name)
    }catch{
        print(error)
    }
}

func BuildNewIndex(search_url: URL?, chunkSize: Int, chunkOverlap: Int) async{
    if search_url == nil
    {
        print("empty url")
        return
    }
    await fetchFolderContents(url: search_url!)
    await splitTextFromFiles(chunkSize: chunkSize, chunkOverlap: chunkOverlap)
    let elapsedTime = await clock.measure {
        await generateIndexFromChunks()
    }
    print("Elapsed generate index: \(elapsedTime)")
    
}

func loadExistingIndex(url: URL, name: String) async {
    let index = await SimilarityIndex(model: embeddingModel, metric: distanceMetric)
    do{
        let res = try index.loadIndex(fromDirectory: url, name: name)
        similarityIndex = index
    }catch{
        print(error)
    }
}

func main() async{
    print("Hello, Search Kit!")
    searchQuery = "The Birth of the Swatch"
//    await BuildNewIndex()
    await loadExistingIndex(url: URL(fileURLWithPath: "/Users/guinmoon/dev/alpaca_llama_etc/LLMFarm/RAG_Test/RAG_Test"), name: "RAG_test_index")
    let elapsedTime2 = await clock.measure {
        await searchIndexWithQuery(query: searchQuery, top: searchResultsCount)
    }
    print("Elapsed search: \(elapsedTime2)")
    let res = searchResults
    print(res)
//    saveIndex(url: URL(fileURLWithPath: "/Users/guinmoon/dev/alpaca_llama_etc/LLMFarm/RAG_Test/RAG_Test"), name: "RAG_test_index")
}
