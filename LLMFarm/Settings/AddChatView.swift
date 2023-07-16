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
    @State private var model_context: Int32 = 1024
    @State private var model_n_batch: Int32 = 512
    @State private var model_temp: Float = 0.9
    @State private var model_top_k: Int32 = 40
    @State private var model_top_p: Float = 0.95
    @State private var model_repeat_last_n: Int32 = 64
    @State private var model_repeat_penalty: Float = 1.1
    @State private var prompt_format: String = "auto"
    @State private var numberOfThreads: Int32 = 0
    @State private var use_metal: Bool = false
    @State private var isImporting: Bool = false
    @Binding var renew_chat_list: () -> Void
    
    private var chat_name: String = ""
    let bin_type = UTType(tag: "bin", tagClass: .filenameExtension, conformingTo: nil)
    
    @State private var model_inference = "auto"
    let model_inferences = ["auto","gptneox", "llama", "gpt2", "replit", "starcoder"]
    
    @State private var model_icon: String = "ava0"
    let model_icons = ["ava0","ava1","ava2","ava3","ava4","ava5","ava6","ava7"]
    
    init(add_chat_dialog: Binding<Bool>,edit_chat_dialog:Binding<Bool>,
         renew_chat_list: Binding<() -> Void>) {
        self._add_chat_dialog = add_chat_dialog
        self._edit_chat_dialog = edit_chat_dialog
        self._renew_chat_list = renew_chat_list
    }
    
    init(add_chat_dialog: Binding<Bool>,edit_chat_dialog:Binding<Bool>,
         chat_name:String,renew_chat_list: Binding<() -> Void>) {
        self._add_chat_dialog = add_chat_dialog
        self._edit_chat_dialog = edit_chat_dialog
        self._renew_chat_list = renew_chat_list
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
        if (chat_config!["use_metal"] != nil){
            self._use_metal = State(initialValue: chat_config!["use_metal"]! as! Bool)
        }
        if (chat_config!["prompt_format"] != nil){
            self._prompt_format = State(initialValue: chat_config!["prompt_format"]! as! String)
        }
        if (chat_config!["numberOfThreads"] != nil){
            self._numberOfThreads = State(initialValue: chat_config!["numberOfThreads"]! as! Int32)
        }
        if (chat_config!["context"] != nil){
            self._model_context = State(initialValue: chat_config!["context"]! as! Int32)
        }
        if (chat_config!["n_batch"] != nil){
            self._model_n_batch = State(initialValue: chat_config!["n_batch"]! as! Int32)
        }
        if (chat_config!["top_k"] != nil){
            self._model_top_k = State(initialValue: chat_config!["top_k"]! as! Int32)
        }
        if (chat_config!["temp"] != nil){
            self._model_temp = State(initialValue: chat_config!["temp"]! as! Float)
        }
        if (chat_config!["top_p"] != nil){
            self._model_top_p = State(initialValue: chat_config!["top_p"]! as! Float)
        }
        if (chat_config!["repeat_penalty"] != nil){
            self._model_repeat_penalty = State(initialValue: chat_config!["repeat_penalty"]! as! Float)
        }
        if (chat_config!["repeat_last_n"] != nil){
            self._model_repeat_last_n = State(initialValue: chat_config!["repeat_last_n"]! as! Int32)
        }
    }
    
    var body: some View {
        ZStack{
//            Color("color_bg").edgesIgnoringSafeArea(.all)
            VStack{
                
                HStack{
                    Button {
                        Task {
                            add_chat_dialog = false
                            edit_chat_dialog = false
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
                                                                   "repeat_last_n":Int32(model_repeat_last_n),
                                                                   "repeat_penalty":Float(model_repeat_penalty),
                                                                   "top_k":Int32(model_top_k),
                                                                   "top_p":Float(model_top_p),
                                                                   "model_inference":model_inference,
                                                                   "use_metal":use_metal,
                                                                   "prompt_format":prompt_format,
                                                                   "numberOfThreads":Int32(numberOfThreads),
                                                                   "icon":model_icon]
                            let res = create_chat(options,edit_chat_dialog:self.edit_chat_dialog,chat_name:self.chat_name)
                            if add_chat_dialog {
                                add_chat_dialog = false
                                
                            }
                            if edit_chat_dialog {
                                edit_chat_dialog = false
                            }
                            renew_chat_list()
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
                                .textFieldStyle(.plain)
                            
                        }
                        .padding()
                        
                        
                        if !edit_chat_dialog{
                            HStack {
                                //                            Text(model_file.input)
                                TextField("Model file...", text: $model_file_name)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .textFieldStyle(.plain)
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
                            VStack {
                                Picker("inference", selection: $model_inference) {
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
                            Toggle("Use Metal", isOn: $use_metal)
                        }
                        .disabled(self.model_inference != "llama")
                        .padding()
                        
                        VStack {
                            Text("Prompt format:")
                                .frame(maxWidth: .infinity, alignment: .leading)
                            TextField("size..", text: $prompt_format)
                                .frame( alignment: .leading)
                                .multilineTextAlignment(.trailing)
                                .textFieldStyle(.plain)
                        }
                        .padding()
                        
                        Divider()
                            .padding(.top, 8)
                        
                        Group {
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
                            .padding()
                            
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
                            .padding(.horizontal)
                            
                            HStack {
                                Text("N_Batch:")
                                    .frame(maxWidth: 75, alignment: .leading)
                                TextField("size..", value: $model_n_batch, format:.number)
                                    .frame( alignment: .leading)
                                    .multilineTextAlignment(.trailing)
                                    .textFieldStyle(.plain)
#if os(iOS)
                                    .keyboardType(.numberPad)
#endif
                            }
                            .padding(.horizontal)
                            
                            HStack {
                                Text("Temp:")
                                    .frame(maxWidth: 75, alignment: .leading)
                                TextField("size..", value: $model_temp, format:.number)
                                    .frame( alignment: .leading)
                                    .multilineTextAlignment(.trailing)
                                    .textFieldStyle(.plain)
#if os(iOS)
                                    .keyboardType(.numbersAndPunctuation)
#endif
                            }
                            .padding(.horizontal)
                            
                            HStack {
                                Text("Top_k:")
                                    .frame(maxWidth: 75, alignment: .leading)
                                TextField("size..", value: $model_top_k, format:.number)
                                    .frame( alignment: .leading)
                                    .multilineTextAlignment(.trailing)
                                    .textFieldStyle(.plain)
#if os(iOS)
                                    .keyboardType(.numberPad)
#endif
                            }
                            .padding(.horizontal)
                            
                            HStack {
                                Text("Top_p:")
                                    .frame(maxWidth: 75, alignment: .leading)
                                TextField("size..", value: $model_top_p, format:.number)
                                    .frame( alignment: .leading)
                                    .multilineTextAlignment(.trailing)
                                    .textFieldStyle(.plain)
#if os(iOS)
                                    .keyboardType(.numbersAndPunctuation)
#endif
                            }
                            .padding(.horizontal)
                            
                            HStack {
                                Text("Repean last N:")
                                    .frame(maxWidth: 75, alignment: .leading)
                                TextField("count..", value: $model_repeat_last_n, format:.number)
                                    .frame( alignment: .leading)
                                    .multilineTextAlignment(.trailing)
                                    .textFieldStyle(.plain)
#if os(iOS)
                                    .keyboardType(.numberPad)
#endif
                            }
                            .padding(.horizontal)
                            
                            HStack {
                                Text("Repeat Penalty:")
                                    .frame(maxWidth: 75, alignment: .leading)
                                TextField("size..", value: $model_repeat_penalty, format:.number)
                                    .frame( alignment: .leading)
                                    .multilineTextAlignment(.trailing)
                                    .textFieldStyle(.plain)
#if os(iOS)
                                    .keyboardType(.numbersAndPunctuation)
#endif
                            }
                            .padding(.horizontal)
                            
                            HStack{
                                VStack {
                                    Picker("icon", selection: $model_icon) {
                                        ForEach(model_icons, id: \.self) {
                                            Text($0)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                }
                                .frame(maxWidth: .infinity, alignment: .trailing)
                            }.padding()
                        }
                    }
                }
            }
            .padding(.top)
            .padding(.horizontal)
        }
        .navigationTitle($model_title)
    }
    
}
//
//struct AddChatView_Previews: PreviewProvider {
//    static var previews: some View {
//        AddChatView(add_chat_dialog: .constant(true),edit_chat_dialog:.constant(false))
//            .preferredColorScheme(.dark)
//    }
//}
