
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
func one_short_query(_ query: String, _ chat: String, _ token_limit:Int) -> String{
    var result:String = ""
    var aiChatModel = AIChatModel()
    aiChatModel.chat_name = chat
    guard let res = aiChatModel.load_model_by_chat_name_prepare(chat,in_text:query, img_path: nil) else {
        return "Chat load eror."
    }
    do{
        try aiChatModel.chat?.loadModel_sync(aiChatModel.model_context_param.model_inference,contextParams:aiChatModel.model_context_param)
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
    
    @Parameter(title: "Token Limit", default: 50)
    var token_limit: Int
    
    @Parameter(title: "Chat")
    var chat: ShortcutsChatEntity?
    
    @Parameter(title: "Query")
    var query: String?

    /// Define the method that the system calls when it triggers this event.
    @MainActor
    func perform() async throws -> some ProvidesDialog {
        // if let fileURLs = fileURLs?.compactMap({ $0.fileURL }), !fileURLs.isEmpty {
        //     /// Import and handle file URLs
        //     return .result(dialog: IntentDialog(stringLiteral: fileURLs[0].absoluteString))
        // }
        if query != nil && chat != nil{
            let res = one_short_query(query!,chat!.chat,token_limit)
            return .result(dialog: IntentDialog(stringLiteral: res))
        }
        /// Deeplink into the Transfer Creation page
//        DeepLinkManager.handle(TransferURLScheme.createTransferFromShareExtension)

        /// Return an empty result since we're opening the app
        return .result(dialog: IntentDialog(stringLiteral: "Query is empty"))
    }
    
//    private struct ChatsListProvider: DynamicOptionsProvider {
//        func results() async throws ->ItemCollection<ShortcutsChatEntity> {
//            ShortcutsChatEntity{}
////            ["Juan Chavez", "Anne Johnson"]
//        }
//    }
}


struct ShortcutsChatEntity: Identifiable, Hashable, Equatable, AppEntity {
    
    struct ShortcutsQuery: EntityQuery {
//        func entities(for: [Self.Entity.ID]) async throws -> [Self.Entity] {
//            return []
//        }
        func entities(for identifiers: [UUID]) async throws -> [ShortcutsChatEntity] {
               return try await suggestedEntities().filter { chat in
               return identifiers.contains(chat.id)
           }
       }
        
        func suggestedEntities() async throws -> Self.Result {
            let chat_list = get_chats_list()!
            var chat_entities: [ShortcutsChatEntity] = []
            for chat in chat_list {                
                var hasher = Hasher()
                hasher.combine(chat["chat"] ?? "none")
                hasher.combine(chat["model"] ?? "none")
                let hashValue = Int64(hasher.finalize())                
                chat_entities.append(ShortcutsChatEntity(id:UUID.from(integers: (hashValue,hashValue)),
                                                         title:chat["title"] ?? "none",
                                                         chat: chat["chat"] ?? "none",
                                                         model:chat["model"] ?? "none"))
            }
            return chat_entities
        }
    }
    
    static var defaultQuery: ShortcutsQuery = ShortcutsQuery()
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation = .init(name: "Chat")
    
    var id: UUID
    
    @Property(title: "Title")
    var title: String
    
    @Property(title: "Chat")
    var chat: String
    
    @Property(title: "Model")
    var model: String
    
    
    init(id: UUID, title: String?, chat: String?, model: String) {
        
        let Title = title ?? "Unknown Title"
        let Chat = chat ?? "Unknown Chat"
        
        self.id = id
        self.title = Title
        self.chat = Chat
        self.model = model
    }
    
    var displayRepresentation: DisplayRepresentation {
        return DisplayRepresentation(
            title: "\(title)",
            subtitle: "\(model)"
        )
    }
}

extension ShortcutsChatEntity {
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // Equtable conformance
    static func ==(lhs: ShortcutsChatEntity, rhs: ShortcutsChatEntity) -> Bool {
        return lhs.id == rhs.id
    }
    
}



extension UUID {
    // UUID is 128-bit, we need two 64-bit values to represent it
    var integers: (Int64, Int64) {
        var a: UInt64 = 0
        a |= UInt64(self.uuid.0)
        a |= UInt64(self.uuid.1) << 8
        a |= UInt64(self.uuid.2) << (8 * 2)
        a |= UInt64(self.uuid.3) << (8 * 3)
        a |= UInt64(self.uuid.4) << (8 * 4)
        a |= UInt64(self.uuid.5) << (8 * 5)
        a |= UInt64(self.uuid.6) << (8 * 6)
        a |= UInt64(self.uuid.7) << (8 * 7)
        
        var b: UInt64 = 0
        b |= UInt64(self.uuid.8)
        b |= UInt64(self.uuid.9) << 8
        b |= UInt64(self.uuid.10) << (8 * 2)
        b |= UInt64(self.uuid.11) << (8 * 3)
        b |= UInt64(self.uuid.12) << (8 * 4)
        b |= UInt64(self.uuid.13) << (8 * 5)
        b |= UInt64(self.uuid.14) << (8 * 6)
        b |= UInt64(self.uuid.15) << (8 * 7)

        return (Int64(bitPattern: a), Int64(bitPattern: b))
    }
    
    static func from(integers: (Int64, Int64)) -> UUID {
        let a = UInt64(bitPattern: integers.0)
        let b = UInt64(bitPattern: integers.1)
        return UUID(uuid: (
            UInt8(a & 0xFF),
            UInt8((a >> 8) & 0xFF),
            UInt8((a >> (8 * 2)) & 0xFF),
            UInt8((a >> (8 * 3)) & 0xFF),
            UInt8((a >> (8 * 4)) & 0xFF),
            UInt8((a >> (8 * 5)) & 0xFF),
            UInt8((a >> (8 * 6)) & 0xFF),
            UInt8((a >> (8 * 7)) & 0xFF),
            UInt8(b & 0xFF),
            UInt8((b >> 8) & 0xFF),
            UInt8((b >> (8 * 2)) & 0xFF),
            UInt8((b >> (8 * 3)) & 0xFF),
            UInt8((b >> (8 * 4)) & 0xFF),
            UInt8((b >> (8 * 5)) & 0xFF),
            UInt8((b >> (8 * 6)) & 0xFF),
            UInt8((b >> (8 * 7)) & 0xFF)
        ))
    }
    
    var data: Data {
        var data = Data(count: 16)
        // uuid is a tuple type which doesn't have dynamic subscript access...
        data[0] = self.uuid.0
        data[1] = self.uuid.1
        data[2] = self.uuid.2
        data[3] = self.uuid.3
        data[4] = self.uuid.4
        data[5] = self.uuid.5
        data[6] = self.uuid.6
        data[7] = self.uuid.7
        data[8] = self.uuid.8
        data[9] = self.uuid.9
        data[10] = self.uuid.10
        data[11] = self.uuid.11
        data[12] = self.uuid.12
        data[13] = self.uuid.13
        data[14] = self.uuid.14
        data[15] = self.uuid.15
        return data
    }
    
    static func from(data: Data?) -> UUID? {
        guard data?.count == MemoryLayout<uuid_t>.size else {
            return nil
        }
        return data?.withUnsafeBytes{
            guard let baseAddress = $0.bindMemory(to: UInt8.self).baseAddress else {
                return nil
            }
            return NSUUID(uuidBytes: baseAddress) as UUID
        }
    }
}
