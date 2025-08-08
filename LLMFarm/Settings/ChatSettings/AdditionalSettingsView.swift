//
//  AdditionalSettingsView.swift
//  LLMFarm
//
//  Created by guinmoon on 22.06.2024.
//

import SwiftUI

struct AdditionalSettingsView: View {
    
    @Binding var save_load_state: Bool
    @Binding var save_as_template_name:String
    @Binding var chat_style: String
    @Binding var chat_styles: [String]
    
    var get_chat_options_dict: (Bool) -> Dictionary<String, Any>
    var refresh_templates: () -> Void
    
    var body: some View {
        VStack{
            Text("Save as new template:")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 5)
            HStack {
#if os(macOS)
                DidEndEditingTextField(text: $save_as_template_name,didEndEditing: { newName in})
                    .frame(maxWidth: .infinity, alignment: .leading)
#else
                TextField("New template name...", text: $save_as_template_name)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textFieldStyle(.plain)
#endif
                Button {
                    Task {
                        let options = get_chat_options_dict(true)
                        _ = CreateChat(options,edit_chat_dialog:true,chat_name:save_as_template_name + ".json",save_as_template:true)
                        refresh_templates()
                    }
                } label: {
                    Image(systemName: "doc.badge.plus")
                }
                .frame(alignment: .trailing)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 5)
        }
        .padding(.top)
        
        HStack {
            Toggle("Save/Load State", isOn: $save_load_state)
                .frame(maxWidth: 220, alignment: .leading)
             Spacer()
        }
        .padding(.top, 5)
        .padding(.horizontal, 5)
        .padding(.bottom, 4)

        HStack{
            Text("Chat Style:")
                .frame(maxWidth: .infinity, alignment: .leading)
            Picker("", selection: $chat_style) {
                ForEach(chat_styles, id: \.self) {
                    Text($0)
                }
            }
            .pickerStyle(.menu)            
            //
        }
        .padding(.horizontal, 5)
        .padding(.top, 8)
    }
}

//#Preview {
//    AdditionalSettingsView()
//}
