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

@MainActor
final class AIChatModel: ObservableObject {
    enum State {
        case none
        case loading
        case completed
    }
    @Published var AI_typing = 0
    public var chat: AI?
    public var modelURL: String
    public var maxToken = 512
    public var numberOfTokens = 0
    public var total_sec = 0.0
    public var predicting = false
    public var action_button_icon = "paperplane"
    public var model_loading = false
    //    public var model_name = "llama-7b-q5_1.bin"
    //    public var model_name = "stablelm-tuned-alpha-3b-ggml-model-q5_1.bin"
    public var model_name = ""
    public var chat_name = ""
//    public var avalible_models: [String]
    public var start_predicting_time = DispatchTime.now()

    //    public var title:String = ""
    
    @Published
    var state: State = .none
    
    @Published
    var messages: [Message] = []
    
    public init(){
        chat = nil
        modelURL = ""
//        avalible_models = []
    }
    
//    func _get_avalible_models(){
//        self.avalible_models = get_avalible_models()!
//    }
    
    public func load_model_by_chat_name(chat_name: String) -> Bool?{
        let chat_config = get_chat_info(chat_name)
        var model_sample_param = ModelSampleParams.default
        var model_context_param = ModelContextParams.default
        if (chat_config != nil){
            model_sample_param = get_model_sample_param_by_config(chat_config!)
            model_context_param = get_model_context_param_by_config(chat_config!)
        }else{
            return nil
        }
        let model_name = chat_config!["model"] as! String
        self.model_name = model_name
        if let m_name = get_path_by_model_name(model_name) {
            self.modelURL = m_name
        }else{
            return nil
        }
        self.model_loading = true
        self.chat = nil
        //            let a: URL = URL(filePath: modelURL)
        //            let res = a.startAccessingSecurityScopedResource()
        self.chat = AI(_modelPath: modelURL,_chatName: chat_name);
        if (self.modelURL==""){
            return nil
        }
        let model_url = URL(fileURLWithPath: model_name)
        let model_lowercase=model_url.lastPathComponent.lowercased()
        //            if (chat_config!["warm_prompt"] != nil){
        //                model_context_param.warm_prompt = chat_config!["warm_prompt"]! as! String
        //            }
        
        //Set mode linference and try to load model
        if (chat_config!["model_inference"] != nil){
            var model_load_res:Bool? = false
            if (chat_config!["use_metal"] != nil){
                model_context_param.use_metal = chat_config!["use_metal"] as! Bool
            }
            if (chat_config!["mlock"] != nil){
                model_context_param.useMlock = chat_config!["mlock"] as! Bool
            }
            if (chat_config!["mmap"] != nil){
                model_context_param.useMMap = chat_config!["mmap"] as! Bool
            }
            do{
                if chat_config!["model_inference"] as! String == "llama"{
                    if (chat_config!["grammar"] != nil && chat_config!["grammar"] as! String != "<None>" && chat_config!["grammar"] as! String != ""){
                        let grammar_path = get_grammar_path_by_name(chat_config!["grammar"] as! String)
                        model_context_param.grammar_path = grammar_path
                    }
                    if modelURL.hasSuffix(".gguf"){
                        try model_load_res = self.chat?.loadModel(ModelInference.LLama_gguf,contextParams: model_context_param)
                    }else{
                        try model_load_res = self.chat?.loadModel(ModelInference.LLama_bin,contextParams: model_context_param)
                    }
                }else if chat_config!["model_inference"] as! String == "gptneox" {
                    if modelURL.hasSuffix(".gguf"){
                        try model_load_res = self.chat?.loadModel(ModelInference.LLama_gguf,contextParams: model_context_param)
                    }else{
                        try model_load_res = self.chat?.loadModel(ModelInference.GPTNeox,contextParams: model_context_param)
                    }
                }else if chat_config!["model_inference"] as! String == "rwkv" {
                    try model_load_res = self.chat?.loadModel(ModelInference.RWKV,contextParams: model_context_param)
                }else if chat_config!["model_inference"] as! String == "gpt2" {
                    try model_load_res = self.chat?.loadModel(ModelInference.GPT2,contextParams: model_context_param)
                    self.chat?.model.reverse_prompt.append("<|endoftext|>")
                }else if chat_config!["model_inference"] as! String == "replit" {
                    try model_load_res = self.chat?.loadModel(ModelInference.Replit,contextParams: model_context_param)
                    self.chat?.model.reverse_prompt.append("<|endoftext|>")
                }else if chat_config!["model_inference"] as! String == "starcoder" {
                    if modelURL.hasSuffix(".gguf"){
                        try model_load_res = self.chat?.loadModel(ModelInference.LLama_gguf,contextParams: model_context_param)
                    }else{
                        try model_load_res = self.chat?.loadModel(ModelInference.Starcoder,contextParams: model_context_param)
                    }
                    self.chat?.model.reverse_prompt.append("<|endoftext|>")
                }
            }
            catch {
                print(error)
                
            }
        }
        if self.chat?.model == nil || self.chat?.model.context == nil{
            return nil
        }
        if (chat_config!["reverse_prompt"] != nil){
            let splited_revrse_prompt = String(chat_config!["reverse_prompt"]! as! String).components(separatedBy: [";"])
            for word in splited_revrse_prompt{
                let trimed_word = word.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimed_word==""{
                    continue
                }
                var exist = false
                for r_word in self.chat!.model.reverse_prompt{
                    if r_word == trimed_word{
                        exist = true
                        break
                    }
                }
                if !exist{
                    self.chat?.model.reverse_prompt.append(trimed_word)
                }
            }
        }
        self.chat?.model.sampleParams = model_sample_param
        self.chat?.model.contextParams = model_context_param
        print(model_sample_param)
        print(model_context_param)
        //Set prompt model if in config or try to set promt format by filename
        if (chat_config!["prompt_format"] != nil && chat_config!["prompt_format"]! as! String != "auto"
            && chat_config!["prompt_format"]! as! String != "{{prompt}}"){
            self.chat?.model.custom_prompt_format = chat_config!["prompt_format"]! as! String
            self.chat?.model.promptFormat = .Custom
        }
        else{
            if (model_lowercase.contains("dolly")){
                self.chat?.model.promptFormat = .Dolly_b3;
            }else if (model_lowercase.contains("stable")){
                self.chat?.model.promptFormat = .StableLM_Tuned
                self.chat?.model.reverse_prompt.append("<|USER|>")
            }else if ((chat_config!["model_inference"] != nil && chat_config!["model_inference"]! as! String == "llama") ||
                      model_lowercase.contains("llama") ||
                      model_lowercase.contains("alpaca") ||
                      model_lowercase.contains("vic") ){
                //            self.chat?.model.promptStyle = .LLaMa
                self.chat?.model.promptFormat = .LLaMa
            }else if (model_lowercase.contains("rp-")&&model_lowercase.contains("chat")){
                self.chat?.model.promptFormat = .RedPajama_chat
            }else{
                self.chat?.model.promptFormat = .None
            }
        }
        self.model_loading = false
        return true
    }
    
    func prepare(_ model_name:String, _ chat_name:String) async {
        state = .loading
        self.model_name = model_name
        self.chat_name = chat_name
        //        if self.chat == nil{
        //            let res=self.load_model_by_name(model_name:model_name)
        //            if (res == nil){
        //                let message = Message(sender: .system, text: "Failed to load model.")
        //                messages.append(message)
        //            }
        //        }
        state = .completed
    }
    
    public func stop_predict(is_error:Bool=false){
        self.chat?.flagExit = true
        self.total_sec = Double((DispatchTime.now().uptimeNanoseconds - self.start_predicting_time.uptimeNanoseconds)) / 1_000_000_000
        if messages.count>0{
            if self.messages[messages.endIndex-1].state == .predicting ||
                self.messages[messages.endIndex-1].state == .none{
                self.messages[messages.endIndex-1].state = .predicted(totalSecond: self.total_sec)
            }
            if is_error{
                self.messages[messages.endIndex-1].state = .error
            }
        }
        self.predicting = false
        self.numberOfTokens = 0
        self.action_button_icon = "paperplane"
        self.AI_typing = 0
        save_chat_history(self.messages,self.chat_name+".json")
    }
    
    public func process_predicted_str(_ str: String, _ time: Double,_ message: inout Message, _ messageIndex: Int) -> Bool
    {
        var check = true
        for stop_word in self.chat?.model.reverse_prompt ?? [] {
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
            if (self.numberOfTokens>self.maxToken){
                self.stop_predict()
            }
        }else{
            print("chat ended.")
        }
        return check
    }
    
    public func send(message text: String) async {
        let requestMessage = Message(sender: .user, state: .typed, text: text)
        messages.append(requestMessage)
        self.AI_typing += 1
        if self.chat != nil{
            if self.chat_name != self.chat?.chatName{
                self.chat = nil
            }
        }
        if self.chat == nil{
            state = .loading
            let res=self.load_model_by_chat_name(chat_name:self.chat_name)
            if (res == nil){
                let message = Message(sender: .system, text: "Failed to load model.")
                messages.append(message)
                state = .completed
                stop_predict(is_error: true)
                return
            }
            state = .completed
        }else{
            self.chat?.chatName = self.chat_name
        }
        self.chat?.flagExit = false
        do {
            var message = Message(sender: .system, text: "")
            messages.append(message)
            let messageIndex = messages.endIndex - 1
            
            self.numberOfTokens = 0
            self.total_sec = 0.0
            self.predicting = true
            self.action_button_icon = "stop.circle"
            var check = true
            self.start_predicting_time = DispatchTime.now()
            self.chat?.conversation(text, { str, time in
                check = self.process_predicted_str(str, time, &message, messageIndex)
            }, {
                final_str in
                print(final_str)
                self.AI_typing = 0
                self.total_sec = Double((DispatchTime.now().uptimeNanoseconds - self.start_predicting_time.uptimeNanoseconds)) / 1_000_000_000
                if (self.chat_name == self.chat?.chatName && self.chat?.flagExit != true){
                    message.state = .predicted(totalSecond: self.total_sec)
                    self.messages[messageIndex] = message
                }else{
                    print("chat ended.")
                }
                self.predicting = false
                self.numberOfTokens = 0
                self.action_button_icon = "paperplane"
                if final_str == "/[Error]/"{
                    let message = Message(sender: .system, state: .error, text: "Eval Error")
                    self.messages.append(message)
                }
                save_chat_history(self.messages,self.chat_name+".json")
            })
            
            
        } catch {
            let message = Message(sender: .system, state: .error, text: error.localizedDescription)
            messages.append(message)
        }
    }
}
