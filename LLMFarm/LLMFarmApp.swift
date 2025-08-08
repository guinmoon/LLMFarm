//
//  LLMFarmApp.swift
//  LLMFarm
//
//  Created by guinmoon on 20.05.2023.
//

import SwiftUI
import Darwin
//import llmfarm_core_cpp



@main
struct LLMFarmApp: App {
    @State var add_chat_dialog = false
    @State var edit_chat_dialog = false
    @State var current_detail_view_name:String? = "Chat"
    @State var model_name = ""
    @State var title = ""
    @StateObject var aiChatModel = AIChatModel()
    @StateObject var fineTuneModel = FineTuneModel()
    @StateObject var orientationInfo = OrientationInfo()
    @State var isLandscape:Bool = false
    @State private var chat_selection: Dictionary<String, String>?
    @State var after_chat_edit: () -> Void = {}
    @State var tabIndex: Int = 0
    //    var set_res = setSignalHandler()
    
    func close_chat() -> Void{
        aiChatModel.stop_predict()
    }
    
    var body: some Scene {
        WindowGroup {
            NavigationSplitView()  {
                ChatListView(tabSelection: .constant(0),
                             model_name:$model_name,
                             title: $title,
                             add_chat_dialog:$add_chat_dialog,
                             close_chat:close_chat,
                             edit_chat_dialog:$edit_chat_dialog,
                             chat_selection:$chat_selection,
                             after_chat_edit: $after_chat_edit
                ).environmentObject(fineTuneModel)
                    .environmentObject(aiChatModel)
                
                    .frame(minWidth: 250, maxHeight: .infinity)
                
            }
        detail:{
            ChatView(
                modelName: $model_name,
                chatSelection: $chat_selection,
                title: $title,
                CloseChat:close_chat,
                AfterChatEdit: $after_chat_edit,
                addChatDialog:$add_chat_dialog,
                editChatDialog:$edit_chat_dialog
                ).environmentObject(aiChatModel).environmentObject(orientationInfo)
                .frame(maxWidth: .infinity,maxHeight: .infinity)
            
            
        }
        .navigationSplitViewStyle(.balanced)
        .background(.ultraThinMaterial)
        }        
    }
}
