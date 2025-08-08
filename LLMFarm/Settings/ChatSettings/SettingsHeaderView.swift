//
//  SettingsHeaderView.swift
//  LLMFarm
//
//  Created by guinmoon on 22.06.2024.
//

import SwiftUI

struct SettingsHeaderView: View {
    
    @Binding var add_chat_dialog: Bool
    @Binding var edit_chat_dialog: Bool
    @Binding var model_title: String
    @Binding var model_not_selected_alert: Bool
    
    var save_chat_settings: () -> Void
    
    var body: some View {
        VStack{
            HStack{
                Button {
                    Task {
                        add_chat_dialog = false
                        //                            edit_chat_dialog = false
                    }
                } label: {
                    Text("Cancel")
                }
                Text(edit_chat_dialog ? "Edit Chat" :"Add Chat" )
                    .fontWeight(.semibold)
                    .font(.title3)
                    .frame(maxWidth:.infinity, alignment: .center)
                    .padding(.trailing, 30)
                Spacer()
                Button {
                    Task {
                        save_chat_settings()
                    }
                } label: {
                    Text(edit_chat_dialog ? "Save" :"Add" )
                }
                .alert("To create a  chat, first select a model.", isPresented: $model_not_selected_alert) {
                    Button("OK", role: .cancel) { }
                }
                .disabled(model_title=="")
                
            }
//            Text(edit_chat_dialog ? model_title : ""  )
//                .padding(.top,4)
//                .font(.title3)
        }
    }
}

//#Preview {
//    SettingsHeaderView()
//}
