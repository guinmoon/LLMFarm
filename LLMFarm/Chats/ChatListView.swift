//
//  ChatListView.swift
//  ChatUI
//
//  Created by Shezad Ahamed on 05/08/21.
//

import SwiftUI



struct ChatListView: View {
    
    @State var searchText: String = ""
    @Binding var tabSelection: Int
    @Binding var chat_selected: Bool
    @Binding var model_name: String
    @Binding var chat_name: String
    @Binding var title: String
    @Binding var add_chat_dialog: Bool
    var close_chat: () -> Void
    @Binding var edit_chat_dialog: Bool
//    @State var selection: Int32? = nil
//    var select_chat: (String) -> Void
    
//    let users = ["Shezad", "Mathew", "Afna", "Jerin", "Catherine"]
    @State var chats_previews = get_chat_list()!
    
    func delete(at offsets: IndexSet) {
//        chats_preview.remove(atOffsets: offsets)
        let chatsToDelete = offsets.map { self.chats_previews[$0] }
        let res = delete_chats(chatsToDelete)
        
    }
    
    func delete(at elem:Dictionary<String, String>){
        let res = delete_chats([elem])
        self.chats_previews.removeAll(where: { $0 == elem })
    }


    
    var body: some View {
        ZStack{
//            Color("color_bg").edgesIgnoringSafeArea(.all)
            
            VStack(alignment: .leading, spacing: 5){
                HStack{
                    Text("Chats")
                        .fontWeight(.semibold)
                        .font(.largeTitle)
                    Spacer()
                    
                    Button {
                        Task {
                            add_chat_dialog = true
                            edit_chat_dialog = false
                        }
                    } label: {
                        Image(systemName: "plus.app")
                            .foregroundColor(Color("color_primary"))
                            .font(.title2)
                    }
                    .buttonStyle(.borderless)
                    .controlSize(.large)
                }
                .padding(.top)
                .padding(.horizontal)
                
                
//                    Divider()
//                        .padding(.bottom, 20)
                
                
                VStack(){
                    List() {
                        ForEach(chats_previews, id: \.self) { chat_preview in
//                            NavigationLink(value: chat_preview){
                                ChatItem(
                                    chatImage: String(describing: chat_preview["icon"]!),
                                    chatTitle: String(describing: chat_preview["title"]!),
                                    message: String(describing: chat_preview["message"]!),
                                    time: String(describing: chat_preview["time"]!),
                                    model:String(describing: chat_preview["model"]!),
                                    chat:String(describing: chat_preview["chat"]!),
                                    chat_selected: $chat_selected,
                                    model_name: $model_name,
                                    chat_name: $chat_name,
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
//                            }
                        }
                        .onDelete(perform: delete)
                    }
//                    .border(Color.red, width: 1)
//                    .listStyle(PlainListStyle())
                    #if os(macOS)
                    .listStyle(.sidebar)
                    #else
                    .listStyle(InsetListStyle())
                    #endif
                }
                .background(.opacity(0))
            }
        }
        
    }
}



struct ChatListView_Previews: PreviewProvider {
    static var previews: some View {
        ChatListView(tabSelection: .constant(1),
                     chat_selected: .constant(false),
                     model_name: .constant(""),
                     chat_name: .constant(""),
                     title: .constant(""),
                     add_chat_dialog: .constant(false),
                     close_chat:{},
                     edit_chat_dialog:.constant(false))
//            .preferredColorScheme(.dark)
    }
}
