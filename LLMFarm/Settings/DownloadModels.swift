//
//  ContactsView.swift
//  ChatUI
//
//  Created by Shezad Ahamed on 05/08/21.
//

import SwiftUI
import UniformTypeIdentifiers

public protocol Tabbable: Identifiable {
    associatedtype Id
    var id: Id { get }
    
    var name : String { get }
}

struct DownloadModelsView: View {
    

    @State var searchText: String = ""
    @State var models_info: [DownloadModelInfo] = get_downloadble_models("downloadable_models.json") ?? []
    @State var model_selection: String?
    @State private var isImporting: Bool = false
    @State private var modelImported: Bool = false
    let bin_type = UTType(tag: "bin", tagClass: .filenameExtension, conformingTo: nil)
    let gguf_type = UTType(tag: "gguf", tagClass: .filenameExtension, conformingTo: nil)
    @State private var model_file_url: URL = URL(filePath: "")
    @State private var model_file_name: String = ""
    @State private var model_file_path: String = "select model"
    @State private var add_button_icon: String = "plus.app"

//    @State private var downloadTask: URLSessionDownloadTask?
//    @State private var progress = 0.0
//    @State private var observation: NSKeyValueObservation?

//    private static func getFileURL(filename: String) -> URL {
//        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(filename)
//    }
//    
    
//    init (){
//        self._models_info = State(initialValue: get_downloadble_models("downloadable_models.json")!)
//    }
    
    
    func delete(at offsets: IndexSet) {
//        let chatsToDelete = offsets.map { self.models_info[$0] }
//        _ = delete_models(chatsToDelete,dest:dir)
//        models_info = get_models_list(dir:dir) ?? []        
    }
    
    func delete(at elem:Dictionary<String, String>){
//        _  = delete_models([elem],dest:dir)
//        self.models_info.removeAll(where: { $0 == elem })
//        models_info = get_models_list(dir:dir) ?? []
    }
    
    private func delayIconChange() {
        // Delay of 7.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            add_button_icon = "plus.app"
        }
    }
    
    
    
    var body: some View {
        ZStack{
            //            Color("color_bg").edgesIgnoringSafeArea(.all)
            VStack{
//                 Button(action: {
//                    let fileURL = DownloadButton.getFileURL(filename: filename)
//                    if !FileManager.default.fileExists(atPath: fileURL.path) {
//                        download()
//                        return
//                    }
//                    do {
//                        try llamaState.loadModel(modelUrl: fileURL)
//                    } catch let err {
//                        print("Error: \(err.localizedDescription)")
//                    }
//                }) {
//                    Text("Load \(modelName)")
//                }
                VStack(spacing: 5){
                    List(selection: $model_selection){
                        ForEach(models_info, id: \.self) { model_info  in

                            ModelDownloadItem(modelInfo:model_info)
//                                modelName: model["name"],
//                                modelIcon: "square.stack.3d.up.fill",
//                                model_files:  model["models"])                          
                        }
//                        .onDelete(perform: delete)
                    }
#if os(macOS)
                    .listStyle(.sidebar)
#else
                    .listStyle(InsetListStyle())
#endif
                }
                if  models_info.count <= 0 {
                    VStack{
                        
                        Button {
                            Task {
                                isImporting.toggle()
                            }
                        } label: {
                            Image(systemName: "plus.square.dashed")
                                .foregroundColor(.secondary)
                                .font(.system(size: 40))
                        }
                        .buttonStyle(.borderless)
                        .controlSize(.large)
                        Text("Add model")
                            .font(.title3)
                            .frame(maxWidth: .infinity)
                        
                    }.opacity(0.4)
                        .frame(maxWidth: .infinity,alignment: .center)
                }
                
            }
        }
        .toolbar{
           
        }
        .navigationTitle("Download models")      
    }
}

