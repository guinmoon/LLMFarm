//
//  SummaryIntent.swift
//  LLMFarm
//
//  Created by guinmoon on 16.10.2024.
//

import Foundation
import AppIntents
import llmfarm_core_cpp

struct LLMSummaryIntent: AppIntent {
    static let title: LocalizedStringResource = "Summarize text"
    static let description: LocalizedStringResource = "Create text summary with LLM"
    

    @Parameter(title: "Token Limit", default: 150)
    var token_limit: Int

    @Parameter(title: "Use history", default: false)
    var use_history: Bool
    
    @Parameter(title: "Chat")
    var chat: ShortcutsChatEntity?
    
    @Parameter(title: "Query")
    var query: String?
    
    
    /// Define the method that the system calls when it triggers this event.
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {

        var img_path:String? = nil
        

        if (query == nil){
            return .result(value: "Query is empty.")
        }
        if (chat == nil){
            return .result(value: "Please select chat.")
        }
        
        let trimmedQuery = query!.trimmingCharacters(in: .whitespacesAndNewlines) + "\n\n## Summary:\n"
        
        let res = await OneShortQuery(trimmedQuery,chat!.chat,token_limit,img_path:img_path,use_history: use_history)
        return .result(value: res)
        
    }
    
}
