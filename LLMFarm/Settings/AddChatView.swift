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
    @State private var prompt_format: String = "{{prompt}}"
    @State private var warm_prompt: String = "\n\n\n"
    @State private var reverse_prompt:String = ""
    @State private var numberOfThreads: Int32 = 0
    @State private var mirostat: Int32 = 0
    @State private var mirostat_tau: Float = 5.0
    @State private var mirostat_eta: Float = 0.1
    @State private var use_metal: Bool = false
    @State private var isImporting: Bool = false
    @Binding var renew_chat_list: () -> Void
    
    private var chat_name: String = ""
    let bin_type = UTType(tag: "bin", tagClass: .filenameExtension, conformingTo: nil)
    
    @State private var model_settings_template:ModelSettingsTemplate = ModelSettingsTemplate()
    let model_setting_templates = get_model_setting_templates()
    
    @State private var model_inference = "llama"
    let model_inferences = ["gptneox", "llama", "gpt2", "replit", "starcoder", "rwkv"]
    
    @State private var model_sampling = "temperature"
    let model_samplings = ["temperature", "greedy", "mirostat", "mirostat_v2"]
    
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
        if (chat_config!["warm_prompt"] != nil){
            self._warm_prompt = State(initialValue: chat_config!["warm_prompt"]! as! String)
        }
        if (chat_config!["reverse_prompt"] != nil){
            self._reverse_prompt = State(initialValue: chat_config!["reverse_prompt"]! as! String)
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
            if (chat_config!["temp"]! as! Float) <= 0{
                self._model_sampling = State(initialValue: "greedy")
            }
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
        if (chat_config!["mirostat"] != nil){
            self._mirostat = State(initialValue: chat_config!["mirostat"] as! Int32)
            if (chat_config!["mirostat"] as! Int32) == 1{
                self._model_sampling = State(initialValue: "mirostat")
            }
            if (chat_config!["mirostat"] as! Int32) == 2{
                self._model_sampling = State(initialValue: "mirostat_v2")
            }
        }
        if (chat_config!["mirostat_tau"] != nil){
            self._mirostat_tau = State(initialValue: chat_config!["mirostat_tau"] as! Float)
        }
        if (chat_config!["mirostat_eta"] != nil){
            self._mirostat_eta = State(initialValue: chat_config!["mirostat_eta"] as! Float)
        }
    }
    
    func apply_setting_template(template:ModelSettingsTemplate){
        model_inference = template.inference
        prompt_format = template.prompt_format
        model_context = template.context
        model_n_batch = template.n_batch
        model_temp = template.temp
        model_top_k = template.top_k
        model_top_p = template.top_p
        model_repeat_penalty = template.repeat_penalty
        model_repeat_last_n = template.repeat_last_n
        warm_prompt = template.warm_prompt
        reverse_prompt = template.reverse_prompt
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
                                                                   "icon":model_icon,
                                                                   "model_inference":model_inference,
                                                                   "use_metal":use_metal,
                                                                   "prompt_format":prompt_format,
                                                                   "warm_prompt":warm_prompt,
                                                                   "reverse_prompt":reverse_prompt,
                                                                   "numberOfThreads":Int32(numberOfThreads),
                                                                   "context":Int32(model_context),
                                                                   "n_batch":Int32(model_n_batch),
                                                                   "temp":Float(model_temp),
                                                                   "repeat_last_n":Int32(model_repeat_last_n),
                                                                   "repeat_penalty":Float(model_repeat_penalty),
                                                                   "top_k":Int32(model_top_k),
                                                                   "top_p":Float(model_top_p),
                                                                   "mirostat":mirostat,
                                                                   "mirostat_eta":mirostat_eta,
                                                                   "mirostat_tau":mirostat_tau
                                                                   ]
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
                        HStack{
                            Text("Icon:")
                                .frame(maxWidth: .infinity, alignment: .leading)
                            VStack {
                                Picker("", selection: $model_icon) {
                                    ForEach(model_icons, id: \.self) {
                                        Text($0)
                                    }
                                }
                                .pickerStyle(.menu)
                            }
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        }.padding()
                        Divider()
                            .padding(.top, 8)
                        
                        HStack{
                            Text("Settings template:")
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Picker("", selection: $model_settings_template) {
                                ForEach(model_setting_templates, id: \.self) { template in
                                    Text(template.template_name).tag(template)
                                }
                            }
                            .onChange(of: model_settings_template) { tmpl in
                                apply_setting_template(template:model_settings_template)
                            }
                            .pickerStyle(.menu)
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        
                        HStack{
                            Text("Inference:")
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Picker("", selection: $model_inference) {
                                ForEach(model_inferences, id: \.self) {
                                    Text($0)
                                }
                            }
                            .pickerStyle(.menu)
                            //
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        
                        HStack {
                            Toggle("Use Metal", isOn: $use_metal)
                        }
                        .disabled(self.model_inference != "llama")
                        .padding()
                        
                        Group {
//                            VStack {
//                                Text("Warm prompt:")
//                                    .frame(maxWidth: .infinity, alignment: .leading)
//                                TextField("prompt..", text: $warm_prompt, axis: .vertical)
//                                    .lineLimit(2)
//                                
//                                    .textFieldStyle(.roundedBorder)
//                                    .frame( alignment: .leading)
//                                //                                .multilineTextAlignment(.trailing)
//                                //                                .textFieldStyle(.plain)
//                            }
//                            .padding(.horizontal)
                            
                            VStack {
                                Text("Prompt format:")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                TextField("prompt..", text: $prompt_format, axis: .vertical)
                                    .lineLimit(2)
                                
                                    .textFieldStyle(.roundedBorder)
                                    .frame( alignment: .leading)
                                //                                .multilineTextAlignment(.trailing)
                                //                                .textFieldStyle(.plain)
                            }
                            .padding(.top, 8)
                            .padding(.horizontal)
                            
                            VStack {
                                Text("Reverse prompt:")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                TextField("prompt..", text: $reverse_prompt, axis: .vertical)
                                    .lineLimit(2)
                                
                                    .textFieldStyle(.roundedBorder)
                                    .frame( alignment: .leading)
                                //                                .multilineTextAlignment(.trailing)
                                //                                .textFieldStyle(.plain)
                            }
                            .padding(.top, 8)
                            .padding(.horizontal)
                            
                            Divider()
                                .padding(.top, 8)
                        }
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
                            
                            HStack{
                                Text("Sampling:")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Picker("", selection: $model_sampling) {
                                    ForEach(model_samplings, id: \.self) {
                                        Text($0)
                                    }
                                }
                                .pickerStyle(.menu)
                                .onChange(of: model_sampling) { sampling in
                                    if sampling == "temperature" {
                                        mirostat = 0
                                    }
                                    if sampling == "greedy" {
                                        mirostat = 0
                                        model_temp = 0
                                    }
                                    if sampling == "mirostat" {
                                        mirostat = 1
                                    }
                                    if sampling == "mirostat_v2" {
                                        mirostat = 2
                                    }
                                }
                                //
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                        }
                        Group {
                            if model_sampling == "temperature" {
                                Group {
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
                                        Text("Repeat last N:")
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
                                    
                                    
                                }
                            }
                            
                            if model_sampling == "mirostat" || model_sampling == "mirostat_v2" {
                                Group {
                                    HStack {
                                        Text("Mirostat_eta:")
                                            .frame(maxWidth: 84, alignment: .leading)
                                        TextField("val..", value: $mirostat_eta, format:.number)
                                            .frame( alignment: .leading)
                                            .multilineTextAlignment(.trailing)
                                            .textFieldStyle(.plain)
#if os(iOS)
                                            .keyboardType(.numbersAndPunctuation)
#endif
                                    }
                                    .padding(.horizontal)
                                    
                                    HStack {
                                        Text("Mirostat_tau:")
                                            .frame(maxWidth: 85, alignment: .leading)
                                        TextField("val..", value: $mirostat_tau, format:.number)
                                            .frame( alignment: .leading)
                                            .multilineTextAlignment(.trailing)
                                            .textFieldStyle(.plain)
#if os(iOS)
                                            .keyboardType(.numbersAndPunctuation)
#endif
                                    }
                                    .padding(.horizontal)
                                }
                            }
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
//        AddChatView(add_chat_dialog: .constant(true),edit_chat_dialog:.constant(false),renew_chat_list: .constant({}))
//            .preferredColorScheme(.dark)
//    }
//}
