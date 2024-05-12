//
//  ShortcutsChatEntity.swift
//  LLMFarm
//
//  Created by guinmoon on 12.05.2024.
//

import Foundation
import AppIntents



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
