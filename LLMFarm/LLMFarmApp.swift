//
//  LLMFarmApp.swift
//  LLMFarm
//
//  Created by guinmoon on 20.05.2023.
//

import SwiftUI




@main
struct LLMFarmApp: App {
    @State var chat_selected = false
    @State var add_chat_dialog = false
    @State var edit_chat_dialog = false
    @State var model_name = ""
    @State var chat_name = ""
    @State var title = ""
    @StateObject var aiChatModel = AIChatModel()
    @StateObject var orientationInfo = OrientationInfo()
    @State var isLandscape:Bool = false
    
    func close_chat() -> Void{
        aiChatModel.stop_predict()
    }
    //    var chat_view = nil
    
    var body: some Scene {
        WindowGroup {            
            if (orientationInfo.orientation == .landscape && orientationInfo.userInterfaceIdiom != .phone)
            {
                NavigationSplitView()  {
                    if !add_chat_dialog{
                        ChatListView(tabSelection: .constant(1),
                                     chat_selected: $chat_selected,
                                     model_name:$model_name,
                                     chat_name:$chat_name,
                                     title: $title,
                                     add_chat_dialog:$add_chat_dialog,
                                     close_chat:close_chat,
                                     edit_chat_dialog:$edit_chat_dialog)
                        .frame(minWidth: 250, maxHeight: .infinity)
                        //                        .border(Color.red, width: 1)
#if os(iOS) || os(watchOS) || os(tvOS)
                        .padding(.leading,(UIDevice.current.hasNotch && UIDevice.current.userInterfaceIdiom == .phone ) ? -40: 0)
#endif
                    }else{
                        if !edit_chat_dialog{
                            AddChatView(add_chat_dialog: $add_chat_dialog,
                                        edit_chat_dialog:.constant(false))
                            .frame(minWidth: 200,maxHeight: .infinity)
                            //                        .border(Color.red, width: 1)
#if os(iOS) || os(watchOS) || os(tvOS)
                            .padding(.leading,(UIDevice.current.hasNotch && UIDevice.current.userInterfaceIdiom == .phone ) ? -40: 0)
#endif
                        }else{
                            AddChatView(add_chat_dialog: $add_chat_dialog,
                                        edit_chat_dialog:$edit_chat_dialog,
                                        chat_name: aiChatModel.chat_name)
                            .frame(minWidth: 200,maxHeight: .infinity)
                            //                        .border(Color.red, width: 1)
#if os(iOS) || os(watchOS) || os(tvOS)
                            .padding(.leading,(UIDevice.current.hasNotch && UIDevice.current.userInterfaceIdiom == .phone ) ? -40: 0)
#endif
                        }
                    }
                        
                }detail:{
                    
                    ChatView(chat_selected: $chat_selected,
                             model_name: $model_name,
                             chat_name: $chat_name,
                             title: $title,
                             close_chat:close_chat,
                             add_chat_dialog:$add_chat_dialog,
                             edit_chat_dialog:$edit_chat_dialog).environmentObject(aiChatModel).environmentObject(orientationInfo)
                        .frame(maxWidth: .infinity,maxHeight: .infinity)
                    
                }
                .navigationSplitViewStyle(.balanced)
                .background(.ultraThinMaterial)
            }
            else
            {
                if (!chat_selected){
                    //                withAnimation(.easeInOut(duration: 2)) {
                    //                    //                ContentView(chat_selected: $chat_selected,model_name: $model_name)
                    //
                    //                }
                    if !add_chat_dialog{
                        ChatListView(tabSelection: .constant(1),
                                     chat_selected: $chat_selected,
                                     model_name:$model_name,
                                     chat_name:$chat_name,
                                     title: $title,
                                     add_chat_dialog:$add_chat_dialog,
                                     close_chat:close_chat,
                                     edit_chat_dialog:$edit_chat_dialog)
                    }else{
                        AddChatView(add_chat_dialog: $add_chat_dialog,
                                    edit_chat_dialog:$edit_chat_dialog)
                    }
                }
                else{
                    if !add_chat_dialog{
                        withAnimation() {
                            ChatView(chat_selected: $chat_selected,
                                     model_name: $model_name,
                                     chat_name: $chat_name,
                                     title: $title,close_chat:close_chat,
                                     add_chat_dialog: $add_chat_dialog,
                                     edit_chat_dialog:$edit_chat_dialog).environmentObject(aiChatModel).environmentObject(orientationInfo)
                        }
                    }
                    else{
                        if !edit_chat_dialog{
                            AddChatView(add_chat_dialog: $add_chat_dialog,
                                        edit_chat_dialog:.constant(false))
                        }else{
                            AddChatView(add_chat_dialog: $add_chat_dialog,
                                        edit_chat_dialog:$edit_chat_dialog,
                                        chat_name: aiChatModel.chat_name)
                        }
                    }
                }
            }
        }
    }
}
