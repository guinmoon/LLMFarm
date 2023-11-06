//
//  FineTuneView.swift
//  LLMFarm
//
//  Created by guinmoon on 05.11.2023.
//

import SwiftUI


struct FineTuneView: View {
    @EnvironmentObject var aiChatModel: AIChatModel
    @State private var isModelImporting: Bool = false
    @State private var isDataSetImporting: Bool = false
    @State var models_previews = get_models_list()!
    @State var datasets_preview = get_datasets_list()!
    @State private var model_file_url: URL = URL(filePath: "/")
    @State private var model_file_path: String = "Select model"
    @State private var dataset_file_url: URL = URL(filePath: "/")
    @State private var dataset_file_path: String = "Select dataset"
    @State private var lora_name: String = ""
    @State private var n_ctx: Int32 = 64
    @State private var n_batch: Int32 = 4
    @State private var adam_iter: Int32 = 30
    @State private var n_threads: Int32 = 0
    @State private var use_metal: Bool = false
    @State private var use_checkpointing: Bool = false
    @State private var tune_log: String = ""
    
    
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
                                model_file_path = model["file_name"]!
                                lora_name = get_file_name_without_ext(fileName:model_file_path) + "_" + get_file_name_without_ext(fileName:dataset_file_path) + ".bin"
                            }
                        }
                    }
                } label: {
                    Label(model_file_path == "" ?"Select Model...":model_file_path, systemImage: "ellipsis.circle")
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
                    model_file_url = selectedFile
                    //                                    saveBookmark(url: selectedFile)
                    //#if os(iOS) || os(watchOS) || os(tvOS)
                    model_file_path = selectedFile.lastPathComponent
                    //#else
                    //                                    model_file_path = selectedFile.path
                    //#endif
                    lora_name = get_file_name_without_ext(fileName:model_file_path) + "_" + get_file_name_without_ext(fileName:dataset_file_path) + ".bin"
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
                        ForEach(datasets_preview, id: \.self) { model in
                            Button(model["file_name"]!){
                                //                                            model_file_name = model["file_name"]!
                                dataset_file_path = model["file_name"]!
                                lora_name = get_file_name_without_ext(fileName:model_file_path) + "_" + get_file_name_without_ext(fileName:dataset_file_path) + ".bin"
                            }
                        }
                    }
                } label: {
                    Label(dataset_file_path == "" ?"Select File...":dataset_file_path, systemImage: "ellipsis.circle")
                }.padding()
            }
            .fileImporter(
                isPresented: $isDataSetImporting,
                allowedContentTypes: [.data],
                allowsMultipleSelection: false
            ) { result in
                do {
                    guard let selectedFile: URL = try result.get().first else { return }
                    dataset_file_url = selectedFile
                    dataset_file_path = selectedFile.lastPathComponent
                    lora_name = get_file_name_without_ext(fileName:model_file_path) + "_" + get_file_name_without_ext(fileName:dataset_file_path) + ".bin"
                } catch {
                    print("Unable to add file")
                    print(error.localizedDescription)
                }
            }
            
            HStack {
#if os(macOS)
                Text("LoRA Name:")
                DidEndEditingTextField(text: $lora_name,didEndEditing: { newName in})
                    .frame(maxWidth: .infinity, alignment: .leading)
#else
                TextField("LoRA file name...", text: $lora_name)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textFieldStyle(.plain)
#endif
                
            }
            .padding()
            
            
            HStack {
                Text("Threads:")
                    .frame(maxWidth: 75, alignment: .leading)
                TextField("count..", value: $n_threads, format:.number)
                    .frame( alignment: .leading)
                    .multilineTextAlignment(.trailing)
                    .textFieldStyle(.plain)
#if os(iOS)
                    .keyboardType(.numberPad)
#endif
            }
            .padding(.horizontal)
            .padding(.top, 5)
            
            HStack {
                Toggle("Metal", isOn: $use_metal)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal)
            .padding(.bottom, 4)
            
            HStack {
                Toggle("Use Checkpointing", isOn: $use_checkpointing)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal)
            .padding(.bottom, 4)
            
            HStack {
                Text("Adam Iter:")
                    .frame(maxWidth: 95, alignment: .leading)
                TextField("count..", value: $adam_iter, format:.number)
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
                TextField("size..", value: $n_ctx, format:.number)
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
                TextField("size..", value: $n_batch, format:.number)
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
                TextEditor(text:$tune_log).frame(minHeight: 5)
            }
            .padding(.horizontal)
            
            HStack{
                Button {
                    Task {
                        
                    }
                } label: {
                    Text("Run finetune")
                }
            }
            .padding()
            .frame(maxWidth: .infinity,alignment: .trailing)
            
        }
        .frame(maxHeight: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/,alignment:.topLeading)
        .navigationTitle("FineTune")
    }
}

struct FineTuneView_Previews: PreviewProvider {
    static var previews: some View {
        FineTuneView()
    }
}
