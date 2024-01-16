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
    @State private var chat_selection: String?
    @State var renew_chat_list: () -> Void = {}
    @State var tabIndex: Int = 0
    //    var set_res = setSignalHandler()
    
    func close_chat() -> Void{
        aiChatModel.stop_predict()
    }
    
    var body: some Scene {
        WindowGroup {
            NavigationSplitView()  {
                if !add_chat_dialog{
                    if (tabIndex==0){
                        ChatListView(tabSelection: .constant(1),
                                     model_name:$model_name,
                                     title: $title,
                                     add_chat_dialog:$add_chat_dialog,
                                     close_chat:close_chat,
                                     edit_chat_dialog:$edit_chat_dialog,
                                     chat_selection:$chat_selection,
                                     renew_chat_list: $renew_chat_list
                        )
                        .disabled(edit_chat_dialog)
                        .frame(minWidth: 250, maxHeight: .infinity)
                        
                        //                        .border(/*@START_MENU_TOKEN@*/Color.black/*@END_MENU_TOKEN@*/)
                        BottomPanelView(tabIndex: $tabIndex, current_detail_view_name:$current_detail_view_name)
                        //                            .border(/*@START_MENU_TOKEN@*/Color.black/*@END_MENU_TOKEN@*/)
                    }
                    if (tabIndex==1){
                        // ModelsView()
                        SettingsView(current_detail_view_name:$current_detail_view_name).environmentObject(fineTuneModel)
                        BottomPanelView(tabIndex: $tabIndex, current_detail_view_name:$current_detail_view_name)
                            .ignoresSafeArea(.keyboard)
                    }
                }else{
                    AddChatView(add_chat_dialog: $add_chat_dialog,
                                edit_chat_dialog: $edit_chat_dialog,
                                renew_chat_list: $renew_chat_list).environmentObject(aiChatModel)
                    .frame(minWidth: 200,maxHeight: .infinity)
                }
            }
        detail:{
            if !edit_chat_dialog{
                if current_detail_view_name == "Chat"{
                    ChatView(
                        model_name: $model_name,
                        chat_selection: $chat_selection,
                        title: $title,
                        close_chat:close_chat,
                        add_chat_dialog:$add_chat_dialog,
                        edit_chat_dialog:$edit_chat_dialog).environmentObject(aiChatModel).environmentObject(orientationInfo)
                        .frame(maxWidth: .infinity,maxHeight: .infinity)
                }
//                if current_detail_view_name == "Models"{
//                    ModelsView("models")
//                }
            }
            else{
                AddChatView(add_chat_dialog: $add_chat_dialog,
                            edit_chat_dialog: $edit_chat_dialog,
                            chat_name: aiChatModel.chat_name,
                            renew_chat_list: $renew_chat_list).environmentObject(aiChatModel)
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
