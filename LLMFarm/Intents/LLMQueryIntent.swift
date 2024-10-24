
import SwiftUI
import AppIntents
import llmfarm_core_cpp



@MainActor
func one_short_query(_ query: String, _ chat: String, _ token_limit:Int,img_path: String? = nil, use_history: Bool = false) -> String{
    var result:String = ""
    var aiChatModel = AIChatModel()
    aiChatModel.chat_name = chat
    guard let res = aiChatModel.load_model_by_chat_name_prepare(chat,in_text:query, attachment:  nil) else {
        return "Chat load eror."
    }
    do{
//        aiChatModel.chat?.initModel(aiChatModel.model_context_param.model_inference,contextParams: aiChatModel.model_context_param)
//        if aiChatModel.chat?.model == nil{
//            return "Model load eror."
//        }
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
//        var full_output: String?=""
        var current_output: String = ""
        var current_token_count = 0
        try ExceptionCather.catchException {
            do{
                _ = try aiChatModel.chat?.model?.predict(query,
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

struct LLMQueryIntent: AppIntent {
    static let title: LocalizedStringResource = "Create a query"
    static let description: LocalizedStringResource = "Starts a new Query"
    
    /// Launch your app when the system triggers this intent.
    //    static let openAppWhenRun: Bool = true
    
    
    @Parameter(title: "Token Limit", default: 50)
    var token_limit: Int

    @Parameter(title: "Use history", default: false)
    var use_history: Bool
    
    @Parameter(title: "Chat")
    var chat: ShortcutsChatEntity?
    
    @Parameter(title: "Query")
    var query: String?
    
    @Parameter(
        title: "Image",
        description: "Image to Multimodal",
        supportedTypeIdentifiers: ["public.image"],
        inputConnectionBehavior: .connectToPreviousIntentResult
    )
    var imageUrls: [IntentFile]?
    
    /// Define the method that the system calls when it triggers this event.
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {

        var img_path:String? = nil
        
        if let imageUrls = imageUrls?.compactMap({ $0.data }), !imageUrls.isEmpty {
            #if os(iOS)
            let ui_img = UIImage(data: imageUrls[0])?.fixedOrientation
            #else
            let ui_img = UIImage(data: imageUrls[0])
            #endif
            if ui_img != nil {
                img_path = save_image_from_library_to_cache(ui_img)
                if img_path != nil{
                    img_path = get_path_by_short_name(img_path!,dest: "cache/images")
//                    print(img_path)
                }
            }
        }
        if (query == nil){
            return .result(value: "Query is empty.")
        }
        if (chat == nil){
            return .result(value: "Please select chat.")
        }
        
        let res = one_short_query(query!,chat!.chat,token_limit,img_path:img_path,use_history: use_history)
        return .result(value: res)
        
    }
    
}



