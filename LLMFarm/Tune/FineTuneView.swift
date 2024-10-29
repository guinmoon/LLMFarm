//
//  FineTuneView.swift
//  LLMFarm
//
//  Created by guinmoon on 05.11.2023.
//

import SwiftUI


struct FineTuneView: View {
    @EnvironmentObject var fineTuneModel: FineTuneModel
    @State private var isModelImporting: Bool = false
    @State private var isDataSetImporting: Bool = false
    @State var models_previews = getFileListByExts(exts:[".gguf",".bin"]) ?? []
    @State var datasets_preview = getFileListByExts(dir:"datasets",exts:[".txt"]) ?? []
    
    
    var body: some View {
        VStack(alignment: .leading){
            HStack {
                Menu {
                    Button {
                        Task {
                            isModelImporting = true
                        }
                    } label: {
                        Label("Import from file...", systemImage: "plus.app")
                    }
                    
                    Divider()
                    
                    Section("Avalible models") {
                        ForEach(models_previews, id: \.self) { model in
                            Button(model["file_name"]!){
                                //                                            model_file_name = model["file_name"]!
                                fineTuneModel.model_file_path = model["file_name"]!
                                fineTuneModel.lora_name = GetFileNameWithoutExt(fileName:fineTuneModel.model_file_path) + "_" + GetFileNameWithoutExt(fileName:fineTuneModel.dataset_file_path) + ".bin"
                            }
                        }
                    }
                } label: {
                    Label(fineTuneModel.model_file_path == "" ?"Select Model...":fineTuneModel.model_file_path, systemImage: "ellipsis.circle")
                }.padding()
            }
            .fileImporter(
                isPresented: $isModelImporting,
                allowedContentTypes: [.data],
                allowsMultipleSelection: false
            ) { result in
                do {
                    guard let selectedFile: URL = try result.get().first else { return }
                    //                                model_file.input = selectedFile.lastPathComponent
                    //                                model_file_name = selectedFile.lastPathComponent
                    fineTuneModel.model_file_url = selectedFile
                    //                                    saveBookmark(url: selectedFile)
                    //#if os(iOS) || os(watchOS) || os(tvOS)
                    fineTuneModel.model_file_path = selectedFile.lastPathComponent
                    //#else
                    //                                    model_file_path = selectedFile.path
                    //#endif
                    fineTuneModel.lora_name = GetFileNameWithoutExt(fileName:fineTuneModel.model_file_path) + "_" + GetFileNameWithoutExt(fileName:fineTuneModel.dataset_file_path) + ".bin"
                } catch {
                    // Handle failure.
                    print("Unable to read file contents")
                    print(error.localizedDescription)
                }
            }
            
            
            HStack {
                
                Menu {
                    Button {
                        Task {
                            isDataSetImporting = true
                        }
                    } label: {
                        Label("Import from file...", systemImage: "plus.app")
                    }
                    
                    Divider()
                    
                    Section("Avalible datasets") {
                        ForEach(datasets_preview, id: \.self) { model in
                            Button(model["file_name"]!){
                                //                                            model_file_name = model["file_name"]!
                                fineTuneModel.dataset_file_path = model["file_name"]!
                                fineTuneModel.lora_name = GetFileNameWithoutExt(fileName:fineTuneModel.model_file_path) + "_" + GetFileNameWithoutExt(fileName:fineTuneModel.dataset_file_path) + ".bin"
                            }
                        }
                    }
                } label: {
                    Label(fineTuneModel.dataset_file_path == "" ?"Select File...":fineTuneModel.dataset_file_path, systemImage: "ellipsis.circle")
                }.padding()
            }
            .fileImporter(
                isPresented: $isDataSetImporting,
                allowedContentTypes: [.data],
                allowsMultipleSelection: false
            ) { result in
                do {
                    guard let selectedFile: URL = try result.get().first else { return }
                    fineTuneModel.dataset_file_url = selectedFile
                    fineTuneModel.dataset_file_path = selectedFile.lastPathComponent
                    fineTuneModel.lora_name = GetFileNameWithoutExt(fileName:fineTuneModel.model_file_path) + "_" + GetFileNameWithoutExt(fileName:fineTuneModel.dataset_file_path) + ".txt"
                } catch {
                    print("Unable to add file")
                    print(error.localizedDescription)
                }
            }
            
            HStack {
#if os(macOS)
                Text("LoRA Name:")
                DidEndEditingTextField(text: $fineTuneModel.lora_name,didEndEditing: { newName in})
                    .frame(maxWidth: .infinity, alignment: .leading)
#else
                TextField("LoRA file name...", text: $fineTuneModel.lora_name)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textFieldStyle(.plain)
#endif
                
            }
            .padding()
            
            
            HStack {
                Text("Threads:")
                    .frame(maxWidth: 75, alignment: .leading)
                TextField("count..", value: $fineTuneModel.n_threads, format:.number)
                    .frame( alignment: .leading)
                    .multilineTextAlignment(.trailing)
                    .textFieldStyle(.plain)
#if os(iOS)
                    .keyboardType(.numberPad)
#endif
            }
            .padding(.horizontal)
            .padding(.top, 5)
            
//            HStack {
//                Toggle("Metal", isOn: $fineTuneModel.use_metal)
//                    .frame(maxWidth: .infinity, alignment: .leading)
//            }
//            .padding(.horizontal)
//            .padding(.bottom, 4)
            
            HStack {
                Toggle("Use Checkpointing", isOn: $fineTuneModel.use_checkpointing)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal)
            .padding(.bottom, 4)
            
            HStack {
                Toggle("Use Metal", isOn: $fineTuneModel.use_metal)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal)
            .padding(.bottom, 4)
            
            HStack {
                Text("Adam Iter:")
                    .frame(maxWidth: 95, alignment: .leading)
                TextField("count..", value: $fineTuneModel.adam_iter, format:.number)
                    .frame( alignment: .leading)
                    .multilineTextAlignment(.trailing)
                    .textFieldStyle(.plain)
#if os(iOS)
                    .keyboardType(.numberPad)
#endif
            }
            .padding(.horizontal)
            
            HStack {
                Text("Context:")
                    .frame(maxWidth: 75, alignment: .leading)
                TextField("size..", value: $fineTuneModel.n_ctx, format:.number)
                    .frame( alignment: .leading)
                    .multilineTextAlignment(.trailing)
                    .textFieldStyle(.plain)
#if os(iOS)
                    .keyboardType(.numberPad)
#endif
            }
            .padding(.horizontal)
            
            HStack {
                Text("N_Batch:")
                    .frame(maxWidth: 75, alignment: .leading)
                TextField("size..", value: $fineTuneModel.n_batch, format:.number)
                    .frame( alignment: .leading)
                    .multilineTextAlignment(.trailing)
                    .textFieldStyle(.plain)
#if os(iOS)
                    .keyboardType(.numberPad)
#endif
            }
            .padding(.horizontal)
            
            VStack {
                Text("Log:")
                    .frame(maxWidth: 75, alignment: .leading)
                TextEditor(text:$fineTuneModel.tune_log).frame(minHeight: 5)
            }
            .padding(.horizontal)
//            .onChange(of: fineTuneModel.llama_finetune.tune_log)
            
            if fineTuneModel.state == .tune {
                VStack {
                    ProgressView(value: fineTuneModel.progress)
                }
                .padding(.horizontal)
            }
            
            HStack{
                if fineTuneModel.state == .tune{
                    Button {
                        Task {
                            await fineTuneModel.cancel_finetune()
                        }
                    } label: {
                        Text("Cancel")
                    }
                }else{
                    Button {
                        Task {
                            await fineTuneModel.finetune()
                        }
                    } label: {
                        Text("Run finetune")
                    }
                }
                
            }
            .padding()
            .frame(maxWidth: .infinity,alignment: .trailing)
            
        }
        .frame(maxHeight: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/,alignment:.topLeading)
        .navigationTitle("FineTune")
        .disabled(fineTuneModel.state == .cancel)
    }
}

struct FineTuneView_Previews: PreviewProvider {
    static var previews: some View {
        FineTuneView()
    }
}
