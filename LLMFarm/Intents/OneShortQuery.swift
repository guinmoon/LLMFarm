//
//  OneShortQuery.swift
//  LLMFarm
//
//  Created by guinmoon on 18.11.2024.
//

import SwiftUI
import AppIntents
import SimilaritySearchKit
import SimilaritySearchKitDistilbert
import SimilaritySearchKitMiniLMAll
import SimilaritySearchKitMiniLMMultiQA
import llmfarm_core_cpp



@MainActor
func OneShortQuery(_ queryIn: String, _ chat: String, _ token_limit:Int,
                   img_path: String? = nil,
                   use_history: Bool = false,
                   useRag: Bool = false,
                   topRag: Int = 1) async ->  String{
    var result:String = ""
    var aiChatModel = AIChatModel()
    aiChatModel.chat_name = chat
    aiChatModel.ResetRAGUrl()
    var query = queryIn
    guard let res = aiChatModel.load_model_by_chat_name_prepare(chat,in_text:query, attachment:  nil) else {
        return "Chat load eror."
    }
    do{
        if !use_history{
            // aiChatModel.model_context_param.save_load_state = false
            aiChatModel.chat?.model?.contextParams.save_load_state = false
        }else{
            aiChatModel.messages = load_chat_history(chat + ".json") ?? []
            let requestMessage = Message(sender: .user, state: .typed, text: query, tok_sec: 0,
                                         attachment:img_path,attachment_type:"image")
            aiChatModel.messages.append(requestMessage)
            
            aiChatModel.chat?.model?.contextParams.state_dump_path = get_state_path_by_chat_name(chat) ?? ""
        }
        
        
        
        try aiChatModel.chat?.loadModel_sync()
        var system_prompt:String? = nil
        
        if aiChatModel.chat?.model?.contextParams.system_prompt != ""{
            system_prompt = aiChatModel.chat?.model?.contextParams.system_prompt ?? ""
            if (system_prompt != ""){
                system_prompt! += "\n"
            }
            //            aiChatModel.messages[aiChatModel.messages.endIndex - 1].header = aiChatModel.model_context_param.system_prompt
        }
        
        aiChatModel.chat?.model?.parse_skip_tokens()
        
        if useRag{
            await aiChatModel.LoadRAGIndex(ragURL: aiChatModel.ragUrl)
            let results = await searchIndexWithQuery(query: query, top: topRag)
            query = SimilarityIndex.exportLLMPrompt(query: query, results: results!)
        }
        
        var current_output: String = ""
        var current_token_count = 0
        try ExceptionCather.catchException {
            do{
                _ = try aiChatModel.chat?.model?.Predict(query,
                                                         {
                    str,time in
                    print("\(str)",terminator: "")
                    if !aiChatModel.check_stop_words(str, &current_output){
                        return true
                    }else{
                        current_output += str
                    }
                    current_token_count+=1
                    if current_token_count>token_limit{
                        return true
                    }
                    return false
                },system_prompt:system_prompt,img_path:img_path)
            }catch{
                print(error)
            }
        }
        if use_history{
            let message = Message(sender: .system, text: current_output,tok_sec: 0)
            aiChatModel.messages.append(message)
            aiChatModel.save_chat_history_and_state()
        }
        result = current_output
    }
    catch{
        return "Chat load error."
    }
    return result
}
