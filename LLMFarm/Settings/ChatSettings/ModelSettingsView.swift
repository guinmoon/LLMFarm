//
//  ModelSettings.swift
//  LLMFarm
//
//  Created by guinmoon on 22.06.2024.
//

import SwiftUI

struct ModelSettingsView: View {
    @Binding var model_file_url: URL
    @Binding var model_file_path: String
    @Binding var model_title: String
    
    @Binding var clip_model_file_url: URL
    @Binding var clip_model_file_path: String
    @Binding var clip_model_title: String
    
    @Binding var lora_file_url: URL
    @Binding var lora_file_path: String
    @Binding var lora_title: String
    @Binding var lora_file_scale: Float
    @Binding var add_chat_dialog: Bool
    @Binding var edit_chat_dialog: Bool
    @Binding var toggleSettings: Bool
    
    @Binding var models_previews: [Dictionary<String, String>]
    @Binding var loras_previews: [Dictionary<String, String>]
    
    @Binding var has_lora: Bool
    @Binding var has_clip: Bool 
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5){
            
            ModelSelector(  models_previews:$models_previews,
                            model_file_path:$model_file_path,
                            model_file_url:$model_file_url,
                            model_title:$model_title,
                            toggleSettings:$toggleSettings,
                            edit_chat_dialog:$edit_chat_dialog,
                            import_lable:"Import from file...",
                            download_lable:"Download models...",
                            selection_lable:"Select Model...",
                            avalible_lable:"Avalible models")
            .padding([/*.trailing, .leading,*/ .top])
            .padding(.horizontal, 5)
#if os(iOS)
            .padding(.bottom)
#endif
            if has_clip {
                ModelSelector(  models_previews:$models_previews,
                                model_file_path:$clip_model_file_path,
                                model_file_url:$clip_model_file_url,
                                model_title:$clip_model_title,
                                toggleSettings:$toggleSettings,
                                edit_chat_dialog:$edit_chat_dialog,
                                import_lable:"Import from file...",
                                download_lable:"Download models...",
                                selection_lable:"Select Clip Model...",
                                avalible_lable:"Avalible models")
                .padding([/*.trailing, .leading,*/ .top])
                .padding(.horizontal, 5)
#if os(iOS)
                .padding(.bottom)
#endif
            }
            if has_lora {
                HStack {
                    ModelSelector(  models_previews:$loras_previews,
                                    model_file_path:$lora_file_path,
                                    model_file_url:$lora_file_url,
                                    model_title:$lora_title,
                                    toggleSettings:$toggleSettings,
                                    edit_chat_dialog:$edit_chat_dialog,
                                    import_lable:"Import from file...",
                                    download_lable:"Download models...",
                                    selection_lable:"Select Adapter...",
                                    avalible_lable:"Avalible adapters")
                    .padding([/*.trailing, .leading,*/ .top])
                    .padding(.leading, 5)
#if os(iOS)
                    .padding(.bottom)
#endif
                    Spacer()
                    
                    TextField("Scale..", value: $lora_file_scale, format:.number)
                        .frame( maxWidth: 50, alignment: .leading)
                        .multilineTextAlignment(.trailing)
                        .textFieldStyle(.plain)
                        .padding(.trailing, 5)
                        .padding(.top)
#if os(iOS)
                        .keyboardType(.numbersAndPunctuation)
#endif
                }
            }
            HStack {
                Toggle("Clip", isOn: $has_clip)
                    .frame(maxWidth: 120, alignment: .trailing)
//                Toggle("LoRa", isOn: $has_lora)
//                    .frame(maxWidth: 120, alignment: .trailing)
                Spacer()
            }
            .padding([/*.trailing, .leading,*/ .top])
            .padding(.horizontal, 5)
#if os(iOS)
            .padding([.bottom])
#endif
        }
    }
}

//#Preview {
//    ModelSettings()
//}
