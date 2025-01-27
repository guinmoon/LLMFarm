//
//  ChatViewModel.swift
//
//  Created by Artem Savkin
//

import Foundation
import SwiftUI
import SimilaritySearchKit
import SimilaritySearchKitDistilbert
import SimilaritySearchKitMiniLMAll
import SimilaritySearchKitMiniLMMultiQA
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
        case ragIndexLoading
        case ragSearch
        case completed
    }
    
    public var chat: AI?
    public var modelURL: String
    // public var model_sample_param: ModelSampleParams = ModelSampleParams.default
    // public var model_context_param: ModelAndContextParams = ModelAndContextParams.default
    public var numberOfTokens = 0
    public var total_sec = 0.0
    public var action_button_icon = "paperplane"
    public var model_loading = false
    public var model_name = ""
    public var chat_name = ""
    //    public var avalible_models: [String]
    public var start_predicting_time = DispatchTime.now()
    public var first_predicted_token_time = DispatchTime.now()
    public var tok_sec:Double = 0.0
    public var ragIndexLoaded: Bool = false
    private var state_dump_path:String = ""

//    public var conv_finished_group = DispatchGroup()

    private var title_backup = ""

    private var messages_lock = NSLock()

    public var ragUrl:URL
    private var ragTop: Int = 3
    private var chunkSize: Int = 256
    private var chunkOverlap: Int = 100
    private var currentModel: EmbeddingModelType = .minilmMultiQA
    private var comparisonAlgorithm: SimilarityMetricType = .dotproduct
    private var chunkMethod: TextSplitterType = .recursive
    
//    @Published var llmStatus = ""
    @Published var predicting = false
    @Published var AI_typing = 0
    @Published var state: State = .none
    @Published var messages: [Message] = []
    @Published var load_progress:Float = 0.0
    @Published var Title: String = ""
    @Published var is_mmodal: Bool = false
    @Published var cur_t_name: String = ""
    @Published var cur_eval_token_num: Int = 0
    @Published var query_tokens_count: Int = 0
    
    public init(){
        chat = nil
        modelURL = ""
//        let ragDir = "documents/"+(self.chat_name == "" ? "tmp_chat": self.chat_name )
        let ragDir = GetRagDirRelPath(chat_name: self.chat_name)
        ragUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(ragDir) ?? URL(fileURLWithPath: "")
    }
    
    
    public func ResetRAGUrl(){
        let ragDir = GetRagDirRelPath(chat_name: self.chat_name)
        ragUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(ragDir) ?? URL(fileURLWithPath: "")
    }
    
//    @MainActor

    private func model_load_progress_callback(_ progress:Float) -> Bool{
        DispatchQueue.main.async {
            self.load_progress = progress
//                    print(self.load_progress)
        }
        return true
    }
    
    private func eval_callback(_ t:Int) -> Bool{
        DispatchQueue.main.async {
            // self.cur_t_name = t_name.description
            if t == 0{
                self.cur_eval_token_num += 1
            }
//            print(self.cur_t_name)
        }
        return false
    }

    private func after_model_load(_ load_result: String,
                                  in_text:String,
                                  attachment: String? = nil,
                                  attachment_type: String? = nil){
        if load_result != "[Done]" ||
            self.chat?.model == nil || 
            self.chat?.model!.context == nil {
            self.finish_load(append_err_msg: true, msg_text: "Load Model Error: \(load_result)")
            return
        }            

        self.finish_load()
        //Set prompt model if in config or try to set promt format by filename
        
        print(self.chat?.model?.contextParams)
        print(self.chat?.model?.sampleParams)
        self.model_loading = false
        var system_prompt:String? = nil
        if self.chat?.model?.contextParams.system_prompt != "" && self.chat?.model?.nPast == 0{
            system_prompt = self.chat?.model?.contextParams.system_prompt ?? " " + "\n"
            self.messages[self.messages.endIndex - 1].header = self.chat?.model?.contextParams.system_prompt ?? ""
        }
        self.chat?.model?.parse_skip_tokens()
        Task{
            await self.Send(message: in_text, 
                            append_user_message:false,
                            system_prompt:system_prompt,
                            attachment:attachment,
                            attachment_type:attachment_type)
        }
    }
    
    public func hard_reload_chat(){
        self.remove_dump_state()
        if self.chat != nil && self.chat?.model != nil{
            self.chat!.model!.contextParams.save_load_state = false
        }
        self.chat = nil
    }
    
    public func remove_dump_state(){        
        if FileManager.default.fileExists(atPath: self.state_dump_path){
            try? FileManager.default.removeItem(atPath: self.state_dump_path)
        }
    }

    public func reload_chat(_ chat_selection: Dictionary<String, String>){
        self.stop_predict()
//        self.model_name = model_name        
        self.chat_name = chat_selection["chat"] ?? "Not selected"
        self.Title = chat_selection["title"] ?? ""
        self.is_mmodal =  chat_selection["mmodal"] ?? "" == "1"
        messages_lock.lock()
        self.messages = []        
        self.messages = load_chat_history(chat_selection["chat"]!+".json") ?? []
        messages_lock.unlock()
        self.state_dump_path = get_state_path_by_chat_name(chat_name) ?? ""
        ResetRAGUrl()
        
        self.ragIndexLoaded = false
        self.AI_typing = -Int.random(in: 0..<100000)
    }

    public  func update_chat_params(){
        let chat_config = getChatInfo(self.chat?.chatName ?? "")
        if (chat_config == nil){
            return
        }
        // self.model_sample_param = get_model_sample_param_by_config(chat_config!)
        // self.model_context_param = get_model_context_param_by_config(chat_config!)
        // self.chat?.model?.sampleParams = self.model_sample_param
        // self.chat?.model?.contextParams = self.model_context_param
        self.chat?.model?.contextParams = get_model_context_param_by_config(chat_config!)
        self.chat?.model?.sampleParams = get_model_sample_param_by_config(chat_config!)        
    }
    
    public func load_model_by_chat_name_prepare(_ chat_name: String,in_text:String, 
                                                attachment: String? = nil,
                                                attachment_type: String? = nil) -> Bool?{
        let chat_config = getChatInfo(chat_name)
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
        
        var model_sample_param = ModelSampleParams.default
        var model_context_param = ModelAndContextParams.default
        model_sample_param = get_model_sample_param_by_config(chat_config!)
        model_context_param = get_model_context_param_by_config(chat_config!)
        
        if (chat_config!["grammar"] != nil && chat_config!["grammar"] as! String != "<None>" && chat_config!["grammar"] as! String != ""){
            let grammar_path = get_grammar_path_by_name(chat_config!["grammar"] as! String)
            model_context_param.grammar_path = grammar_path
        }

        // RAG
        self.chunkSize = chat_config?["chunk_size"] as? Int ?? self.chunkSize
        self.chunkOverlap = chat_config?["chunk_overlap"] as? Int ?? self.chunkOverlap
        self.ragTop = chat_config?["rag_top"] as? Int ?? self.ragTop
        if (chat_config!["current_model"] != nil){
            self.currentModel = getCurrentModelFromStr(chat_config?["current_model"] as? String ?? "")
        }
        if (chat_config!["comparison_algorithm"] != nil){ 
            self.comparisonAlgorithm =  getComparisonAlgorithmFromStr(chat_config?["comparison_algorithm"] as? String ?? "")
        }
        if (chat_config!["chunk_method"] != nil){ 
            self.chunkMethod =  getChunkMethodFromStr(chat_config?["chunk_method"] as? String ?? "")
        }
        
        AIChatModel_obj_ptr = nil
        self.chat = nil
        self.chat = AI(_modelPath: modelURL,_chatName: chat_name);
        if self.chat == nil{
            return nil
        }
        self.chat?.initModel(model_context_param.model_inference,contextParams: model_context_param)
        if self.chat?.model == nil{
            return nil
        }
        self.chat?.model?.sampleParams = model_sample_param
        self.chat?.model?.contextParams = model_context_param
        
        return true
    }

    public func load_model_by_chat_name(_ chat_name: String,
                                        in_text:String,
                                        attachment: String? = nil,
                                        attachment_type: String? = nil) -> Bool?{
        self.model_loading = true
//        guard let _ = load_model_by_chat_name_prepare(chat_name,
//                                                      in_text:in_text,
//                                                      attachment:attachment,
//                                                      attachment_type: attachment_type)
//        else {
//            return nil;
//        }
        
        if self.chat?.model?.contextParams.save_load_state == true {
            self.chat?.model?.contextParams.state_dump_path = get_state_path_by_chat_name(chat_name) ?? ""
        }
        
        self.chat?.model?.modelLoadProgressCallback = { progress in
            return self.model_load_progress_callback(progress)
        }
        self.chat?.model?.modelLoadCompleteCallback = {  load_result in
            self.chat?.model?.evalCallback = self.eval_callback
            self.after_model_load(load_result,in_text:in_text,attachment:attachment,attachment_type:attachment_type)
        }
        self.chat?.loadModel()
            
        return true
    }
    
    
    private func update_last_message(_ message: inout Message){
        messages_lock.lock()
        if let _ = messages.last {
            messages[messages.endIndex-1] = message
        }
        messages_lock.unlock()
    }

    public func save_chat_history_and_state(){
        save_chat_history(self.messages,self.chat_name+".json")
        if self.chat != nil && self.chat?.model != nil {
            self.chat?.model?.save_state()
        }
    }
    
    public func stop_predict(is_error:Bool=false){
        self.chat?.flagExit = true
        self.total_sec = Double((DispatchTime.now().uptimeNanoseconds - self.start_predicting_time.uptimeNanoseconds)) / 1_000_000_000        
        if let last_message =  messages.last{
            messages_lock.lock()
            if last_message.state == .predicting || last_message.state == .none{
                messages[messages.endIndex-1].state = .predicted(totalSecond: self.total_sec)
                messages[messages.endIndex-1].tok_sec = Double(self.numberOfTokens)/self.total_sec
            }
            if is_error{
                messages[messages.endIndex-1].state = .error
            }
            messages_lock.unlock()
        }
        self.predicting = false
        self.tok_sec = Double(self.numberOfTokens)/self.total_sec
        self.numberOfTokens = 0
        self.action_button_icon = "paperplane"
        self.AI_typing = 0
        self.save_chat_history_and_state()
        if is_error{
            self.chat = nil
        }
        
    }
    
    public func check_stop_words(_ token:String,_ message_text: inout String) -> Bool{
        var check = true
        for stop_word in self.chat?.model?.contextParams.reverse_prompt ?? []{
            if token == stop_word {
                return false
            }	
            if message_text.hasSuffix(stop_word) {
                if stop_word.count>0 && message_text.count>stop_word.count{
                    message_text.removeLast(stop_word.count)
                }
                return false
            }
        }
        return check
    }
    
    public func process_predicted_str(_ str: String, _ time: Double,_ message: inout Message/*, _ messageIndex: Int*/) -> Bool
    {
        let check = check_stop_words(str,&message.text)
        if !check {
            self.stop_predict()
        }
        if (check &&
            self.chat?.flagExit != true &&
            self.chat_name == self.chat?.chatName){
            message.state = .predicting
            message.text += str
            self.AI_typing += 1            
            update_last_message(&message)
            self.numberOfTokens += 1

        }else{
            print("chat ended.")
        }
        return check
    }
    
    public func finish_load(append_err_msg:Bool = false, msg_text:String = ""){
        if append_err_msg {
            self.messages.append(Message(sender: .system, state: .error, text: msg_text, tok_sec: 0))
            self.stop_predict(is_error: true)
        }
        self.state = .completed        
        self.Title = self.title_backup
    }

    public func finish_completion(_ final_str:String,_ message: inout Message/*, _ messageIndex: Int*/){
//        final_str in // Finish predicting 
        self.cur_t_name = ""
        self.load_progress = 0
        print(final_str)
        self.AI_typing = 0
        self.total_sec = Double((DispatchTime.now().uptimeNanoseconds - self.start_predicting_time.uptimeNanoseconds)) / 1_000_000_000
        if (self.chat_name == self.chat?.chatName && self.chat?.flagExit != true){
            if self.tok_sec != 0{
                message.tok_sec = self.tok_sec
            }
            else{
                message.tok_sec = Double(self.numberOfTokens)/self.total_sec
            }
            message.state = .predicted(totalSecond: self.total_sec)
            update_last_message(&message)
        }else{
            print("chat ended.")
        }
        self.predicting = false
        self.numberOfTokens = 0
        self.action_button_icon = "paperplane"
        if final_str.hasPrefix("[Error]"){
            self.messages.append(Message(sender: .system, state: .error, text: "Eval \(final_str)", tok_sec: 0))
        }
//        self.conv_finished_group.leave()
//        save_chat_history(self.messages,self.chat_name+".json")
        self.save_chat_history_and_state()
    }

    
    public func LoadRAGIndex(ragURL: URL) async {
        updateIndexComponents(currentModel:currentModel,comparisonAlgorithm:comparisonAlgorithm,chunkMethod:chunkMethod)
        await loadExistingIndex(url: ragURL, name: "RAG_index")
        ragIndexLoaded = true
    }
    
    public func RegenerateLstMessage(){
//        self.messages.removeLast()
    }
    
    public func GenerateRagLLMQuery(_ inputText:String,
                                     _ searchResultsCount:Int,
                                     _ ragURL:URL,
                                     message in_text: String,
                                     append_user_message:Bool = true,
                                     system_prompt:String? = nil,
                                     attachment: String? = nil,
                                     attachment_type: String? = nil)  {
        
        let aiQueue = DispatchQueue(label: "LLMFarm-RAG", qos: .userInitiated, attributes: .concurrent, autoreleaseFrequency: .inherit, target: nil)
        
        
        aiQueue.async {
            Task {
                if await !self.ragIndexLoaded {
                    await self.LoadRAGIndex(ragURL: ragURL)
                }
                DispatchQueue.main.async {
                    self.state = .ragSearch
                }
                let results = await searchIndexWithQuery(query: inputText, top: searchResultsCount)
                let llmPrompt = SimilarityIndex.exportLLMPrompt(query: inputText, results: results!)
                await self.Send(message: llmPrompt,
                                 append_user_message: false,
                                 system_prompt: system_prompt,
                                 attachment: llmPrompt,
                                 attachment_type:"rag")
            }
        }
    }

    public func SetSendMsgTokensCount(_ count:Int){
        
    }
    
    public func SetGeneratedMsgTokensCount(_ count:Int){
        
    }
    
    public func Send(message in_text: String,
                     append_user_message:Bool = true,
                     system_prompt:String? = nil, 
                     attachment: String? = nil,
                     attachment_type: String? = nil,
                     useRag: Bool = false)  async {
//        self.llmStatus = ""
        let text = in_text
        self.AI_typing += 1
        
        if append_user_message{
//            var attachment_type:String? = nil
//            if attachment != nil{
//                attachment_type = "img"
//            }
            let requestMessage = Message(sender: .user, state: .typed, text: text, tok_sec: 0,
                                        attachment:attachment,attachment_type:attachment_type)
            self.messages.append(requestMessage)
        }
        
        if self.chat != nil{
            if self.chat_name != self.chat?.chatName{
                self.chat = nil
            }
        }
        
        if self.chat == nil {
            guard let _ = load_model_by_chat_name_prepare(chat_name,
                                                          in_text:in_text,
                                                          attachment:attachment,
                                                          attachment_type: attachment_type)
            else {
                return ;
            }
        }
        
        if useRag {
            self.state = .ragIndexLoading
            self.GenerateRagLLMQuery(in_text,
                                    self.ragTop, self.ragUrl,
                                    message: in_text,
                                    append_user_message:append_user_message,
                                    system_prompt:system_prompt,
                                    attachment: attachment,
                                    attachment_type:attachment_type)
            return
        }
        
        
        self.AI_typing += 1    
        
        
       
        
        if self.chat?.model?.context == nil{
            self.state = .loading
            title_backup = Title
            Title = "loading..."
            let res = self.load_model_by_chat_name(self.chat_name,
                                                   in_text:in_text,
                                                   attachment: attachment,
                                                   attachment_type:attachment_type)
            if res == nil{
                finish_load(append_err_msg:true,msg_text: "Model load error")
            }
            return
        }
        
        if attachment != nil && attachment_type == "rag"{
            let requestMessage = Message(sender: .user_rag, state: .typed, text: text, tok_sec: 0,
                                        attachment:attachment,attachment_type:attachment_type)
            self.messages.append(requestMessage)
        }
        
        self.state = .completed
        self.chat?.chatName = self.chat_name
        self.chat?.flagExit = false        
        var message = Message(sender: .system, text: "",tok_sec: 0)
        self.messages.append(message)
        self.numberOfTokens = 0
        self.total_sec = 0.0
        self.predicting = true
        self.action_button_icon = "stop.circle"
        let img_real_path = get_path_by_short_name(attachment ?? "unknown",dest: "cache/images")
//        conv_finished_group.enter()
        self.start_predicting_time = DispatchTime.now()
//        llmStatus = "Eval"
        self.chat?.conversation(text,
            { str, time in //Predicting
                _ = self.process_predicted_str(str, time, &message/*, messageIndex*/)
            },
            { key,value in
//                if (key == "itc"){
//                    SetSendMsgTokensCount(value as Int)
//                }
//                if (key == "itc"){
//                    SetGeneratedMsgTokensCount(value as Int)
//                }
            },
            { final_str in // Finish predicting
                self.finish_completion(final_str, &message/*, messageIndex*/)   
//                self.llmStatus = "Done"
            },
            system_prompt:system_prompt,img_path:img_real_path)
        // self.conv_finished_group.leave()
    }
}
