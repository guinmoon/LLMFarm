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
        var pdfData: Data? = nil
        
        let chat_config = getChatInfo(chat?.chat ?? "")
        
        
        if docUrl != nil && docUrl!.fileURL != nil{
            print(chat?.chat)
            
            let ragDir = GetRagDirRelPath(chat_name: chat?.chat ?? "") + "/docs"
            let ragUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(ragDir) ?? URL(fileURLWithPath: "")
            let newPath = CopyFileToSandbox(url: docUrl!.fileURL! ,dest:ragDir)
            await addFileToIndex(fileURL: docUrl!.fileURL!, ragURL: ragUrl,
                                currentModel: getCurrentModelFromStr(chat_config?["current_model"] as? String ?? ""),
                                comparisonAlgorithm: getComparisonAlgorithmFromStr(chat_config?["comparison_algorithm"] as? String ?? ""),
                                chunkMethod: getChunkMethodFromStr(chat_config?["chunk_method"] as? String ?? ""))
        }
        print("added to index")
        // Способ 1: Прямое получение данных
        pdfData = docUrl?.data
        
        // Способ 2: Попытка загрузки по URL
        if pdfData == nil, let url = docUrl?.fileURL {
            pdfData = try? Data(contentsOf: url)
        }
        
        // Способ 3: Использование URLSession для загрузки
        if pdfData == nil, let url = docUrl?.fileURL {
            do {
                pdfData = try await URLSession.shared.data(from: url).0
            } catch {
                print("Error loading file via URLSession: \(error)")
            }
        }
        
        // Проверка данных
        guard let pdfData = pdfData else {
            print("No PDF data found")
            return .result(value: "No PDF document selected.")
        }
        
        // Извлечение текста
        var extractedText: String? = nil
        if let pdfDocument = PDFDocument(data: pdfData) {
            extractedText = extractPDFText(from: pdfDocument)
            print("Extracted text length: \(extractedText?.count ?? 0)")
        } else {
            print("Failed to create PDFDocument")
            return .result(value: "Invalid PDF document.")
        }
        
        // Проверки входных данных
        guard let query = query, !query.isEmpty else {
            return .result(value: "Query is empty.")
        }
        
        guard let chat = chat else {
            return .result(value: "Please select chat.")
        }
        
        // Подготовка запроса с текстом документа
        var trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let pdfText = extractedText, !pdfText.isEmpty {
            trimmedQuery += "\n\n## Document Context:\n\(pdfText)\n\n## Summary:\n"
        } else {
            print("No text extracted from PDF")
        }
        
        // Выполнение запроса
        let res = extractedText ?? "no text"
//        showPDFTextSheet(text: res)
//        let res = one_short_query(trimmedQuery, chat.chat, token_limit, use_history: use_history)
        return .result(value: res)
    }
    
    // Метод извлечения текста из PDF с расширенной обработкой
    private func extractPDFText(from pdfDocument: PDFDocument) -> String {
        var fullText = ""
        
        for pageIndex in 0..<pdfDocument.pageCount {
            if let page = pdfDocument.page(at: pageIndex),
               let pageContent = page.string {
                fullText += pageContent + "\n"
            }
        }
        
        // Обрезка длинного текста, если необходимо
        let maxLength = 10000 // Например, ограничение в 10000 символов
        return String(fullText.prefix(maxLength))
    }

}
