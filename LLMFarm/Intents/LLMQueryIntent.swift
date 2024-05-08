
import SwiftUI
import AppIntents
import llmfarm_core_cpp


func mainCallback(_ str: String, _ time: Double) -> Bool {
    print("\(str)",terminator: "")
//    total_output += str.count
//    if(total_output>maxOutputLength){
//        print("Maximum output len achieved")
//        return true
//    }
    
    return false
}

@MainActor
func one_short_query(_ query: String) -> String{
    var result:String = ""
    var aiChatModel = AIChatModel()
    let chat_list = get_chats_list()!
    if (chat_list.count == 0){
        return "Chat list is empty."
    }
    let current_chat = chat_list[0]
    // aiChatModel.conv_finished_group.enter()
//    let res = aiChatModel.load_model_by_chat_name(current_chat["chat"] ?? "",in_text:query, img_path: nil)
    aiChatModel.chat_name = current_chat["chat"] ?? ""
    guard let res = aiChatModel.load_model_by_chat_name_prepare(current_chat["chat"] ?? "",in_text:query, img_path: nil) else {
        return "Chat load eror."
    }
    do{
        try aiChatModel.chat?.loadModel_sync(aiChatModel.model_context_param.model_inference,contextParams:aiChatModel.model_context_param)
        var output: String?=""
        let max_token_count = 50
        var current_token_count = 0
        try ExceptionCather.catchException {
            output = try! aiChatModel.chat?.model.predict(query, {
                str,time in
                print("\(str)",terminator: "")
                current_token_count+=1
                if current_token_count>max_token_count{
                    return true
                }
                return false
            })
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

struct LLMQueryIntent3: AppIntent {
    static let title: LocalizedStringResource = "Create a query"
    static let description: LocalizedStringResource = "Starts a new Query"

    /// Launch your app when the system triggers this intent.
//    static let openAppWhenRun: Bool = true

//     @Parameter(
//         title: "Files",
//         description: "Files to Transfer",
// //        supportedTypeIdentifiers: ["public.image"],
//         inputConnectionBehavior: .connectToPreviousIntentResult
//     )
//     var fileURLs: [IntentFile]?
    @Parameter(title: "Query")
    var query: String?

    /// Define the method that the system calls when it triggers this event.
    @MainActor
    func perform() async throws -> some ProvidesDialog {
        // if let fileURLs = fileURLs?.compactMap({ $0.fileURL }), !fileURLs.isEmpty {
        //     /// Import and handle file URLs
        //     return .result(dialog: IntentDialog(stringLiteral: fileURLs[0].absoluteString))
        // }
        if query != nil{
            let res = one_short_query(query!)
            return .result(dialog: IntentDialog(stringLiteral: res))
        }
        /// Deeplink into the Transfer Creation page
//        DeepLinkManager.handle(TransferURLScheme.createTransferFromShareExtension)

        /// Return an empty result since we're opening the app
        return .result(dialog: IntentDialog(stringLiteral: "Query is empty"))
    }
}
