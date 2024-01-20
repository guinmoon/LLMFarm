//
//  ChatListView.swift
//  ChatUI
//
//  Created by Shezad Ahamed on 05/08/21.
//

import SwiftUI



struct ChatListView: View {
    @EnvironmentObject var fineTuneModel: FineTuneModel
    @EnvironmentObject var aiChatModel: AIChatModel
    
    @State var searchText: String = ""
    @Binding var tabSelection: Int
    @Binding var model_name: String
    @Binding var title: String
    @Binding var add_chat_dialog: Bool
    var close_chat: () -> Void
    @Binding var edit_chat_dialog: Bool
//    @Binding var chat_selection: String?
    @Binding var chat_selection: Dictionary<String, String>?
    @Binding var renew_chat_list: () -> Void
    @State var chats_previews:[Dictionary<String, String>] = []
    @State var current_detail_view_name:String? = "Chat"
    @State private var toggleSettings = false
    @State private var toggleAddChat = false
    
    func refresh_chat_list(){
        self.chats_previews = get_chats_list()!
    }
    
    func delete(at offsets: IndexSet) {
        let chatsToDelete = offsets.map { self.chats_previews[$0] }
        _ = delete_chats(chatsToDelete)
        
    }
    
    func delete(at elem:Dictionary<String, String>){
        _ = delete_chats([elem])
        self.chats_previews.removeAll(where: { $0 == elem })
    }


    
    var body: some View {
        VStack(alignment: .leading, spacing: 5){
//                HStack{
//                    Text("Chats")
//                        .fontWeight(.semibold)
//                        .font(.title2)
//                    Spacer()
//
//                    Button {
//                        Task {
//                            add_chat_dialog = true
//                            edit_chat_dialog = false
//                        }
//                    } label: {
//                        Image(systemName: "plus.app")
////                            .foregroundColor(Color("color_primary"))
//                            .font(.title2)
//                    }
//                    .buttonStyle(.borderless)
//                    .controlSize(.large)
//                }
//                .padding(.top)
//                .padding(.horizontal)
            
            
//                    Divider()
//                        .padding(.bottom, 20)
            
            
            VStack(){
                List(selection: $chat_selection){
                    ForEach(chats_previews, id: \.self) { chat_preview in
                        NavigationLink(value: chat_preview){
                            ChatItem(
                                chatImage: String(describing: chat_preview["icon"]!),
                                chatTitle: String(describing: chat_preview["title"]!),
                                message: String(describing: chat_preview["message"]!),
                                time: String(describing: chat_preview["time"]!),
                                model:String(describing: chat_preview["model"]!),
                                chat:String(describing: chat_preview["chat"]!),
//                                chat_selection: $chat_selection,
                                model_name: $model_name,
                                title: $title,
                                close_chat:close_chat
                            )
                            //                            .border(Color.green, width: 1)
                            .listRowInsets(.init())
                            .contextMenu {
                                Button(action: {
                                    delete(at: chat_preview)
                                }){
                                    Text("Delete chat")
                                }
                            }
                        }
                    }
                    .onDelete(perform: delete)
                }
                
                .frame(maxHeight: .infinity)
//                    .border(Color.red, width: 1)
//                    .listStyle(PlainListStyle())
                #if os(macOS)
                .listStyle(.sidebar)
                #else
                .listStyle(InsetListStyle())
                #endif
            }
            .background(.opacity(0))
            
            if chats_previews.count<=0{
                VStack{
                    Button {
                        Task {
                            add_chat_dialog = true
                            edit_chat_dialog = false
                        }
                    } label: {
                        Image(systemName: "plus.square.dashed")
                            .foregroundColor(.secondary)
                            .font(.system(size: 40))
                    }
                    .buttonStyle(.borderless)
                    .controlSize(.large)
                    Text("Start new chat")
                        .font(.title3)
                        .frame(maxWidth: .infinity)
                    
                    
                }.opacity(0.4)
                    .frame(maxWidth: .infinity,alignment: .center)
            }
        }.task {
            renew_chat_list = refresh_chat_list
            refresh_chat_list()
        }
        .navigationTitle("Chats")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Menu {
                    Button {
                        toggleSettings = true
                    } label: {
                        HStack {
                            Text("Settings")
                            Image(systemName: "gear")
                        }
                    }
                    #if os(iOS)
                    EditButton()
                    #endif
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task {
                       add_chat_dialog = true
                       edit_chat_dialog = false
                        toggleAddChat = true
                    }
                } label: {
                    Image(systemName: "plus")
                }
                
            }
    }
        .sheet(isPresented: $toggleSettings) {
            SettingsView(current_detail_view_name:$current_detail_view_name).environmentObject(fineTuneModel)
#if os(macOS)
                .frame(minWidth: 400,minHeight: 600)
#endif
        }
        .sheet(isPresented: $toggleAddChat) {
            AddChatView(add_chat_dialog: $toggleAddChat,
                        edit_chat_dialog: $edit_chat_dialog,
                        chat_name: aiChatModel.chat_name,
                        renew_chat_list: $renew_chat_list).environmentObject(aiChatModel)
#if os(macOS)
                .frame(minWidth: 400,minHeight: 600)
#endif
        }
    }
}



//struct ChatListView_Previews: PreviewProvider {
//    static var previews: some View {
//        ChatListView(tabSelection: .constant(1),
//                     chat_selected: .constant(false),
//                     model_name: .constant(""),
//                     chat_name: .constant(""),
//                     title: .constant(""),
//                     add_chat_dialog: .constant(false),
//                     close_chat:{},
//                     edit_chat_dialog:.constant(false))
////            .preferredColorScheme(.dark)
//    }
//}
