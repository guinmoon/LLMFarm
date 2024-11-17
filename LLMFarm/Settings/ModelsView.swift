//
//  ContactsView.swift
//  ChatUI
//
//  Created by Shezad Ahamed on 05/08/21.
//

import SwiftUI
import UniformTypeIdentifiers

struct ModelsView: View {
    
    public var dir:String
    @State var searchText: String = ""
    @State var models_previews: [Dictionary<String, String>]
    @State var model_selection: String?
    @State private var isImporting: Bool = false
    @State private var modelImported: Bool = false
    let bin_type = UTType(tag: "bin", tagClass: .filenameExtension, conformingTo: nil)
    let gguf_type = UTType(tag: "gguf", tagClass: .filenameExtension, conformingTo: nil)
    @State private var model_file_url: URL = URL(filePath: "")
    @State private var model_file_name: String = ""
    @State private var model_file_path: String = "select model"
    @State private var add_button_icon: String = "plus.app"
    var targetExts = [".gguf",".bin"]
    
    init (_ dir:String){
        self.dir = dir
        self._models_previews = State(initialValue: getFileListByExts(dir:dir,exts:targetExts)!)
    }
    
    func delete(at offsets: IndexSet) {
        let chatsToDelete = offsets.map { self.models_previews[$0] }
        _ = removeFile(chatsToDelete,dest:dir)
        models_previews = getFileListByExts(dir:dir,exts:targetExts) ?? []
    }
    
    func delete(at elem:Dictionary<String, String>){
        _  = removeFile([elem],dest:dir)
        self.models_previews.removeAll(where: { $0 == elem })
        models_previews = getFileListByExts(dir:dir,exts:targetExts) ?? []
    }
    
    private func delayIconChange() {
        // Delay of 7.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            add_button_icon = "plus.app"
        }
    }
    
    
    
    var body: some View {
        //        ZStack{
        //            Color("color_bg").edgesIgnoringSafeArea(.all)
        GroupBox(label:
                 Text("Local models")
        ) {
            HStack{
                Spacer()
                Button {
                    Task {
                        isImporting.toggle()
                    }
                    
                } label: {
                    Image(systemName: add_button_icon)
                    //                            .foregroundColor(Color("color_primary"))
                        .font(.title2)
                }
                .buttonStyle(.borderless)
                .frame(alignment: .trailing)
                .padding([.top,.trailing])
                //                .controlSize(.large)
                .fileImporter(
                    isPresented: $isImporting,
                    //                            allowedContentTypes: [bin_type!,gguf_type!],
                    allowedContentTypes: [.data],
                    allowsMultipleSelection: false
                ) { result in
                    do {
                        guard let selectedFile: URL = try result.get().first else { return }
                        model_file_name = selectedFile.lastPathComponent
                        model_file_url = selectedFile
                        model_file_path = selectedFile.lastPathComponent
                        _ = CopyFileToSandbox(url: model_file_url,dest:dir)
                        modelImported = true
                        add_button_icon = "checkmark"
                        delayIconChange()
                        models_previews = getFileListByExts(dir:dir,exts:targetExts) ?? []
                        
                    } catch {
                        // Handle failure.
                        print("Unable to read file contents")
                        print(error.localizedDescription)
                    }
                }
            }
            VStack{
//                VStack(spacing: 5){
                    List(selection: $model_selection){
                        ForEach(models_previews, id: \.self) { model in
                            
                            ModelInfoItem(
                                modelIcon: String(describing: model["icon"]!),
                                file_name:  String(describing: model["file_name"]!),
                                orig_file_name:String(describing: model["file_name"]!),
                                description: String(describing: model["description"]!)
                            ).contextMenu {
                                Button(action: {
                                    delete(at: model)
                                }){
                                    Text("Delete")
                                }
                            }
                        }
                        .onDelete(perform: delete)
                        .listRowBackground(Color.gray.opacity(0))
                        
                    }
                    .scrollContentBackground(.hidden)
                    
                    .onAppear {
                        models_previews = getFileListByExts(dir:dir,exts:targetExts)  ?? []
                    }
#if os(macOS)
                    .listStyle(.sidebar)
#else
                    .listStyle(InsetListStyle())
#endif
//                }
                if  models_previews.count <= 0 {
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
            .frame(maxHeight: .infinity)
        }
        
        .padding(.horizontal,10)
//        .toolbar{
//
//        }
        //        .navigationTitle(dir)
        .onChange(of:dir){ dir in
            models_previews = getFileListByExts(dir:dir,exts:targetExts)  ?? []
        }
    }
//    }
}

//struct ContactsView_Previews: PreviewProvider {
//    static var previews: some View {
//        ModelsView()
//    }
//}

