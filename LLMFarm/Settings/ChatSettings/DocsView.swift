//
//  DocsView.swift
//  LLMFarm
//
//  Created by guinmoon on 19.10.2024.
//

import SwiftUI

//
//  ContactsView.swift
//  ChatUI
//
//  Created by Shezad Ahamed on 05/08/21.
//

import SwiftUI
import UniformTypeIdentifiers

struct DocsView: View {
    
    public var dir:String
    @State var searchText: String = ""
    @State var docsPreviews: [Dictionary<String, String>]
    @State var docSelection: String?
    @State private var isImporting: Bool = false
    @State private var modelImported: Bool = false
    let binType = UTType(tag: "txt", tagClass: .filenameExtension, conformingTo: nil)
    let ggufType = UTType(tag: "pdf", tagClass: .filenameExtension, conformingTo: nil)
    @State private var docFileUrl: URL = URL(filePath: "")
    @State private var docFileName: String = ""
    @State private var docFilePath: String = "select model"
    @State private var addButtonIcon: String = "plus.app"
    var targetExts = [".pdf",".txt"]
    
    init (_ dir:String){
        self.dir = dir
        self._docsPreviews = State(initialValue: getFileListByExts(dir:dir,exts:targetExts)!)
    }
    
    func delete(at offsets: IndexSet) {
        let chatsToDelete = offsets.map { self.docsPreviews[$0] }
        _ = delete_models(chatsToDelete,dest:dir)
        docsPreviews = getFileListByExts(dir:dir,exts:targetExts) ?? []
    }
    
    func delete(at elem:Dictionary<String, String>){
        _  = delete_models([elem],dest:dir)
        self.docsPreviews.removeAll(where: { $0 == elem })
        docsPreviews = getFileListByExts(dir:dir,exts:targetExts) ?? []
    }
    
    private func delayIconChange() {
        // Delay of 7.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            addButtonIcon = "plus.app"
        }
    }
    
    
    
    var body: some View {
        //        ZStack{
        //            Color("color_bg").edgesIgnoringSafeArea(.all)
        GroupBox(label:
                 Text("Documents for RAG")
        ) {
            HStack{
                Spacer()
                Button {
                    Task {
                        isImporting.toggle()
                    }
                    
                } label: {
                    Image(systemName: addButtonIcon)
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
                        docFileName = selectedFile.lastPathComponent
                        docFileUrl = selectedFile
                        docFilePath = selectedFile.lastPathComponent
                        _ = copyFileToSandbox(url: docFileUrl,dest:dir)
                        modelImported = true
                        addButtonIcon = "checkmark"
                        delayIconChange()
                        docsPreviews = getFileListByExts(dir:dir,exts:targetExts) ?? []
                        
                    } catch {
                        // Handle failure.
                        print("Unable to read file contents")
                        print(error.localizedDescription)
                    }
                }
            }
            VStack{
//                VStack(spacing: 5){
                    List(selection: $docSelection){
                        ForEach(docsPreviews, id: \.self) { model in
                            
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
                        docsPreviews = getFileListByExts(dir:dir,exts:targetExts)  ?? []
                    }
#if os(macOS)
                    .listStyle(.sidebar)
#else
                    .listStyle(InsetListStyle())
#endif
//                }
                if  docsPreviews.count <= 0 {
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
                        Text("Add file")
                            .font(.title3)
                            .frame(maxWidth: .infinity)
                        
                    }.opacity(0.4)
                        .frame(maxWidth: .infinity,alignment: .center)
                }
                
            }
            .frame(maxHeight: .infinity)
        }
        
//        .padding(.horizontal,10)
//        .toolbar{
//
//        }
        //        .navigationTitle(dir)
        .onChange(of:dir){ dir in
            docsPreviews = getFileListByExts(dir:dir,exts:targetExts)  ?? []
        }
    }
//    }
}

//struct ContactsView_Previews: PreviewProvider {
//    static var previews: some View {
//        ModelsView()
//    }
//}



//#Preview {
//    DocsView()
//}
