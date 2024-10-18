//
//  ContactItem.swift
//  ChatUI
//
//  Created by Shezad Ahamed on 6/08/21.
//

import SwiftUI



struct ModelDownloadItem: View {
    
    @State var modelName: String
    var modelIcon: String = "square.2.layers.3d"
    @State var file_name: String = ""
    @State var orig_file_name: String = ""
    var description: String = ""
    @State var model_files: [Dictionary<String, String>] = []
    @State var download_url: String = ""
    @State var modelQuantization:String = ""
    @State var status = ""
    var modelSize:String = ""
    var modelInfo:DownloadModelInfo
    
    
    
    init(modelInfo: DownloadModelInfo) {
        self.modelInfo = modelInfo
        self._modelName = State(initialValue:modelInfo.name ?? "Undefined")
        self._model_files = State(initialValue:modelInfo.models ?? [])
        if self.model_files.count>0{
            self._modelQuantization = State(initialValue:self.model_files[0]["Q"] ?? "")
            self._download_url = State(initialValue:self.model_files[0]["url"] ?? "")
            self._file_name = State(initialValue:self.model_files[0]["file_name"] ?? "")
            self._status=State(initialValue:FileManager.default.fileExists(atPath: getFileURLFormPathStr(dir:"models",filename: self.file_name).path) ? "downloaded" : "download")
        }
    }
    
    
    func model_name_canged(){
        let res = rename_file(orig_file_name,file_name,"models")
        if res {
            orig_file_name = file_name
        }else{
            print("Rename error!")
        }
    }
    
    var body: some View {
        HStack{
//            Image(systemName: modelIcon)
//                .resizable()
//            //                .background( Color("color_bg_inverted").opacity(0.05))
//                .padding(EdgeInsets(top: 3, leading: 1, bottom: 3, trailing: 1))
//                .frame(width: 40, height: 40)
//                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 1){
                
                HStack
                {
                    
                    Text(modelName)
                        .frame( alignment: .leading)
                    
                    Spacer()
                    
                    Menu {
                        
                        Section("Quantization") {
                            ForEach(model_files, id: \.self) { model_info in
                                Button(model_info["Q"]!){
                                    file_name = model_info["file_name"] ?? ""
                                    download_url = model_info["url"] ?? ""
                                    modelQuantization = model_info["Q"] ?? ""
                                    status  = FileManager.default.fileExists(atPath: getFileURLFormPathStr(dir:"models",filename: file_name).path) ? "downloaded" : "download"
                                }
                            }
                        }
                    } label: {
                        Label(modelQuantization == "" ?"Q":modelQuantization, systemImage: "ellipsis.circle")
                    }
                    .frame( alignment: .trailing)
                    .frame( maxWidth: 90)
                    .frame( maxHeight: 30)
                    
//                    if download_url != ""{
                    DownloadButton(modelName: $modelName, modelUrl: $download_url, filename:$file_name, status:$status)
                            .frame( alignment: .trailing)
                            .frame( maxWidth: 50)
//                    }
                }
                
                HStack{
                    Text(description)
                        .lineLimit(/*@START_MENU_TOKEN@*/2/*@END_MENU_TOKEN@*/)
                    
                }
                
            }
            .padding(.horizontal, 10)
            
        }
    }
}
