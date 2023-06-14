//
//  ChatItem.swift
//  ChatUI
//
//  Created by Shezad Ahamed on 6/08/21.
//

import SwiftUI

struct ChatItem: View {
    
    var chatImage: String = ""
    var chatTitle: String = ""
    var message: String = ""
    var time: String = ""
    var model: String = ""
    var chat: String = ""
    @Binding var chat_selected: Bool
    @Binding var model_name: String
    @Binding var chat_name: String
    @Binding var title: String
    var close_chat: () -> Void
//    var select_chat: (String) -> Void
    
    var body: some View {
        HStack{
            Button(action: {
                close_chat()
                model_name = self.model
                chat_name = self.chat
                title = self.chatTitle
                chat_selected = true
            }){
            Image(chatImage+"_85")
                .resizable()
                .background( Color("color_bg_inverted").opacity(0.05))
                .padding(EdgeInsets(top: 7, leading: 5, bottom: 7, trailing: 5))
                .frame(width: 85, height: 85)
                .clipShape(Circle())
                VStack(alignment: .leading, spacing: 8){
                    HStack{
                        Text(chatTitle)
                            .fontWeight(.semibold)
                            .padding(.top, 3)
                        Spacer()
//                        Text(time)
//                            .foregroundColor(Color("color_primary"))
//                            .padding(.top, 3)
                    }
                    
                    
                    Text(message)
                        .foregroundColor(Color("color_bg_inverted").opacity(0.5))
                        .lineLimit(/*@START_MENU_TOKEN@*/2/*@END_MENU_TOKEN@*/)
//                    Divider()
//                        .padding(.top, 8)
                }
            }
            .buttonStyle(.borderless)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            
        }
        
    }
}
