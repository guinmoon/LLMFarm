//
//  ChatViewModel.swift
//  AlpacaChatApp
//
//  Created by Yoshimasa Niwa on 3/19/23.
//

import Foundation
import SwiftUI
import os
import llmfarm_core

private extension Duration {
    var seconds: Double {
        Double(components.seconds) + Double(components.attoseconds) / 1.0e18
    }
}

var AIChatModel_obj_ptr:UnsafeMutableRawPointer? = nil

@MainActor
final class AIChatModel: ObservableObject {
    
    enum State {
        case none
        case loading
        case completed
    }
    
    public var chat: AI?
    public var modelURL: String
    public var model_sample_param: ModelSampleParams = ModelSampleParams.default
    public var model_context_param:ModelAndContextParams = ModelAndContextParams.default
    
    //    public var maxToken = 512
    public var numberOfTokens = 0
    public var total_sec = 0.0
    public var action_button_icon = "paperplane"
    public var model_loading = false
    //    public var model_name = "llama-7b-q5_1.bin"
    //    public var model_name = "stablelm-tuned-alpha-3b-ggml-model-q5_1.bin"
    public var model_name = ""
    public var chat_name = ""
    //    public var avalible_models: [String]
    public var start_predicting_time = DispatchTime.now()
    public var first_predicted_token_time = DispatchTime.now()
    public var tok_sec:Double = 0.0
    
    //    public var title:String = ""
    
    @Published var predicting = false
    @Published var AI_typing = 0
    @Published var state: State = .none
    @Published var messages: [Message] = []
    
    public init(){
        chat = nil
        modelURL = ""
        //        avalible_models = []
    }
    
    //    func _get_avalible_models(){
    //        self.avalible_models = get_avalible_models()!
    //    }
    
    
    
    public func load_model_by_chat_name(chat_name: String) throws -> Bool?{
        self.model_loading = true
        
        let chat_config = get_chat_info(chat_name)
        if (chat_config == nil){
            return nil
        }
        if (chat_config!["model_inference"] == nil || chat_config!["model"] == nil){
            return nil
        }
        
        self.model_name = chat_config!["model"] as! String
        if let m_url = get_path_by_short_name(self.model_name) {
            self.modelURL = m_url
        }else{
            return nil
        }
        
        if (self.modelURL==""){
            return nil
        }
        
        model_sample_param = ModelSampleParams.default
        model_context_param = ModelAndContextParams.default
        model_sample_param = get_model_sample_param_by_config(chat_config!)
        model_context_param = get_model_context_param_by_config(chat_config!)
        
        // let model_lowercase=URL(fileURLWithPath: model_name).lastPathComponent.lowercased()
        //         if (chat_config!["warm_prompt"] != nil){
        //             model_context_param.warm_prompt = chat_config!["warm_prompt"]! as! String
        //         }
        
        if (chat_config!["grammar"] != nil && chat_config!["grammar"] as! String != "<None>" && chat_config!["grammar"] as! String != ""){
            let grammar_path = get_grammar_path_by_name(chat_config!["grammar"] as! String)
            model_context_param.grammar_path = grammar_path
        }
        
        self.chat = nil
        self.chat = AI(_modelPath: modelURL,_chatName: chat_name);
        
        do{
            try _ = self.chat?.loadModel(model_context_param.model_inference,contextParams: model_context_param)
        }
        catch {
            print(error)
            throw error
        }
        
        if self.chat?.model == nil || self.chat?.model.context == nil{
            return nil
        }
        
        self.chat?.model.sampleParams = model_sample_param
        self.chat?.model.contextParams = model_context_param
        //Set prompt model if in config or try to set promt format by filename
        
        print(model_sample_param)
        print(model_context_param)
        self.model_loading = false
        return true
    }
    
//    func prepare(_ model_name:String, _ chat_name:String) async {
//
//        self.model_name = model_name
//        self.chat_name = chat_name
//
//    }
    
    public func stop_predict(is_error:Bool=false){
        self.chat?.flagExit = true
        self.total_sec = Double((DispatchTime.now().uptimeNanoseconds - self.start_predicting_time.uptimeNanoseconds)) / 1_000_000_000
        if messages.count>0{
            if self.messages[messages.endIndex-1].state == .predicting ||
                self.messages[messages.endIndex-1].state == .none{
                self.messages[messages.endIndex-1].state = .predicted(totalSecond: self.total_sec)
                self.messages[messages.endIndex-1].tok_sec = Double(self.numberOfTokens)/self.total_sec
            }
            if is_error{
                self.messages[messages.endIndex-1].state = .error
            }
        }
        self.predicting = false
        self.tok_sec = Double(self.numberOfTokens)/self.total_sec
        self.numberOfTokens = 0
        self.action_button_icon = "paperplane"
        self.AI_typing = 0
        save_chat_history(self.messages,self.chat_name+".json")
    }
    
    public func process_predicted_str(_ str: String, _ time: Double,_ message: inout Message, _ messageIndex: Int) -> Bool
    {
        var check = true
        for stop_word in self.model_context_param.reverse_prompt{
            if str == stop_word {
                self.stop_predict()
                check = false
                break
            }
            if message.text.hasSuffix(stop_word) {
                self.stop_predict()
                check = false
                if stop_word.count>0 && message.text.count>stop_word.count{
                    message.text.removeLast(stop_word.count)
                }
            }
        }
        if (check &&
            self.chat?.flagExit != true &&
            self.chat_name == self.chat?.chatName){
            
            message.state = .predicting
            message.text += str
            //                    self.AI_typing += str.count
            self.AI_typing += 1
            var updatedMessages = self.messages
            updatedMessages[messageIndex] = message
            self.messages = updatedMessages
            self.numberOfTokens += 1
            self.total_sec += time
            //            if (self.numberOfTokens>self.maxToken){
            //                self.stop_predict()
            //            }
        }else{
            print("chat ended.")
        }
        return check
    }
    
    public func send(message text: String) async {
        
        let requestMessage = Message(sender: .user, state: .typed, text: text, tok_sec: 0)
        self.messages.append(requestMessage)
        self.AI_typing += 1
        
        
        if self.chat != nil{
            if self.chat_name != self.chat?.chatName{
                self.chat = nil
            }
        }
        
        if self.chat == nil{
            self.state = .loading
            do{
                var res:Bool? = nil
                try await Task {
                    res=try self.load_model_by_chat_name(chat_name:self.chat_name)
                }.value
                if (res == nil){
                    self.messages.append(Message(sender: .system, text: "Failed to load model.", tok_sec: 0))
                    self.state = .completed
                    self.stop_predict(is_error: true)
                    return
                }
            }catch{
                self.messages.append(Message(sender: .system, text: "\(error)", tok_sec: 0))
                self.state = .completed
                self.stop_predict(is_error: true)
                return
            }
        }
        
        self.state = .completed
        self.chat?.chatName = self.chat_name
        self.chat?.flagExit = false
        var message = Message(sender: .system, text: "",tok_sec: 0)
        self.messages.append(message)
        let messageIndex = self.messages.endIndex - 1
        self.numberOfTokens = 0
        self.total_sec = 0.0
        self.predicting = true
        self.action_button_icon = "stop.circle"
        self.start_predicting_time = DispatchTime.now()
        
        self.chat?.conversation(text, { str, time in
            _ = self.process_predicted_str(str, time, &message, messageIndex)
        }, 
        {
            final_str in
            print(final_str)
            self.AI_typing = 0
            self.total_sec = Double((DispatchTime.now().uptimeNanoseconds - self.start_predicting_time.uptimeNanoseconds)) / 1_000_000_000
            if (self.chat_name == self.chat?.chatName && self.chat?.flagExit != true){
                message.state = .predicted(totalSecond: self.total_sec)
                if self.tok_sec != 0{
                    message.tok_sec = self.tok_sec
                }
                else{
                    message.tok_sec = Double(self.numberOfTokens)/self.total_sec
                }
                self.messages[messageIndex] = message
            }else{
                print("chat ended.")
            }
            self.predicting = false
            self.numberOfTokens = 0
            self.action_button_icon = "paperplane"
            if final_str.hasPrefix("[Error]"){
                self.messages.append(Message(sender: .system, state: .error, text: "Eval \(final_str)", tok_sec: 0))
            }
            save_chat_history(self.messages,self.chat_name+".json")
        })
    }
}
