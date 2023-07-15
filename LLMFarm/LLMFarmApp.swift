//
//  LLMFarmApp.swift
//  LLMFarm
//
//  Created by guinmoon on 20.05.2023.
//

import SwiftUI




@main
struct LLMFarmApp: App {
    @State var add_chat_dialog = false
    @State var edit_chat_dialog = false
    @State var model_name = ""
    @State var title = ""
    @StateObject var aiChatModel = AIChatModel()
    @StateObject var orientationInfo = OrientationInfo()
    @State var isLandscape:Bool = false
    @State private var chat_selection: String?
    
    func close_chat() -> Void{
        aiChatModel.stop_predict()
    }
    
    var body: some Scene {
        WindowGroup {
            
            NavigationSplitView()  {
                if !add_chat_dialog{
                    ChatListView(tabSelection: .constant(1),
                                 model_name:$model_name,
                                 title: $title,
                                 add_chat_dialog:$add_chat_dialog,
                                 close_chat:close_chat,
                                 edit_chat_dialog:$edit_chat_dialog,
                                 chat_selection:$chat_selection)
                    .disabled(edit_chat_dialog)
                    .frame(minWidth: 250, maxHeight: .infinity)
                }else{
                    AddChatView(add_chat_dialog: $add_chat_dialog,
                                edit_chat_dialog:.constant(false))
                    .frame(minWidth: 200,maxHeight: .infinity)
                }
            }
        detail:{
            if !edit_chat_dialog{
                ChatView(
                         model_name: $model_name,
                         chat_selection: $chat_selection,
                         title: $title,
                         close_chat:close_chat,
                         add_chat_dialog:$add_chat_dialog,
                         edit_chat_dialog:$edit_chat_dialog).environmentObject(aiChatModel).environmentObject(orientationInfo)
                    .frame(maxWidth: .infinity,maxHeight: .infinity)
            }
            else{
                AddChatView(add_chat_dialog: $add_chat_dialog,
                            edit_chat_dialog:$edit_chat_dialog,
                            chat_name: aiChatModel.chat_name)
                .frame(minWidth: 200,maxHeight: .infinity)
                #if !os(macOS)
                .toolbar(.hidden, for: .automatic)
                #endif
            }
            
        }
        .navigationSplitViewStyle(.balanced)
        .background(.ultraThinMaterial)
        }
        
        
        
    }
}
