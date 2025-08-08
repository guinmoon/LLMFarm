//
//  SummaryIntent.swift
//  LLMFarm
//
//  Created by guinmoon on 16.10.2024.
//

import Foundation
import AppIntents
import PDFKit
import SwiftUI
import llmfarm_core_cpp



struct LLMDocQueryIntent: AppIntent {
    static let title: LocalizedStringResource = "Question to Doc"
    static let description: LocalizedStringResource = "Add document to RAG index and run LLM query"
    
    @Parameter(title: "Token Limit", default: 150)
    var token_limit: Int
    
    @Parameter(title: "Max RAG answers count", default: 1)
    var topRag: Int
    
    @Parameter(title: "Use history", default: false)
    var use_history: Bool
    
    @Parameter(title: "Chat")
    var chat: ShortcutsChatEntity?
    
    @Parameter(title: "Query")
    var query: String?
    
    @Parameter(
        title: "Document",
        description: "Single PDF document for RAG",
        supportedTypeIdentifiers: ["public.pdf", "com.adobe.pdf"],
        inputConnectionBehavior: .connectToPreviousIntentResult
    )
    var docUrl: IntentFile?
    
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        // Расширенная отладка
        print("Received docUrl: \(String(describing: docUrl))")
        print("Filename: \(docUrl?.filename ?? "No filename")")
        
        // Попытка получить данные несколькими способами
        //        var pdfData: Data? = nil
        
        guard let query = query, !query.isEmpty else {
            return .result(value: "Query is empty.")
        }
        
        guard let chat = chat else {
            return .result(value: "Please select chat.")
        }
        
        
        let chat_config = getChatInfo(chat.chat)
        
        
        if docUrl != nil && docUrl!.fileURL != nil{
            print(chat.chat)
            
            let ragDir = GetRagDirRelPath(chat_name: chat.chat)
            let docsDir = ragDir + "/docs"
            let ragUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(ragDir) ?? URL(fileURLWithPath: "")
            let newPath = CopyFileToSandbox(url: docUrl!.fileURL! ,dest:docsDir)
            await addFileToIndex(fileURL: docUrl!.fileURL!, ragURL: ragUrl,
                                 currentModel: getCurrentModelFromStr(chat_config?["current_model"] as? String ?? ""),
                                 comparisonAlgorithm: getComparisonAlgorithmFromStr(chat_config?["comparison_algorithm"] as? String ?? ""),
                                 chunkMethod: getChunkMethodFromStr(chat_config?["chunk_method"] as? String ?? ""))
        }
        else{
            return .result(value: "Error adding document to RAG index")
        }
        print("added to index")
        
        var trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let res = await OneShortQuery(trimmedQuery, chat.chat, token_limit,
                                      use_history: use_history,
                                      useRag: true,
                                      topRag: topRag)
        return .result(value: res)
    }
    
    
}
