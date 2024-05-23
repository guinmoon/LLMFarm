//
//  ChatListView.swift
//  ChatUI
//
//  Created by Shezad Ahamed on 05/08/21.
//

import SwiftUI
import llmfarm_core_cpp
import UniformTypeIdentifiers





struct AddChatView: View {
    
    @Binding var add_chat_dialog: Bool
    @Binding var edit_chat_dialog: Bool
    @Binding var toggleSettings: Bool
    @EnvironmentObject var aiChatModel: AIChatModel
    
    //    @State private var chat_config: Dictionary<String, AnyObject> = [:]
    
    //    @State private var model_file: InputDoument = InputDoument(input: "")
    @State private var isBasicAccordionExpanded: Bool = true
    @State private var isModelAccordionExpanded: Bool = true
    @State private var isPredictionAccordionExpanded: Bool = false
    @State private var isSamplingAccordionExpanded: Bool = false
    @State private var isPromptAccordionExpanded: Bool = false
    @State private var isAdditionalAccordionExpanded: Bool = false
    
    @State private var model_file_url: URL = URL(filePath: "/")
    @State private var model_file_path: String = "Select model"
    @State private var model_title: String = ""
    
    @State private var clip_model_file_url: URL = URL(filePath: "/")
    @State private var clip_model_file_path: String = "Select Clip model"
    @State private var clip_model_title: String = ""
    
    @State private var lora_file_url: URL = URL(filePath: "/")
    @State private var lora_file_path: String = "Add LoRA adapter"
    @State private var lora_title: String = ""
    @State private var lora_file_scale: Float = 1.0
    
    @State private var model_context: Int32 = 1024
    @State private var model_n_batch: Int32 = 512
    @State private var model_temp: Float = 0.9
    @State private var model_top_k: Int32 = 40
    @State private var model_top_p: Float = 0.95
    @State private var model_repeat_last_n: Int32 = 64
    @State private var model_repeat_penalty: Float = 1.1
    @State private var prompt_format: String = "{{prompt}}"
    @State private var warm_prompt: String = "\n\n\n"
    @State private var skip_tokens: String = ""
    @State private var reverse_prompt:String = ""
    @State private var numberOfThreads: Int32 = 0
    @State private var mirostat: Int32 = 0
    @State private var mirostat_tau: Float = 5.0
    @State private var mirostat_eta: Float = 0.1
    @State private var use_metal: Bool = false
    @State private var mlock: Bool = false
    @State private var mmap: Bool = true
    @State private var flash_attn: Bool = false
    
    @State private var isLoraImporting: Bool = false
    @State private var tfs_z: Float = 1.0
    @State private var typical_p: Float = 1.0
    @State private var grammar: String = "<None>"
    @State private var add_bos_token: Bool = true
    @State private var add_eos_token: Bool = false
    @State private var parse_special_tokens: Bool = true
    
    @State private var has_lora: Bool = false
    @State private var has_clip: Bool = false
    
    @State private var save_load_state: Bool = true
    
    
    @State private var lora_adapters: [Dictionary<String, Any>] = []
    
    var hardware_arch = Get_Machine_Hardware_Name()
    @Binding var after_chat_edit: () -> Void
    
    private var chat_name: String = ""
    let bin_type = UTType(tag: "bin", tagClass: .filenameExtension, conformingTo: nil)
    let gguf_type = UTType(tag: "gguf", tagClass: .filenameExtension, conformingTo: nil)
    
    @State private var model_settings_template:ChatSettingsTemplate = ChatSettingsTemplate()
    @State var model_setting_templates = get_model_setting_templates()
    @State var save_as_template_name:String = "My Template"
    
    @State private var model_inference = "llama"
    @State private var ggjt_v3_inference = "gpt2"
    @State private var model_inference_inner = "llama"
    
    let model_inferences = ["llama","rwkv","ggjt_v3"]
    let ggjt_v3_inferences = ["gptneox", "gpt2", "replit", "starcoder"]
    
    @State private var model_sampling = "temperature"
    let model_samplings = ["temperature", "greedy", "mirostat", "mirostat_v2"]
    
    @State private var model_icon: String = "ava0"
    let model_icons = ["ava0","ava1","ava2","ava3","ava4","ava5","ava6","ava7"]
    
    @State var models_previews = get_models_list(exts:[".gguf",".bin"])!
    
    @State var loras_previews = get_models_list(dir: "lora_adapters",exts:[".bin"])!
    
    @State var grammars_previews = get_grammars_list()!
    
    @State private var clearChatAlert = false
    
    @State private var model_not_selected_alert = false
    
    
    func refresh_templates(){
        model_setting_templates = get_model_setting_templates()
    }
    
    init(add_chat_dialog: Binding<Bool>,edit_chat_dialog:Binding<Bool>,
         after_chat_edit: Binding<() -> Void>,toggleSettings: Binding<Bool>) {
        self._add_chat_dialog = add_chat_dialog
        self._edit_chat_dialog = edit_chat_dialog
        self._after_chat_edit = after_chat_edit
        self._toggleSettings = toggleSettings
    }
    
    init(add_chat_dialog: Binding<Bool>,edit_chat_dialog:Binding<Bool>,
         chat_name:String,after_chat_edit: Binding<() -> Void>,toggleSettings: Binding<Bool>) {
        self._add_chat_dialog = add_chat_dialog
        self._edit_chat_dialog = edit_chat_dialog
        self._after_chat_edit = after_chat_edit
        self._toggleSettings = toggleSettings
        self.chat_name = chat_name
        let chat_config = get_chat_info(chat_name)
        if chat_config == nil{ //in Swift runtime failure: Unexpectedly found nil while unwrapping an Optional value ()
            return
        }
        
        //        self._chat_config = State(initialValue: chat_config!)
        
        if (chat_config!["title"] != nil){
            self._model_title = State(initialValue: chat_config!["title"]! as! String)
        }
        if (chat_config!["model"] != nil){
            self._model_file_path = State(initialValue: chat_config!["model"]! as! String)
        }
        if (chat_config!["clip_model"] != nil){
            self._clip_model_file_path = State(initialValue: chat_config!["clip_model"]! as! String)
            if let path = get_path_by_short_name(chat_config!["clip_model"]! as! String){
                self._has_clip = State(initialValue: true)
            }
        }
        if chat_config!["lora_adapters"] != nil{
            let adapters = chat_config!["lora_adapters"]! as?  [Dictionary<String, Any>]
            if adapters != nil && adapters!.count>0{
                self._lora_file_path = State(initialValue: adapters![0]["adapter"]! as! String)
                self._lora_file_scale = State(initialValue: adapters![0]["scale"]! as! Float)
                if let path = get_path_by_short_name(adapters![0]["adapter"]! as! String,dest:"lora_adapters"){
                    self._has_lora = State(initialValue: true)
                }
            }            
        }
        if chat_config!["icon"] != nil{
            self._model_icon = State(initialValue: chat_config!["icon"]! as! String)
        }
        if chat_config!["model_settings_template"] != nil{
            let cur_template = chat_config?["model_settings_template"] as? String ?? ""
//            let isPresent = model_setting_templates.contains(where: { $0.template_name == cur_template })
            model_setting_templates.forEach { template in
                if template.template_name == cur_template{
                    self._model_settings_template = State(initialValue:template)
                }
            }
        }        
        if (chat_config!["model_inference"] != nil){
            self._model_inference = State(initialValue: chat_config!["model_inference"]! as! String)
        }
        if (chat_config!["use_metal"] != nil){
            self._use_metal = State(initialValue: chat_config!["use_metal"]! as! Bool)
        }
        if (chat_config!["mlock"] != nil){
            self._mlock = State(initialValue: chat_config!["mlock"]! as! Bool)
        }
        if (chat_config!["mmap"] != nil){
            self._mmap = State(initialValue: chat_config!["mmap"]! as! Bool)
        }
        if (chat_config!["flash_attn"] != nil){
            self._flash_attn = State(initialValue: chat_config!["flash_attn"]! as! Bool)
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
        if (chat_config!["skip_tokens"] != nil){
            self._skip_tokens = State(initialValue: chat_config!["skip_tokens"]! as! String)
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
        if (chat_config!["tfs_z"] != nil){
            self._tfs_z = State(initialValue: chat_config!["tfs_z"] as! Float)
        }
        if (chat_config!["typical_p"] != nil){
            self._typical_p = State(initialValue: chat_config!["typical_p"] as! Float)
        }
        if (chat_config!["grammar"] != nil){
            self._grammar = State(initialValue: chat_config!["grammar"]! as! String)
        }
        if (chat_config!["add_bos_token"] != nil){
            self._add_bos_token = State(initialValue: chat_config!["add_bos_token"] as! Bool)
        }
        if (chat_config!["add_eos_token"] != nil){
            self._add_eos_token = State(initialValue: chat_config!["add_eos_token"] as! Bool)
        }
        if (chat_config!["parse_special_tokens"] != nil){
            self._parse_special_tokens = State(initialValue: chat_config!["parse_special_tokens"] as! Bool)
        }
        if (chat_config!["save_load_state"] != nil){
            self._save_load_state = State(initialValue: chat_config!["save_load_state"] as! Bool)
        }
    }
    
    @State var applying_template:Bool = false
    
    func set_template_to_custom(){
        model_settings_template = model_setting_templates[0]
    }
    
    
    
    func apply_setting_template(template:ChatSettingsTemplate){
        if template.template_name == "Custom"{
            return
        }
        model_inference = template.inference
        prompt_format = template.prompt_format
        model_context = template.context
        model_n_batch = template.n_batch
        model_temp = template.temp
        model_top_k = template.top_k
        model_top_p = template.top_p
        model_repeat_penalty = template.repeat_penalty
        model_repeat_last_n = template.repeat_last_n
        //        warm_prompt = template.warm_prompt
        reverse_prompt = template.reverse_prompt
        use_metal = template.use_metal
        mirostat = template.mirostat
        mirostat_tau = template.mirostat_tau
        mirostat_eta = template.mirostat_eta
        grammar = template.grammar
        numberOfThreads = template.numberOfThreads
        add_bos_token = template.add_bos_token
        add_eos_token = template.add_eos_token
        parse_special_tokens = template.parse_special_tokens
        mmap = template.mmap
        mlock = template.mlock
        tfs_z = template.tfs_z
        typical_p = template.typical_p
        flash_attn = template.flash_attn
        skip_tokens = template.skip_tokens
        if hardware_arch=="x86_64"{
            use_metal = false
        }
        run_after_delay(delay:1200, function:{applying_template = false})
    }
    
    
    func get_chat_options_dict(is_template:Bool = false) -> Dictionary<String, Any> {
        var options:Dictionary<String, Any> =    ["model":model_file_path,
                                                  "model_settings_template":model_settings_template.template_name,
                                                  "clip_model":clip_model_file_path,
                                                  "lora_adapters":lora_adapters,
                                                  "title":model_title,
                                                  "icon":model_icon,
                                                  "model_inference":model_inference_inner,
                                                  "use_metal":use_metal,
                                                  "mlock":mlock,
                                                  "mmap":mmap,
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
                                                  "mirostat_tau":mirostat_tau,
                                                  "tfs_z":tfs_z,
                                                  "typical_p":typical_p,
                                                  "grammar":grammar,
                                                  "add_bos_token":add_bos_token,
                                                  "add_eos_token":add_eos_token,
                                                  "parse_special_tokens":parse_special_tokens,
                                                  "flash_attn":flash_attn,
                                                  "save_load_state":save_load_state,
                                                  "skip_tokens":skip_tokens
        ]
        if is_template{
            options["template_name"] = save_as_template_name
        }
        return options
    }
    
    
    
    var body: some View {
        ZStack{
            //            Color("color_bg").edgesIgnoringSafeArea(.all)
            VStack{
                
                HStack{
                    Button {
                        Task {
                            add_chat_dialog = false
                            //                            edit_chat_dialog = false
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
                            if model_file_path == "Select model"{
                                model_not_selected_alert = true
                                return
                            }
                            //                            if !edit_chat_dialog {
                            if model_file_url.path != "/"{
                                print(model_file_url.path)
                                let sandbox_path = copyModelToSandbox(url: model_file_url,dest: "models")
                                if sandbox_path != nil{
                                    model_file_path = sandbox_path!
                                }
                            }
                            if lora_file_url.path != "/"{
                                print(lora_file_url.path)
                                let sandbox_path = copyModelToSandbox(url: lora_file_url,dest: "lora_adapters")
                                if sandbox_path != nil{
                                    lora_file_path = sandbox_path!
                                }
                            }
                            if clip_model_file_url.path != "/"{
                                print(clip_model_file_url.path)
                                let sandbox_path = copyModelToSandbox(url: clip_model_file_url,dest: "models")
                                if sandbox_path != nil{
                                    clip_model_file_path = sandbox_path!
                                }
                            }
                            //#if os(macOS)
                            
                            //#endif
                            //                            }
                            lora_adapters.append(["adapter":lora_file_path,"scale":lora_file_scale])
                            let options = get_chat_options_dict()
                            _ = create_chat(options,edit_chat_dialog:self.edit_chat_dialog,chat_name:self.chat_name)
                            if add_chat_dialog {
                                add_chat_dialog = false
                                
                            }
                            if edit_chat_dialog {
                                edit_chat_dialog = false
                            }
                            after_chat_edit()
                        }
                    } label: {
                        Text(edit_chat_dialog ? "Save" :"Add" )
                    }
                    .alert("To create a  chat, first select a model.", isPresented: $model_not_selected_alert) {
                                Button("OK", role: .cancel) { }
                    }
                    .disabled(model_title=="")
                }
                
                ScrollView(showsIndicators: false){
                    
                    DisclosureGroup("Basic:", isExpanded: $isBasicAccordionExpanded) {
                        HStack{
                            
                            Picker("", selection: $model_icon) {
//                                LazyVGrid(columns: [GridItem(.flexible(minimum: 20, maximum: 50)),GridItem(.flexible(minimum: 20, maximum: 50))], spacing: 5) {
                                    ForEach(model_icons, id: \.self) { img in
                                        Image(img+"_48")
                                            .resizable()
                                            .background( Color("color_bg_inverted").opacity(0.05))
                                            .padding(EdgeInsets(top: 7, leading: 5, bottom: 7, trailing: 5))
                                            .frame(width: 48, height: 48)
                                            .clipShape(Circle())
                                    }
//                                }
                            }
                            .pickerStyle(.menu)
                            
                            .frame(maxWidth: 80, alignment: .leading)
                            .frame(height: 48)
                            
#if os(macOS)
                            DidEndEditingTextField(text: $model_title,didEndEditing: { newName in})
                                .frame(maxWidth: .infinity, alignment: .leading)
                            //                            .padding([.trailing, .leading, .top])
#else
                            TextField("Title...", text: $model_title)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .textFieldStyle(.plain)
                            //                            .padding([.trailing, .leading, .top])
#endif
                            
                            
                            
                            //                            Text("Icon:")
                            //                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                        }
                        .padding([.top ])
                        
                        HStack{
                            Text("Settings template:")
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Picker("", selection: $model_settings_template) {
                                ForEach(model_setting_templates, id: \.self) { template in
                                    Text(template.template_name).tag(template)
                                }
                            }
                            .onChange(of: model_settings_template) { tmpl in
                                applying_template = true
                                apply_setting_template(template:model_settings_template)
                            }
                            .pickerStyle(.menu)
                        }
                        .padding(.horizontal, 5)
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
                        .padding(.horizontal, 5)
                        .padding(.top, 8)
                        .onChange(of: model_inference){ inf in
                            if model_inference != "ggjt_v3"{
                                model_inference_inner = model_inference
                            }else{
                                model_inference_inner = ggjt_v3_inference
                            }
                        }
                        
                        
                        if model_inference == "ggjt_v3"{
                            HStack{
                                Text("Inference ggjt_v3:")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Picker("", selection: $ggjt_v3_inference) {
                                    ForEach(ggjt_v3_inferences, id: \.self) {
                                        Text($0)
                                    }
                                }
                                .pickerStyle(.menu)
                                //
                            }
                            .padding(.horizontal, 5)
                            .padding(.top, 8)
                            .onChange(of: ggjt_v3_inference){ inf in
                                model_inference_inner = ggjt_v3_inference
                            }
                        }
                    }.padding([.top ])
                    
                    DisclosureGroup("Model:", isExpanded: $isModelAccordionExpanded) {
                        VStack(alignment: .leading, spacing: 5){
                            
                            ModelSelector(  models_previews:$models_previews,
                                            model_file_path:$model_file_path,
                                            model_file_url:$model_file_url,
                                            model_title:$model_title,
                                            toggleSettings:$toggleSettings,
                                            edit_chat_dialog:$edit_chat_dialog,
                                            import_lable:"Import from file...",
                                            download_lable:"Download models...",
                                            selection_lable:"Select Model...",
                                            avalible_lable:"Avalible models")
                            .padding([/*.trailing, .leading,*/ .top])
                            .padding(.horizontal, 5)
#if os(iOS)
                            .padding(.bottom)
#endif
                            if has_clip {
                                ModelSelector(  models_previews:$models_previews,
                                                model_file_path:$clip_model_file_path,
                                                model_file_url:$clip_model_file_url,
                                                model_title:$clip_model_title,
                                                toggleSettings:$toggleSettings,
                                                edit_chat_dialog:$edit_chat_dialog,
                                                import_lable:"Import from file...",
                                                download_lable:"Download models...",
                                                selection_lable:"Select Clip Model...",
                                                avalible_lable:"Avalible models")
                                .padding([/*.trailing, .leading,*/ .top])
                                .padding(.horizontal, 5)
#if os(iOS)
                                .padding(.bottom)
#endif
                            }
                            if has_lora {
                                HStack {
                                    ModelSelector(  models_previews:$loras_previews,
                                                    model_file_path:$lora_file_path,
                                                    model_file_url:$lora_file_url,
                                                    model_title:$lora_title,
                                                    toggleSettings:$toggleSettings,
                                                    edit_chat_dialog:$edit_chat_dialog,
                                                    import_lable:"Import from file...",
                                                    download_lable:"Download models...",
                                                    selection_lable:"Select Adapter...",
                                                    avalible_lable:"Avalible adapters")
                                    .padding([/*.trailing, .leading,*/ .top])
                                    .padding(.leading, 5)
#if os(iOS)
                                    .padding(.bottom)
#endif
                                    Spacer()
                                    
                                    TextField("Scale..", value: $lora_file_scale, format:.number)
                                        .frame( maxWidth: 50, alignment: .leading)
                                        .multilineTextAlignment(.trailing)
                                        .textFieldStyle(.plain)
                                        .padding(.trailing, 5)
                                        .padding(.top)
#if os(iOS)
                                        .keyboardType(.numbersAndPunctuation)
#endif
                                }
                            }
                            HStack {
                                Toggle("Clip", isOn: $has_clip)
                                    .frame(maxWidth: 120, alignment: .trailing)
                                Toggle("LoRa", isOn: $has_lora)
                                    .frame(maxWidth: 120, alignment: .trailing)
                                Spacer()
                            }
                            .padding([/*.trailing, .leading,*/ .top])
                            .padding(.horizontal, 5)
#if os(iOS)
                            .padding([.bottom])
#endif
                        }
                    }.padding([.top ])

                    DisclosureGroup("Prompt format:", isExpanded: $isPromptAccordionExpanded) {
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
                                Text("Format:")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                TextEditor(text: $prompt_format)
                                    .frame(minHeight: 30)
                                //                                TextField("prompt..", text: $prompt_format, axis: .vertical)
                                //                                    .lineLimit(2)
                                //                                    .textFieldStyle(.roundedBorder)
                                //                                    .frame( alignment: .leading)
                                //                                .multilineTextAlignment(.trailing)
                                //                                .textFieldStyle(.plain)
                            }
                            .padding(.top, 8)
                            .padding(.horizontal, 5)
                            
                            VStack {
                                Text("Reverse prompts:")
                                    .frame(maxWidth: .infinity, alignment: .leading)
#if os(macOS)
                                DidEndEditingTextField(text: $reverse_prompt, didEndEditing: { newName in})
                                    .frame( alignment: .leading)
#else
                                TextField("prompt..", text: $reverse_prompt, axis: .vertical)
                                    .lineLimit(2)
                                    .textFieldStyle(.roundedBorder)
                                    .frame( alignment: .leading)
#endif
                                //                                .multilineTextAlignment(.trailing)
                                //                                .textFieldStyle(.plain)
                            }
                            .padding(.top, 8)
                            .padding(.horizontal, 5)

                            VStack {
                                Text("Skip tokens:")
                                    .frame(maxWidth: .infinity, alignment: .leading)
#if os(macOS)
                                DidEndEditingTextField(text: $skip_tokens, didEndEditing: { newName in})
                                    .frame( alignment: .leading)
#else
                                TextField("prompt..", text: $skip_tokens, axis: .vertical)
                                    .lineLimit(2)
                                    .textFieldStyle(.roundedBorder)
                                    .frame( alignment: .leading)
#endif
                                //                                .multilineTextAlignment(.trailing)
                                //                                .textFieldStyle(.plain)
                            }
                            .padding(.top, 8)
                            .padding(.horizontal, 5)
                            
                            HStack {
                                Toggle("Special", isOn: $parse_special_tokens)
                                    .frame(maxWidth: 120, alignment: .trailing)
                                    .disabled(self.model_inference != "llama" )
                                Spacer()
                            }
                            .padding(.horizontal, 5)
                            .padding(.bottom, 4)
                            
                            HStack {
                                Toggle("BOS", isOn: $add_bos_token)
                                    .frame(maxWidth: 120, alignment: .trailing)
                                Toggle("EOS", isOn: $add_eos_token)
                                    .frame(maxWidth: 120, alignment: .trailing)
                                Spacer()
                            }
                            .padding(.horizontal, 5)
                            .padding(.bottom, 4)
                            
                            Divider()
                                .padding(.top, 8)
                        }
                    }.padding([.top ])
                    
                    DisclosureGroup("Prediction options:", isExpanded: $isPredictionAccordionExpanded) {
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
                            .padding(.horizontal, 5)
                            .padding(.top)
                            
                            HStack {
                                Toggle("Metal", isOn: $use_metal)
                                    .frame(maxWidth: 120, alignment: .leading)
                                    .disabled((self.model_inference != "llama" && self.model_inference_inner != "gpt2" ) /*|| hardware_arch=="x86_64"*/)
//                                Toggle("FAttn", isOn: $flash_attn)
//                                    .frame(maxWidth: 120, alignment: .leading)
//                                    .disabled((self.model_inference != "llama" && self.model_inference_inner != "gpt2" ) /*|| hardware_arch=="x86_64"*/)
                                Spacer()
                            }
                            .padding(.horizontal, 5)
                            .padding(.bottom, 4)
                            
                            HStack {
                                Toggle("MLock", isOn: $mlock)
                                    .frame(maxWidth: 120,  alignment: .leading)
                                    .disabled(self.model_inference != "llama" && self.model_inference_inner != "gpt2" )
                                Toggle("MMap", isOn: $mmap)
                                    .frame(maxWidth: 120,  alignment: .leading)
                                    .disabled(self.model_inference != "llama" && self.model_inference_inner != "gpt2" )
                                Spacer()
                            }
                            .padding(.horizontal, 5)
                            .padding(.bottom, 4)
                            
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
                            .padding(.horizontal, 5)
                            
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
                            .padding(.horizontal, 5)
                        }
                    }.padding([.top ])
                    
                    DisclosureGroup("Sampling options:", isExpanded: $isSamplingAccordionExpanded) {
                        Group {
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
                            .padding(.horizontal, 5)
                            .padding(.top, 8)
                            
                            if model_sampling == "temperature" {
                                Group {
                                    
                                    HStack {
                                        Text("Repeat last N:")
                                            .frame(maxWidth: 100, alignment: .leading)
                                        TextField("count..", value: $model_repeat_last_n, format:.number)
                                            .frame( alignment: .leading)
                                            .multilineTextAlignment(.trailing)
                                            .textFieldStyle(.plain)
#if os(iOS)
                                            .keyboardType(.numberPad)
#endif
                                    }
                                    .padding(.horizontal, 5)
                                    
                                    HStack {
                                        Text("Repeat Penalty:")
                                            .frame(maxWidth: 100, alignment: .leading)
                                        TextField("size..", value: $model_repeat_penalty, format:.number)
                                            .frame( alignment: .leading)
                                            .multilineTextAlignment(.trailing)
                                            .textFieldStyle(.plain)
#if os(iOS)
                                            .keyboardType(.numbersAndPunctuation)
#endif
                                    }
                                    .padding(.horizontal, 5)
                                    
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
                                    .padding(.horizontal, 5)
                                    
                                    HStack {
                                        Text("Top_k:")
                                            .frame(maxWidth: 75, alignment: .leading)
                                        TextField("val..", value: $model_top_k, format:.number)
                                            .frame( alignment: .leading)
                                            .multilineTextAlignment(.trailing)
                                            .textFieldStyle(.plain)
#if os(iOS)
                                            .keyboardType(.numberPad)
#endif
                                    }
                                    .padding(.horizontal, 5)
                                    
                                    HStack {
                                        Text("Top_p:")
                                            .frame(maxWidth: 95, alignment: .leading)
                                        TextField("val..", value: $model_top_p, format:.number)
                                            .frame( alignment: .leading)
                                            .multilineTextAlignment(.trailing)
                                            .textFieldStyle(.plain)
#if os(iOS)
                                            .keyboardType(.numbersAndPunctuation)
#endif
                                    }
                                    .padding(.horizontal, 5)
                                    
                                    
                                    HStack {
                                        Text("Tail Free Z:")
                                            .frame(maxWidth: 100, alignment: .leading)
                                        TextField("val..", value: $tfs_z, format:.number)
                                            .frame( alignment: .leading)
                                            .multilineTextAlignment(.trailing)
                                            .textFieldStyle(.plain)
#if os(iOS)
                                            .keyboardType(.numbersAndPunctuation)
#endif
                                    }
                                    .padding(.horizontal, 5)
                                    
                                    HStack {
                                        Text("Locally Typical N:")
                                            .frame(maxWidth: 140, alignment: .leading)
                                        TextField("val..", value: $typical_p, format:.number)
                                            .frame( alignment: .leading)
                                            .multilineTextAlignment(.trailing)
                                            .textFieldStyle(.plain)
#if os(iOS)
                                            .keyboardType(.numbersAndPunctuation)
#endif
                                    }
                                    .padding(.horizontal, 5)
                                    
                                }
                                
                            }
                            
                            if model_sampling == "mirostat" || model_sampling == "mirostat_v2" {
                                Group {
                                    HStack {
                                        Text("Mirostat_eta:")
                                            .frame(maxWidth: 100, alignment: .leading)
                                        TextField("val..", value: $mirostat_eta, format:.number)
                                            .frame( alignment: .leading)
                                            .multilineTextAlignment(.trailing)
                                            .textFieldStyle(.plain)
#if os(iOS)
                                            .keyboardType(.numbersAndPunctuation)
#endif
                                    }
                                    .padding(.horizontal, 5)
                                    
                                    HStack {
                                        Text("Mirostat_tau:")
                                            .frame(maxWidth: 100, alignment: .leading)
                                        TextField("val..", value: $mirostat_tau, format:.number)
                                            .frame( alignment: .leading)
                                            .multilineTextAlignment(.trailing)
                                            .textFieldStyle(.plain)
#if os(iOS)
                                            .keyboardType(.numbersAndPunctuation)
#endif
                                    }
                                    .padding(.horizontal, 5)
                                    
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
                                    .padding(.horizontal, 5)
                                }
                            }
                            
                            if model_inference == "llama"{
                                HStack{
                                    Text("Grammar sampling:")
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    Picker("", selection: $grammar) {
                                        ForEach(grammars_previews, id: \.self) {
                                            Text($0)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    
                                }
                                .padding(.horizontal, 5)
//                                .padding(.top, 8)
                            }
                        }
                    }.padding([.top ])
                    
                    DisclosureGroup("Additional options:", isExpanded: $isAdditionalAccordionExpanded) {
                        VStack{
                            Text("Save as new template:")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 5)
                            HStack {
#if os(macOS)
                                DidEndEditingTextField(text: $save_as_template_name,didEndEditing: { newName in})
                                    .frame(maxWidth: .infinity, alignment: .leading)
#else
                                TextField("New template name...", text: $save_as_template_name)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .textFieldStyle(.plain)
#endif
                                Button {
                                    Task {
                                        let options = get_chat_options_dict(is_template: true)
                                        _ = create_chat(options,edit_chat_dialog:true,chat_name:save_as_template_name + ".json",save_as_template:true)
                                        refresh_templates()
                                    }
                                } label: {
                                    Image(systemName: "doc.badge.plus")
                                }
                                .frame(alignment: .trailing)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 5)
                        }
                        .padding(.top)
                        
                        HStack {
                            Toggle("Save/Load State", isOn: $save_load_state)
                                .frame(maxWidth: 120, alignment: .leading)
                            Spacer()
                        }
                        .padding(.horizontal, 5)
                        .padding(.bottom, 4)
                        
                    }.padding([.top ])

                }
            }
            .padding(.top)
            .padding(.horizontal)
        }
        .onChange(of: anyOfModelOptions){ new_val in
            if !applying_template {
                set_template_to_custom()
            }
        }
    }
    
    var anyOfModelOptions: [String] {[
        use_metal.description,
        model_inference,
        mlock.description,
        mmap.description,
        prompt_format,
        reverse_prompt,
        numberOfThreads.description,
        model_context.description,
        model_n_batch.description,
        model_temp.description,
        model_repeat_last_n.description,
        model_repeat_penalty.description,
        model_top_k.description,
        model_top_p.description,
        mirostat.description,
        mirostat_eta.description,
        mirostat_tau.description,
        tfs_z.description,
        typical_p.description,
        grammar,
        add_bos_token.description,
        add_eos_token.description,
        parse_special_tokens.description,
        flash_attn.description,
        skip_tokens
    ]}
}
//
//struct AddChatView_Previews: PreviewProvider {
//    static var previews: some View {
//        AddChatView(add_chat_dialog: .constant(true),edit_chat_dialog:.constant(false),renew_chat_list: .constant({}))
//            .preferredColorScheme(.dark)
//    }
//}
