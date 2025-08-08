//
//  ShortcutsChatEntity.swift
//  LLMFarm
//
//  Created by guinmoon on 12.05.2024.
//

import Foundation
import AppIntents



struct ShortcutsChatEntity: Identifiable,/* Hashable, Equatable,*/ AppEntity {
    
    struct ShortcutsQuery: EntityQuery {        
        func entities(for identifiers: [ShortcutsChatEntity.ID]) async throws -> [ShortcutsChatEntity] {
            getChatEntities().filter { identifiers.contains($0.id) }
        }
        
        func entities(matching string: String) async throws -> [ShortcutsChatEntity] {
            getChatEntities().filter { $0.chat == string }
        }
        
        func suggestedEntities() async throws -> [ShortcutsChatEntity] {
            getChatEntities()
        }
        
        private func getChatEntities() -> [ShortcutsChatEntity] {
            let chat_list = get_chats_list()!
            var chat_entities: [ShortcutsChatEntity] = []
            for chat in chat_list {
                var hasher = Hasher()
                hasher.combine(chat["chat"] ?? "none")
//                let hashValue = Int64(hasher.finalize())
                chat_entities.append(ShortcutsChatEntity(/*id:UUID.from(integers: (hashValue,hashValue))*/
                                                         id:chat["chat"] ?? "none",
                                                         title:chat["title"] ?? "none",
                                                         chat: chat["chat"] ?? "none",
                                                         model:chat["model"] ?? "none"))
            }
            return chat_entities
        }
    }
    
    static var defaultQuery: ShortcutsQuery = ShortcutsQuery()
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation = .init(name: "Chat")
    
    var id: String
    
    @Property(title: "Title")
    var title: String
    
    @Property(title: "Chat")
    var chat: String
    
    @Property(title: "Model")
    var model: String
    
//    @Property(title: "current_model")
//    var current_model: String
//    
//    @Property(title: "comparison_algorithm")
//    var comparison_algorithm: String
//    
//    @Property(title: "chunk_method")
//    var chunk_method: String
//    "current_model":info?["current_model"] as? String ?? "minilmMultiQA",
//    "comparison_algorithm":info?["comparison_algorithm"] as? String ?? "dotproduct",
//    "chunk_method":info?["chunk_method"] as? String ?? "recursive"
    
    init(id: String, title: String?, chat: String?, model: String) {
        
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

//extension ShortcutsChatEntity {
//    
//    // Hashable conformance
//    func hash(into hasher: inout Hasher) {
//        hasher.combine(chat)
//    }
//    
//    // Equtable conformance
//    static func ==(lhs: ShortcutsChatEntity, rhs: ShortcutsChatEntity) -> Bool {
//        return lhs.chat == rhs.chat
//    }
//    
//}
