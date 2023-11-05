//
//  FineTuneView.swift
//  LLMFarm
//
//  Created by guinmoon on 05.11.2023.
//

import SwiftUI


struct FineTuneView: View {
    @State private var isModelImporting: Bool = false
    @State private var isDataSetImporting: Bool = false
    @State var models_previews = get_models_list()!
    @State var datasets_preview = get_datasets_list()!
    @State private var model_file_url: URL = URL(filePath: "/")
    @State private var model_file_path: String = "Select model"
    @State private var dataset_file_url: URL = URL(filePath: "/")
    @State private var dataset_file_path: String = "Select dataset"
    @State private var lora_name: String = ""
    
    var body: some View {
        VStack{
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
                                lora_name = get_file_name_without_ext(fileName:model_file_path) + ".bin"
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
                    lora_name = get_file_name_without_ext(fileName:selectedFile.lastPathComponent) + ".bin"
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
//                                lora_title = get_file_name_without_ext(fileName:lora_file_path)
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
//                    lora_title = get_file_name_without_ext(fileName:selectedFile.lastPathComponent)
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
                TextField("Title...", text: $lora_name)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textFieldStyle(.plain)
#endif
                
            }
            .padding()
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
