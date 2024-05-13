
import SwiftUI
import AppIntents
import llmfarm_core_cpp



@MainActor
func one_short_query(_ query: String, _ chat: String, _ token_limit:Int,img_path: String? = nil) -> String{
    var result:String = ""
    var aiChatModel = AIChatModel()
    aiChatModel.chat_name = chat
    guard let res = aiChatModel.load_model_by_chat_name_prepare(chat,in_text:query, img_path: nil) else {
        return "Chat load eror."
    }
    do{
        try aiChatModel.chat?.loadModel_sync(aiChatModel.model_context_param.model_inference,contextParams:aiChatModel.model_context_param)
        aiChatModel.chat?.model.sampleParams = aiChatModel.model_sample_param
        aiChatModel.chat?.model.contextParams = aiChatModel.model_context_param
        var system_prompt:String? = nil
        if aiChatModel.model_context_param.system_prompt != ""{
            system_prompt = aiChatModel.model_context_param.system_prompt+"\n"
//            aiChatModel.messages[aiChatModel.messages.endIndex - 1].header = aiChatModel.model_context_param.system_prompt
        }
        var output: String?=""
        var current_token_count = 0
        try ExceptionCather.catchException {
            output = try! aiChatModel.chat?.model.predict(query, {
                str,time in
                print("\(str)",terminator: "")
                current_token_count+=1
                if current_token_count>token_limit{
                    return true
                }
                return false
            },system_prompt:system_prompt,img_path:img_path)
        }
        result = output ?? ""
    }
    catch{
        return "Chat load eror."
    }
    //    aiChatModel.send(message: query)
    //    aiChatModel.conv_finished_group.wait()
    //    result = aiChatModel.messages.last?.text ?? ""
    return result
}

struct LLMQueryIntent: AppIntent {
    static let title: LocalizedStringResource = "Create a query"
    static let description: LocalizedStringResource = "Starts a new Query"
    
    /// Launch your app when the system triggers this intent.
    //    static let openAppWhenRun: Bool = true
    
    
    @Parameter(title: "Token Limit", default: 50)
    var token_limit: Int
    
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
    func perform() async throws -> some ProvidesDialog {

        var img_path:String? = nil
        
        if let imageUrls = imageUrls?.compactMap({ $0.data }), !imageUrls.isEmpty {
            /// Import and handle file URLs
            ///
            
//            var data: Data?
//            do{
//                data = try Data(contentsOf: imageUrls[0])
//            }
//            catch{
//                print(error)
//            }
//            print(imageUrls[0])
//            if data != nil {
            if let ui_img = UIImage(data: imageUrls[0])?.fixedOrientation {
                    img_path = save_image_from_library_to_cache(ui_img)
                    print(img_path)
                    if img_path != nil{
                        img_path = get_path_by_short_name(img_path!,dest: "cache/images")
                        print(img_path)
                    }
                }
//            }imageUrls[0]
        }
        if (query == nil){
            return .result(dialog: IntentDialog(stringLiteral: "Query is empty."))
        }
        if (chat == nil){
            return .result(dialog: IntentDialog(stringLiteral: "Please select chat."))
        }
        
        let res = one_short_query(query!,chat!.chat,token_limit,img_path:img_path)
        return .result(dialog: IntentDialog(stringLiteral: res))
        
    }
    
}



