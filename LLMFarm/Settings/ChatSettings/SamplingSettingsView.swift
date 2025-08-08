//
//  SamplingSettingsView.swift
//  LLMFarm
//
//  Created by guinmoon on 22.06.2024.
//

import SwiftUI

struct SamplingSettingsView: View {
    
    @Binding var model_sampling: String
    @Binding var model_samplings: [String]
    @Binding var model_temp: Float
    @Binding var model_top_k: Int32
    @Binding var model_top_p: Float
    @Binding var model_repeat_last_n: Int32
    @Binding var model_repeat_penalty: Float
    @Binding var mirostat: Int32
    @Binding var mirostat_tau: Float
    @Binding var mirostat_eta: Float
    @Binding var tfs_z: Float
    @Binding var typical_p: Float
    @Binding var grammar: String 
    @Binding var model_inference: String
    @Binding var grammars_previews: [String]
    
    
    var body: some View {
//        ScrollView{
            HStack{
                Text("Sampling:")
                    .frame(maxWidth: 110, alignment: .leading)
                Picker("", selection: $model_sampling) {
                    ForEach(model_samplings, id: \.self) {
                        Text($0)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .pickerStyle(.menu)
                .onChange(of: model_sampling) { sampling in
                    if sampling == "temperature" {
                        mirostat = 0
                    }
                    if sampling == "greedy" {
                        mirostat = 0
                        model_temp = 0
                    }
                    if sampling == "mirostat" {
                        mirostat = 1
                    }
                    if sampling == "mirostat_v2" {
                        mirostat = 2
                    }
                }
                //
            }
            .padding(.horizontal, 5)
            .padding(.top, 8)
            
            if model_sampling == "temperature" {
                Group {
                    
                    HStack {
                        Text("Repeat last N:")
                            .frame(maxWidth: 100, alignment: .leading)
                        TextField("count..", value: $model_repeat_last_n, format:.number)
                            .frame( alignment: .leading)
                            .multilineTextAlignment(.trailing)
                            .textFieldStyle(.plain)
#if os(iOS)
                            .keyboardType(.numberPad)
#endif
                    }
                    .padding(.horizontal, 5)
                    
                    HStack {
                        Text("Repeat Penalty:")
                            .frame(maxWidth: 100, alignment: .leading)
                        TextField("size..", value: $model_repeat_penalty, format:.number)
                            .frame( alignment: .leading)
                            .multilineTextAlignment(.trailing)
                            .textFieldStyle(.plain)
#if os(iOS)
                            .keyboardType(.numbersAndPunctuation)
#endif
                    }
                    .padding(.horizontal, 5)
                    
                    HStack {
                        Text("Temp:")
                            .frame(maxWidth: 75, alignment: .leading)
                        TextField("size..", value: $model_temp, format:.number)
                            .frame( alignment: .leading)
                            .multilineTextAlignment(.trailing)
                            .textFieldStyle(.plain)
#if os(iOS)
                            .keyboardType(.numbersAndPunctuation)
#endif
                    }
                    .padding(.horizontal, 5)
                    
                    HStack {
                        Text("Top_k:")
                            .frame(maxWidth: 75, alignment: .leading)
                        TextField("val..", value: $model_top_k, format:.number)
                            .frame( alignment: .leading)
                            .multilineTextAlignment(.trailing)
                            .textFieldStyle(.plain)
#if os(iOS)
                            .keyboardType(.numberPad)
#endif
                    }
                    .padding(.horizontal, 5)
                    
                    HStack {
                        Text("Top_p:")
                            .frame(maxWidth: 95, alignment: .leading)
                        TextField("val..", value: $model_top_p, format:.number)
                            .frame( alignment: .leading)
                            .multilineTextAlignment(.trailing)
                            .textFieldStyle(.plain)
#if os(iOS)
                            .keyboardType(.numbersAndPunctuation)
#endif
                    }
                    .padding(.horizontal, 5)
                    
                    
                    HStack {
                        Text("Tail Free Z:")
                            .frame(maxWidth: 100, alignment: .leading)
                        TextField("val..", value: $tfs_z, format:.number)
                            .frame( alignment: .leading)
                            .multilineTextAlignment(.trailing)
                            .textFieldStyle(.plain)
#if os(iOS)
                            .keyboardType(.numbersAndPunctuation)
#endif
                    }
                    .padding(.horizontal, 5)
                    
                    HStack {
                        Text("Locally Typical N:")
                            .frame(maxWidth: 140, alignment: .leading)
                        TextField("val..", value: $typical_p, format:.number)
                            .frame( alignment: .leading)
                            .multilineTextAlignment(.trailing)
                            .textFieldStyle(.plain)
#if os(iOS)
                            .keyboardType(.numbersAndPunctuation)
#endif
                    }
                    .padding(.horizontal, 5)
                    
                }
                
            }
            
            if model_sampling == "mirostat" || model_sampling == "mirostat_v2" {
                Group {
                    HStack {
                        Text("Mirostat_eta:")
                            .frame(maxWidth: 110, alignment: .leading)
                        TextField("val..", value: $mirostat_eta, format:.number)
                            .frame( alignment: .leading)
                            .multilineTextAlignment(.trailing)
                            .textFieldStyle(.plain)
#if os(iOS)
                            .keyboardType(.numbersAndPunctuation)
#endif
                    }
                    .padding(.horizontal, 5)
                    
                    HStack {
                        Text("Mirostat_tau:")
                            .frame(maxWidth: 110, alignment: .leading)
                        TextField("val..", value: $mirostat_tau, format:.number)
                            .frame( alignment: .leading)
                            .multilineTextAlignment(.trailing)
                            .textFieldStyle(.plain)
#if os(iOS)
                            .keyboardType(.numbersAndPunctuation)
#endif
                    }
                    .padding(.horizontal, 5)
                    
                    HStack {
                        Text("Temp:")
                            .frame(maxWidth: 75, alignment: .leading)
                        TextField("size..", value: $model_temp, format:.number)
                            .frame( alignment: .leading)
                            .multilineTextAlignment(.trailing)
                            .textFieldStyle(.plain)
#if os(iOS)
                            .keyboardType(.numbersAndPunctuation)
#endif
                    }
                    .padding(.horizontal, 5)
                }
            }
            
            if model_inference == "llama"{
                HStack{
                    Text("Grammar sampling:")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Picker("", selection: $grammar) {
                        ForEach(grammars_previews, id: \.self) {
                            Text($0)
                        }
                    }
                    .pickerStyle(.menu)
                    
                }
                .padding(.horizontal, 5)
                //                                .padding(.top, 8)
            }
        }
//    }
}

//#Preview {
//    SamplingSettingsView()
//}
