//
//  BasicSettingsView.swift
//  LLMFarm
//
//  Created by guinmoon on 22.06.2024.
//

import SwiftUI

struct BasicSettingsView: View {
    
    @Binding var chat_title: String
    @Binding var model_icon: String
    @Binding var model_icons: [String]
    @Binding var model_inferences: [String]
    @Binding var ggjt_v3_inferences: [String]
    @Binding var model_inference: String
    @Binding var ggjt_v3_inference: String
    @Binding var model_inference_inner: String
    @Binding var model_settings_template: ChatSettingsTemplate
    @Binding var model_setting_templates: [ChatSettingsTemplate]
    @Binding var applying_template: Bool
    var apply_setting_template: (ChatSettingsTemplate) -> Void
    
    
    var body: some View {
        
        HStack{
            
            Picker("", selection: $model_icon) {
//                                LazyVGrid(columns: [GridItem(.flexible(minimum: 20, maximum: 50)),GridItem(.flexible(minimum: 20, maximum: 50))], spacing: 5) {
                    ForEach(model_icons, id: \.self) { img in
                        Image(img+"_48")
                            .resizable()
                            .background( Color("color_bg_inverted").opacity(0.05))
                            .padding(EdgeInsets(top: 7, leading: 5, bottom: 7, trailing: 5))
                            .frame(width: 48, height: 48)
                            .clipShape(Circle())
                    }
//                                }
            }
            .pickerStyle(.menu)
            
            .frame(maxWidth: 80, alignment: .leading)
            .frame(height: 48)
            
#if os(macOS)
            DidEndEditingTextField(text: $chat_title,didEndEditing: { newName in})
                .frame(maxWidth: .infinity, alignment: .leading)
            //                            .padding([.trailing, .leading, .top])
#else
            TextField("Title...", text: $chat_title)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textFieldStyle(.plain)
            //                            .padding([.trailing, .leading, .top])
#endif
            
            
            
            //                            Text("Icon:")
            //                                .frame(maxWidth: .infinity, alignment: .leading)
            
        }
        .padding([.top ])
        
        HStack{
            Text("Settings template:")
                .frame(maxWidth: .infinity, alignment: .leading)
            Picker("", selection: $model_settings_template) {
                ForEach(model_setting_templates, id: \.self) { template in
                    Text(template.template_name).tag(template)
                }
            }
            .onChange(of: model_settings_template) { tmpl in
                applying_template = true
                apply_setting_template(model_settings_template)
            }
            .pickerStyle(.menu)
        }
        .padding(.horizontal, 5)
        .padding(.top, 8)
        
        // Потом надо вернуть, например для выбора между Minicpm, Bunny и т д
        // HStack{
        //     Text("Inference:")
        //         .frame(maxWidth: .infinity, alignment: .leading)
        //     Picker("", selection: $model_inference) {
        //         ForEach(model_inferences, id: \.self) {
        //             Text($0)
        //         }
        //     }
        //     .pickerStyle(.menu)
        //     //
        // }
        // .padding(.horizontal, 5)
        // .padding(.top, 8)
        // .onChange(of: model_inference){ inf in
        //     if model_inference != "ggjt_v3"{
        //         model_inference_inner = model_inference
        //     }else{
        //         model_inference_inner = ggjt_v3_inference
        //     }
        // }
        
        
        // if model_inference == "ggjt_v3"{
        //     HStack{
        //         Text("Inference ggjt_v3:")
        //             .frame(maxWidth: .infinity, alignment: .leading)
        //         Picker("", selection: $ggjt_v3_inference) {
        //             ForEach(ggjt_v3_inferences, id: \.self) {
        //                 Text($0)
        //             }
        //         }
        //         .pickerStyle(.menu)
        //         //
        //     }
        //     .padding(.horizontal, 5)
        //     .padding(.top, 8)
        //     .onChange(of: ggjt_v3_inference){ inf in
        //         model_inference_inner = ggjt_v3_inference
        //     }
        // }
    }
}

//#Preview {
//    BasicSettingsView()
//}
