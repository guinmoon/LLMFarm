//
//  PromptSettingsView.swift
//  LLMFarm
//
//  Created by guinmoon on 22.06.2024.
//

import SwiftUI

struct PromptSettingsView: View {
    
    @Binding var prompt_format: String
    @Binding var warm_prompt: String
    @Binding var skip_tokens: String
    @Binding var reverse_prompt:String
    @Binding var add_bos_token: Bool
    @Binding var add_eos_token: Bool
    @Binding var parse_special_tokens: Bool
    @Binding var model_inference:String
    
    var body: some View {
        ScrollView{
            GroupBox(label:
                        Text("Prompt Format")
            ) {
                VStack {
                    //                Text("Format:")
                    //                    .frame(maxWidth: .infinity, alignment: .leading)
                    TextEditor(text: $prompt_format)
                        .frame(minHeight: 30)
                    //                                TextField("prompt..", text: $prompt_format, axis: .vertical)
                    //                                    .lineLimit(2)
                    //                                    .textFieldStyle(.roundedBorder)
                    //                                    .frame( alignment: .leading)
                    //                                .multilineTextAlignment(.trailing)
                    //                                .textFieldStyle(.plain)
                }
                .padding(.top, 8)
                .padding(.horizontal, 1)
            }.frame(minHeight: 200)
            
            GroupBox(label:
                        Text("Options")
            ) {
                VStack {
                    Text("Reverse prompts:")
                        .frame(maxWidth: .infinity, alignment: .leading)
#if os(macOS)
                    DidEndEditingTextField(text: $reverse_prompt, didEndEditing: { newName in})
                        .frame( alignment: .leading)
#else
                    TextField("prompt..", text: $reverse_prompt, axis: .vertical)
                        .lineLimit(2)
                        .textFieldStyle(.roundedBorder)
                        .frame( alignment: .leading)
#endif
                    //                                .multilineTextAlignment(.trailing)
                    //                                .textFieldStyle(.plain)
                }
                .padding(.top, 8)
                .padding(.horizontal, 5)
                
                VStack {
                    Text("Skip tokens:")
                        .frame(maxWidth: .infinity, alignment: .leading)
#if os(macOS)
                    DidEndEditingTextField(text: $skip_tokens, didEndEditing: { newName in})
                        .frame( alignment: .leading)
#else
                    TextField("prompt..", text: $skip_tokens, axis: .vertical)
                        .lineLimit(2)
                        .textFieldStyle(.roundedBorder)
                        .frame( alignment: .leading)
#endif
                    //                                .multilineTextAlignment(.trailing)
                    //                                .textFieldStyle(.plain)
                }
                .padding(.top, 8)
                .padding(.horizontal, 5)
                
                HStack {
                    Toggle("Special", isOn: $parse_special_tokens)
                        .frame(maxWidth: 120, alignment: .trailing)
                        .disabled(model_inference != "llama" )
                    Spacer()
                }
                .padding(.horizontal, 5)
                .padding(.bottom, 4)
                
                HStack {
                    Toggle("BOS", isOn: $add_bos_token)
                        .frame(maxWidth: 120, alignment: .trailing)
                    Toggle("EOS", isOn: $add_eos_token)
                        .frame(maxWidth: 120, alignment: .trailing)
                    Spacer()
                }
                .padding(.horizontal, 5)
                .padding(.bottom, 4)
                
                Divider()
                    .padding(.top, 8)
            }
        }
    }
}
//
//#Preview {
//    PromptSettingsView()
//}
