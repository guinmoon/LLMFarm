//
//  FineTuneView.swift
//  LLMFarm
//
//  Created by guinmoon on 05.11.2023.
//

import SwiftUI


struct ExportLoraView: View {
    @EnvironmentObject var fineTuneModel: FineTuneModel
    @State private var isModelImporting: Bool = false
    @State private var isDataSetImporting: Bool = false
    @State var models_previews = getFileListByExts(exts:[".gguf",".bin"]) ?? []
    @State var loras_preview = getFileListByExts(dir:"lora_adapters",exts:[".bin"]) ?? []
    
    
    
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
                                fineTuneModel.export_model_name = GetFileNameWithoutExt(fileName:fineTuneModel.model_file_path) + "_" + GetFileNameWithoutExt(fileName:fineTuneModel.lora_file_path) + ".gguf"
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
                    fineTuneModel.lora_name = GetFileNameWithoutExt(fileName:fineTuneModel.model_file_path) + "_" + GetFileNameWithoutExt(fileName:fineTuneModel.lora_file_path) + ".gguf"
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
                    
                    Section("Avalible adapters") {
                        ForEach(loras_preview, id: \.self) { model in
                            Button(model["file_name"]!){
                                //                                            model_file_name = model["file_name"]!
                                fineTuneModel.lora_file_path = model["file_name"]!
                                fineTuneModel.export_model_name = GetFileNameWithoutExt(fileName:fineTuneModel.model_file_path) + "_" + GetFileNameWithoutExt(fileName:fineTuneModel.lora_file_path) + ".gguf"
                            }
                        }
                    }
                } label: {
                    Label(fineTuneModel.lora_file_path == "" ?"Select Adapter...":fineTuneModel.lora_file_path, systemImage: "ellipsis.circle")
                }.padding()
            }
            .fileImporter(
                isPresented: $isDataSetImporting,
                allowedContentTypes: [.data],
                allowsMultipleSelection: false
            ) { result in
                do {
                    guard let selectedFile: URL = try result.get().first else { return }
                    fineTuneModel.lora_file_url = selectedFile
                    fineTuneModel.lora_file_path = selectedFile.lastPathComponent
                    fineTuneModel.lora_name = GetFileNameWithoutExt(fileName:fineTuneModel.model_file_path) + "_" + GetFileNameWithoutExt(fileName:fineTuneModel.lora_file_path) + ".gguf"
                } catch {
                    print("Unable to add file")
                    print(error.localizedDescription)
                }
            }
            
            HStack {
#if os(macOS)
                Text("Result model name:")
                DidEndEditingTextField(text: $fineTuneModel.export_model_name,didEndEditing: { newName in})
                    .frame(maxWidth: .infinity, alignment: .leading)
#else
                TextField("Result model name...", text: $fineTuneModel.export_model_name)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textFieldStyle(.plain)
#endif
                
            }
            .padding()
            
            
//            HStack {
//                Text("Threads:")
//                    .frame(maxWidth: 75, alignment: .leading)
//                TextField("count..", value: $fineTuneModel.n_threads, format:.number)
//                    .frame( alignment: .leading)
//                    .multilineTextAlignment(.trailing)
//                    .textFieldStyle(.plain)
//#if os(iOS)
//                    .keyboardType(.numberPad)
//#endif
//            }
//            .padding(.horizontal)
//            .padding(.top, 5)
        
            
            HStack {
                Text("Scale:")
                    .frame(maxWidth: 95, alignment: .leading)
                TextField("scale..", value: $fineTuneModel.lora_scale, format:.number)
                    .frame( alignment: .leading)
                    .multilineTextAlignment(.trailing)
                    .textFieldStyle(.plain)
            }
            .padding(.horizontal)
            
            if fineTuneModel.state == .export {
                VStack {
                    ProgressView(value: fineTuneModel.progress)
                }
                .padding(.horizontal)
            }
            
            HStack{
                Button {
                    Task {
                        await fineTuneModel.export_lora()
                    }
                } label: {
                    Text("Export")
                }
                .disabled(fineTuneModel.state == .export)
                
            }
            .padding()
            .frame(maxWidth: .infinity,alignment: .trailing)
            
        }
        .frame(maxHeight: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/,alignment:.topLeading)
        .navigationTitle("Merge LoRA")
        .disabled(fineTuneModel.state == .cancel)
    }
}

struct ExportLoraView_Previews: PreviewProvider {
    static var previews: some View {
        ExportLoraView()
    }
}
