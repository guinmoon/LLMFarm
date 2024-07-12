//
//  PredictionSettingsView.swift
//  LLMFarm
//
//  Created by guinmoon on 22.06.2024.
//

import SwiftUI

struct PredictionSettingsView: View {
    
    @Binding var model_context: Int32
    @Binding var model_n_batch: Int32
    @Binding var n_predict: Int32
    @Binding var numberOfThreads: Int32
    @Binding var use_metal: Bool
    @Binding var use_clip_metal: Bool
    @Binding var mlock: Bool
    @Binding var mmap: Bool
    @Binding var flash_attn: Bool
    @Binding var model_inference:String
    @Binding var model_inference_inner:String
    @Binding var has_clip: Bool
    
    var body: some View {
        HStack {
            Text("Threads:")
                .frame(maxWidth: 75, alignment: .leading)
            TextField("count..", value: $numberOfThreads, format:.number)
                .frame( alignment: .leading)
                .multilineTextAlignment(.trailing)
                .textFieldStyle(.plain)
#if os(iOS)
                .keyboardType(.numberPad)
#endif
        }
        .padding(.horizontal, 5)
        .padding(.top)
        
        HStack {
            Toggle("Metal", isOn: $use_metal)
                .frame(maxWidth: 120, alignment: .leading)
                .disabled((model_inference != "llama" && model_inference_inner != "gpt2" ) /*|| hardware_arch=="x86_64"*/)
            if (has_clip == true){
                Toggle("ClipM", isOn: $use_clip_metal)
                    .frame(maxWidth: 120, alignment: .leading)
            }
            Toggle("FAttn", isOn: $flash_attn)
               .frame(maxWidth: 120, alignment: .leading)
               .disabled((self.model_inference != "llama" && self.model_inference_inner != "gpt2" ) /*|| hardware_arch=="x86_64"*/)
            Spacer()
        }
        .padding(.horizontal, 5)
        .padding(.bottom, 4)
        
        HStack {
            Toggle("MLock", isOn: $mlock)
                .frame(maxWidth: 120,  alignment: .leading)
                .disabled(self.model_inference != "llama" && self.model_inference_inner != "gpt2" )
            Toggle("MMap", isOn: $mmap)
                .frame(maxWidth: 120,  alignment: .leading)
                .disabled(self.model_inference != "llama" && self.model_inference_inner != "gpt2" )
            Spacer()
        }
        .padding(.horizontal, 5)
        .padding(.bottom, 4)
        
        HStack {
            Text("Context:")
                .frame(maxWidth: 75, alignment: .leading)
            TextField("size..", value: $model_context, format:.number)
                .frame( alignment: .leading)
                .multilineTextAlignment(.trailing)
                .textFieldStyle(.plain)
#if os(iOS)
                .keyboardType(.numberPad)
#endif
        }
        .padding(.horizontal, 5)
        
        HStack {
            Text("Batch size:")
                .frame(maxWidth: 100, alignment: .leading)
            TextField("size..", value: $model_n_batch, format:.number)
                .frame( alignment: .leading)
                .multilineTextAlignment(.trailing)
                .textFieldStyle(.plain)
#if os(iOS)
                .keyboardType(.numberPad)
#endif
        }
        .padding(.horizontal, 5)

        HStack {
            Text("Predict count:")
                .frame(maxWidth: 120, alignment: .leading)
            TextField("count..", value: $n_predict, format:.number)
                .frame( alignment: .leading)
                .multilineTextAlignment(.trailing)
                .textFieldStyle(.plain)
#if os(iOS)
                .keyboardType(.numberPad)
#endif
        }
        .padding(.horizontal, 5)
    }
}

//#Preview {
//    PredictionSettingsView()
//}
