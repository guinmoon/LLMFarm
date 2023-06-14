//
//  ChatListView.swift
//  ChatUI
//
//  Created by Shezad Ahamed on 05/08/21.
//

import SwiftUI
import UniformTypeIdentifiers

struct InputDoument: FileDocument {

    static var readableContentTypes: [UTType] { [.plainText] }

    var input: String

    init(input: String) {
        self.input = input
    }

    init(configuration: FileDocumentReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        input = string
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return FileWrapper(regularFileWithContents: input.data(using: .utf8)!)
    }

}


struct SelectInference: View {
    @State private var selection = "Red"
    let colors = ["Red", "Green", "Blue", "Black", "Tartan"]

    var body: some View {
        VStack {
            Picker("Select an inference", selection: $selection) {
                ForEach(colors, id: \.self) {
                    Text($0)
                }
            }
            .pickerStyle(.menu)

            Text("Selected inference: \(selection)")
        }
    }
}

struct AddChatView: View {
    
    @Binding var add_chat_dialog: Bool
    @Binding var edit_chat_dialog: Bool
//    @State private var model_file: InputDoument = InputDoument(input: "")
    @State private var model_file_url: URL = URL(filePath: "")
    @State private var model_file_name: String = ""
    @State private var model_file_path: String = "select model"
    @State private var model_title: String = ""
    @State private var model_context: String = "1024"
    @State private var model_n_batch: String = "512"
    @State private var model_temp: String = "0.9"
    @State private var model_top_k: String = "40"
    @State private var model_top_p: String = "0.95"
    @State private var prompt_format: String = "auto"
    @State private var model_icon: String = "ava0"
    @State private var numberOfThreads: String = "0"
    @State private var isImporting: Bool = false
    private var chat_name: String = ""
    let bin_type = UTType(tag: "bin", tagClass: .filenameExtension, conformingTo: nil)
    
    @State private var model_inference = "auto"
    let model_inferences = ["auto","gptneox", "llama"]
    
    init(add_chat_dialog: Binding<Bool>,edit_chat_dialog:Binding<Bool>) {
        self._add_chat_dialog = add_chat_dialog
        self._edit_chat_dialog = edit_chat_dialog
    }
    
    init(add_chat_dialog: Binding<Bool>,edit_chat_dialog:Binding<Bool>,chat_name:String
    ) {
        self._add_chat_dialog = add_chat_dialog
        self._edit_chat_dialog = edit_chat_dialog
        self.chat_name = chat_name
        let chat_config = get_chat_info(chat_name)
        if (chat_config!["title"] != nil){
            self._model_title = State(initialValue: chat_config!["title"]! as! String)
        }
        if (chat_config!["model"] != nil){
            self._model_file_path = State(initialValue: chat_config!["model"]! as! String)
        }
        if (chat_config!["icon"] != nil){
            self._model_icon = State(initialValue: chat_config!["icon"]! as! String)
        }
        if (chat_config!["model_inference"] != nil){
            self._model_inference = State(initialValue: chat_config!["model_inference"]! as! String)
        }
        if (chat_config!["prompt_format"] != nil){
            self._prompt_format = State(initialValue: chat_config!["prompt_format"]! as! String)
        }
        if (chat_config!["numberOfThreads"] != nil){
            self._numberOfThreads = State(initialValue: String(chat_config!["numberOfThreads"]! as! Int32))
        }
        if (chat_config!["context"] != nil){
            self._model_context = State(initialValue: String(chat_config!["context"]! as! Int32))
        }
        if (chat_config!["n_batch"] != nil){
            self._model_n_batch = State(initialValue: String(chat_config!["n_batch"]! as! Int32))
        }
        if (chat_config!["top_k"] != nil){
            self._model_top_k = State(initialValue: String(chat_config!["top_k"]! as! Int32))
        }
        if (chat_config!["temp"] != nil){
            self._model_temp = State(initialValue: String(chat_config!["temp"]! as! Float))
        }
        if (chat_config!["top_p"] != nil){
            self._model_top_p = State(initialValue: String(chat_config!["top_p"]! as! Float))
        }
    }
    
    var body: some View {
        ZStack{
            Color("color_bg").edgesIgnoringSafeArea(.all)
            VStack{
                
                HStack{
                    Button {
                        Task {
                            add_chat_dialog = false
                        }
                    } label: {
                        Text("Cancel")
                    }
                    Text(edit_chat_dialog ? "Edit Chat" :"Add Chat" )
                        .fontWeight(.semibold)
                        .font(.title3)
                        .frame(maxWidth:.infinity, alignment: .center)
                        .padding(.trailing, 30)
                    Spacer()
                    Button {
                        Task {
                            if !edit_chat_dialog {
                                let sandbox_path = copyModelToSandbox(url: model_file_url)
//#if os(macOS)
                                model_file_path = sandbox_path!
//#endif
                            }
                            let options:Dictionary<String, Any> = ["model":model_file_path,
                                                                   "title":model_title,
                                                                   "context":Int32(model_context),
                                                                   "n_batch":Int32(model_n_batch),
                                                                   "temp":Float(model_temp),
                                                                   "top_k":Int32(model_top_k),
                                                                   "top_p":Float(model_top_p),
                                                                   "model_inference":model_inference,
                                                                   "prompt_format":prompt_format,
                                                                   "numberOfThreads":Int32(numberOfThreads),
                                                                   "icon":model_icon]
                            let res = create_chat(options,edit_chat_dialog:self.edit_chat_dialog,chat_name:self.chat_name)
                            add_chat_dialog = false
                            edit_chat_dialog = false
                        }
                    } label: {
                        Text(edit_chat_dialog ? "Save" :"Add" )
                    }
                    .disabled(model_title=="")
                }
                
                ScrollView(showsIndicators: false){
                    VStack(alignment: .leading, spacing: 5){
                        
                        HStack {
                            //                            Text(model_file.input)
                            TextField("Title...", text: $model_title)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                        }
                        .padding()
                                                
                        
                        if !edit_chat_dialog{
                            HStack {
                                //                            Text(model_file.input)
                                TextField("Model file...", text: $model_file_name)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Button {
                                    Task {
                                        isImporting = true
                                    }
                                } label: {
                                    Text("Select")
                                }
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                
                            }
                            .padding()
                            .fileImporter(
                                isPresented: $isImporting,
                                allowedContentTypes: [bin_type!],
                                allowsMultipleSelection: false
                            ) { result in
                                do {
                                    guard let selectedFile: URL = try result.get().first else { return }
                                    //                                model_file.input = selectedFile.lastPathComponent
                                    model_file_name = selectedFile.lastPathComponent
                                    model_file_url = selectedFile
//                                    saveBookmark(url: selectedFile)
//#if os(iOS) || os(watchOS) || os(tvOS)
                                    model_file_path = selectedFile.lastPathComponent
//#else
//                                    model_file_path = selectedFile.path
//#endif
                                    model_title = get_file_name_without_ext(fileName:selectedFile.lastPathComponent)
                                } catch {
                                    // Handle failure.
                                    print("Unable to read file contents")
                                    print(error.localizedDescription)
                                }
                            }
                        }
                        
                        Divider()
                            .padding(.top, 8)
                        
                        HStack{
                            Text("Infc:")
                                .frame(maxWidth: .infinity, alignment: .leading)
                            VStack {
                                Picker("Select an inference", selection: $model_inference) {
                                    ForEach(model_inferences, id: \.self) {
                                        Text($0)
                                    }
                                }
                                .pickerStyle(.menu)
                            }
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        .padding()
                        
                        HStack {
                            Text("Prompt format:")
                                .frame(maxWidth: .infinity, alignment: .leading)
                            TextField("size..", text: $prompt_format)
                                .frame( alignment: .leading)
                                .multilineTextAlignment(.trailing)
                        }
                        .padding()
                        
                        Divider()
                            .padding(.top, 8)
                        
                        Group {
                            HStack {
                                Text("Threads:")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                TextField("size..", text: $numberOfThreads)
                                    .frame( alignment: .leading)
                                    .multilineTextAlignment(.trailing)
                            }
                            .padding()
                            
                            HStack {
                                Text("Context:")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                TextField("size..", text: $model_context)
                                    .frame( alignment: .leading)
                                    .multilineTextAlignment(.trailing)
                            }
                            .padding(.horizontal)
                                                                                
                            HStack {
                                Text("N_Batch:")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                TextField("size..", text: $model_n_batch)
                                    .frame( alignment: .leading)
                                    .multilineTextAlignment(.trailing)
                            }
                            .padding(.horizontal)
                            
                            HStack {
                                Text("Temp:")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                TextField("size..", text: $model_temp)
                                    .frame( alignment: .leading)
                                    .multilineTextAlignment(.trailing)
                            }
                            .padding(.horizontal)
                            
                            HStack {
                                Text("Top_k:")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                TextField("size..", text: $model_top_k)
                                    .frame( alignment: .leading)
                                    .multilineTextAlignment(.trailing)
                            }
                            .padding(.horizontal)
                            
                            HStack {
                                Text("Top_p:")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                TextField("size..", text: $model_top_p)
                                    .frame( alignment: .leading)
                                    .multilineTextAlignment(.trailing)
                            }
                            .padding(.horizontal)
                            
                            HStack {
                                Text("Icon:")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                TextField("size..", text: $model_icon)
                                    .frame( alignment: .leading)
                                    .multilineTextAlignment(.trailing)
                            }
                            .padding()
                        }
                    }
                }
            }
            .padding(.top)
            .padding(.horizontal)
        }
    }
}

struct AddChatView_Previews: PreviewProvider {
    static var previews: some View {
        AddChatView(add_chat_dialog: .constant(true),edit_chat_dialog:.constant(false))
            .preferredColorScheme(.dark)
    }
}
