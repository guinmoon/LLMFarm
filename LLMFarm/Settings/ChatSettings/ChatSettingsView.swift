//
//  ChatSettingsView.swift
//  LLMFarm
//
//  Created by guinmoon on 18.10.2024.
//

import SwiftUI
import llmfarm_core_cpp
import UniformTypeIdentifiers
import SimilaritySearchKit
import SimilaritySearchKitDistilbert
import SimilaritySearchKitMiniLMAll
import SimilaritySearchKitMiniLMMultiQA


struct ChatSettingsView: View {
    
    @Binding var add_chat_dialog: Bool
    @Binding var edit_chat_dialog: Bool
    @Binding var toggleSettings: Bool
    
    @EnvironmentObject var aiChatModel: AIChatModel
    
    @State private var clearChatAlert = false
    @State private var model_not_selected_alert = false
    
    @State private var isBasicAccordionExpanded: Bool = true
    @State private var isModelAccordionExpanded: Bool = true
    @State private var isPredictionAccordionExpanded: Bool = false
    @State private var isSamplingAccordionExpanded: Bool = false
    @State private var isPromptAccordionExpanded: Bool = false
    @State private var isAdditionalAccordionExpanded: Bool = false
    
    @State private var chat_title: String = ""
    @State private var chat_icon: String = "ava0"
    @State private var chat_icons = ["ava0","ava1","ava2","ava3","ava4","ava5","ava6","ava7"]
    // @State private var model_inferences = ["llama","rwkv","ggjt_v3"]
    @State private var model_inferences = ["llama"]
    @State private var ggjt_v3_inferences = ["gptneox", "gpt2", "replit", "starcoder"]
    @State private var model_inference = "llama"
    @State private var ggjt_v3_inference = "gpt2"
    @State private var model_inference_inner = "llama"
    @State private var chat_settings_template:ChatSettingsTemplate = ChatSettingsTemplate()
    @State private var chat_setting_templates = get_model_setting_templates()
    @State private var applying_template:Bool = false
    
    @State private var model_file_url: URL = URL(filePath: "/")
    @State private var model_file_path: String = "Select model"
    // @State private var models_previews = get_models_list(exts:[".gguf",".bin"]) ?? []
    @State private var models_previews = getFileListByExts(exts:[".gguf"]) ?? []
    @State private var clip_model_file_url: URL = URL(filePath: "/")
    @State private var clip_model_file_path: String = "Select Clip model"
    @State private var clip_model_title: String = ""
    @State private var loras_previews = getFileListByExts(dir: "lora_adapters",exts:[".bin"]) ?? []
    //    @State private var loras_previews = []
    @State private var lora_adapters: [Dictionary<String, Any>] = []
    @State private var lora_file_url: URL = URL(filePath: "/")
    @State private var lora_file_path: String = "Add LoRA adapter"
    @State private var lora_title: String = ""
    @State private var lora_file_scale: Float = 1.0
    @State private var isLoraImporting: Bool = false
    @State private var has_lora: Bool = false
    @State private var has_clip: Bool = false
    
    @State private var model_context: Int32 = 1024
    @State private var model_n_batch: Int32 = 512
    @State private var n_predict: Int32 = 0
    @State private var numberOfThreads: Int32 = 0
    @State private var use_metal: Bool = true
    @State private var use_clip_metal: Bool = false
    @State private var mlock: Bool = false
    @State private var mmap: Bool = true
    @State private var flash_attn: Bool = false
    
    @State private var prompt_format: String = "{{prompt}}"
    @State private var warm_prompt: String = "\n\n\n"
    @State private var skip_tokens: String = ""
    @State private var reverse_prompt:String = ""
    @State private var add_bos_token: Bool = true
    @State private var add_eos_token: Bool = false
    @State private var parse_special_tokens: Bool = true
    
    @State private var model_temp: Float = 0.9
    @State private var model_top_k: Int32 = 40
    @State private var model_top_p: Float = 0.95
    @State private var model_repeat_last_n: Int32 = 64
    @State private var model_repeat_penalty: Float = 1.1
    @State private var mirostat: Int32 = 0
    @State private var mirostat_tau: Float = 5.0
    @State private var mirostat_eta: Float = 0.1
    @State private var tfs_z: Float = 1.0
    @State private var typical_p: Float = 1.0
    @State private var grammar: String = "<None>"
    @State private var model_sampling = "temperature"
    @State private var model_samplings = ["temperature", "greedy", "mirostat", "mirostat_v2"]
    @State private var grammars_previews = get_grammars_list() ?? []
    
    @State private var save_load_state: Bool = true
    @State private var save_as_template_name:String = "My Template"
    @State private var chat_style:String = "DocC"
    @State private var chat_styles = ["None", "DocC", "Basic", "GitHub"]
    
    // RAG
    @State private var ragTop: Int = 3
    @State private var chunkSize: Int = 256
    @State private var chunkOverlap: Int = 100
    @State private var currentModel: EmbeddingModelType = .minilmMultiQA
    @State private var comparisonAlgorithm: SimilarityMetricType = .dotproduct
    @State private var chunkMethod: TextSplitterType = .recursive

    var hardware_arch = Get_Machine_Hardware_Name()
    @Binding var after_chat_edit: () -> Void
    
    private var chat_name: String = ""
    let bin_type = UTType(tag: "bin", tagClass: .filenameExtension, conformingTo: nil)
    let gguf_type = UTType(tag: "gguf", tagClass: .filenameExtension, conformingTo: nil)
    
    func refresh_templates(){
        chat_setting_templates = get_model_setting_templates()
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
        let chat_config = getChatInfo(chat_name)
        if chat_config == nil{ //in Swift runtime failure: Unexpectedly found nil while unwrapping an Optional value ()
            return
        }
        
        //        self._chat_config = State(initialValue: chat_config!)
        
        if (chat_config!["title"] != nil){
            self._chat_title = State(initialValue: chat_config!["title"]! as! String)
        }
        if (chat_config!["model"] != nil){
            self._model_file_path = State(initialValue: chat_config!["model"]! as! String)
        }
        if (chat_config!["clip_model"] != nil){
            self._clip_model_file_path = State(initialValue: chat_config!["clip_model"]! as! String)
            if let _ = get_path_by_short_name(chat_config!["clip_model"]! as! String){
                self._has_clip = State(initialValue: true)
            }
        }
        if chat_config!["lora_adapters"] != nil{
            let adapters = chat_config!["lora_adapters"]! as?  [Dictionary<String, Any>]
            if adapters != nil && adapters!.count>0{
                self._lora_file_path = State(initialValue: adapters![0]["adapter"]! as! String)
                self._lora_file_scale = State(initialValue: adapters![0]["scale"]! as! Float)
                if let _ = get_path_by_short_name(adapters![0]["adapter"]! as! String,dest:"lora_adapters"){
                    self._has_lora = State(initialValue: true)
                }
            }
        }
        if chat_config!["icon"] != nil{
            self._chat_icon = State(initialValue: chat_config!["icon"]! as! String)
        }
        if chat_config!["model_settings_template"] != nil{
            let cur_template = chat_config?["model_settings_template"] as? String ?? ""
            //            let isPresent = model_setting_templates.contains(where: { $0.template_name == cur_template })
            chat_setting_templates.forEach { template in
                if template.template_name == cur_template{
                    self._chat_settings_template = State(initialValue:template)
                }
            }
        }
        if (chat_config!["model_inference"] != nil){
            self._model_inference = State(initialValue: chat_config!["model_inference"]! as! String)
        }
        if (chat_config!["use_metal"] != nil){
            self._use_metal = State(initialValue: chat_config!["use_metal"]! as! Bool)
        }
        if (chat_config!["use_clip_metal"] != nil){
            self._use_clip_metal = State(initialValue: chat_config!["use_clip_metal"]! as! Bool)
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
        if (chat_config!["n_predict"] != nil){
            self._n_predict = State(initialValue: chat_config!["n_predict"]! as! Int32)
        }
        if (chat_config!["top_k"] != nil){
            self._model_top_k = State(initialValue: chat_config!["top_k"]! as! Int32)
        }
        if (chat_config!["temp"] != nil){
            self._model_temp = State(initialValue: chat_config?["temp"] as? Float ?? 0)
            if (chat_config!["temp"] as? Float ?? 0) <= 0{
                self._model_sampling = State(initialValue: "greedy")
            }
        }
        if (chat_config!["top_p"] != nil){
            self._model_top_p = State(initialValue: chat_config!["top_p"]! as! Float)
        }
        if (chat_config!["repeat_penalty"] != nil){
            self._model_repeat_penalty = State(initialValue: chat_config!["repeat_penalty"] as? Float ?? 0)
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
        if (chat_config!["chat_style"] != nil){
            self._chat_style = State(initialValue: chat_config!["chat_style"] as! String)
        }

        // RAG
        self._chunkSize = State(initialValue: chat_config?["chunk_size"] as? Int ?? self.chunkSize)
        self._chunkOverlap = State(initialValue: chat_config?["chunk_overlap"] as? Int ?? self.chunkOverlap)
        self._ragTop = State(initialValue: chat_config?["rag_top"] as? Int ?? self.ragTop)
        
        if (chat_config!["current_model"] != nil){
            self._currentModel = State(initialValue: getCurrentModelFromStr(chat_config?["current_model"] as? String ?? ""))
        }
        if (chat_config!["comparison_algorithm"] != nil){ 
            self._comparisonAlgorithm = State(initialValue: getComparisonAlgorithmFromStr(chat_config?["comparison_algorithm"] as? String ?? ""))
        }
        if (chat_config!["chunk_method"] != nil){ 
            self._chunkMethod = State(initialValue: getChunkMethodFromStr(chat_config?["chunk_method"] as? String ?? ""))
        }
        
    }
    
    
    func set_template_to_custom(){
        chat_settings_template = chat_setting_templates[0]
    }
    
    func select_template(_ name:String){
        chat_setting_templates.forEach { template in
            if template.template_name == name{
                chat_settings_template = template
                return
            }
        }
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
        use_clip_metal = template.use_clip_metal
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
        var options:Dictionary<String, Any> = [  
            "model":model_file_path,
            "model_settings_template":chat_settings_template.template_name,
            "clip_model":clip_model_file_path,
            "lora_adapters":lora_adapters,
            "title":chat_title,
            "icon":chat_icon,
            "model_inference":model_inference_inner,
            "use_metal":use_metal,
            "use_clip_metal":use_clip_metal,
            "mlock":mlock,
            "mmap":mmap,
            "prompt_format":prompt_format,
            "warm_prompt":warm_prompt,
            "reverse_prompt":reverse_prompt,
            "numberOfThreads":Int32(numberOfThreads),
            "context":Int32(model_context),
            "n_batch":Int32(model_n_batch),
            "n_predict":Int32(n_predict),
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
            "skip_tokens":skip_tokens,
            "chat_style":chat_style,
            "chunk_size": chunkSize,
            "chunk_overlap": chunkOverlap,
            "rag_top": ragTop,
            "current_model": String(describing:currentModel),
            "comparison_algorithm": String(describing:comparisonAlgorithm),
            "chunk_method": String(describing:chunkMethod)
        ]
        if is_template{
            options["template_name"] = save_as_template_name
        }
        return options
    }
    
    func save_chat_settings(){
        if model_file_path == "Select model"{
            model_not_selected_alert = true
            return
        }
        //                            if !edit_chat_dialog {
        if model_file_url.path != "/"{
            print(model_file_url.path)
            let sandbox_path = CopyFileToSandbox(url: model_file_url,dest: "models")
            if sandbox_path != nil{
                model_file_path = sandbox_path!
            }
        }
        if lora_file_url.path != "/"{
            print(lora_file_url.path)
            let sandbox_path = CopyFileToSandbox(url: lora_file_url,dest: "lora_adapters")
            if sandbox_path != nil{
                lora_file_path = sandbox_path!
            }
        }
        if clip_model_file_url.path != "/"{
            print(clip_model_file_url.path)
            let sandbox_path = CopyFileToSandbox(url: clip_model_file_url,dest: "models")
            if sandbox_path != nil{
                clip_model_file_path = sandbox_path!
            }
        }
        //#if os(macOS)
        
        //#endif
        //                            }
        lora_adapters.append(["adapter":lora_file_path,"scale":lora_file_scale])
        let options = get_chat_options_dict()
        _ = CreateChat(options,edit_chat_dialog:self.edit_chat_dialog,chat_name:self.chat_name)
        if add_chat_dialog {
            add_chat_dialog = false
            
        }
        if edit_chat_dialog {
            edit_chat_dialog = false
        }
        after_chat_edit()
    }
    
    @State var tabIndex = 0
    
    var body: some View{
        
        HStack(spacing: 0){
            
            ChatSettingTabs(index:$tabIndex,edit_chat_dialog:$edit_chat_dialog)
                .edgesIgnoringSafeArea(.all)
            // now were going to create main view....
            
            GeometryReader{ g in
                
                VStack{
                    VStack{
                        SettingsHeaderView(add_chat_dialog: $add_chat_dialog,
                                           edit_chat_dialog: $edit_chat_dialog,
                                           model_title: $chat_title,
                                           model_not_selected_alert: $model_not_selected_alert,
                                           save_chat_settings: save_chat_settings)
                        .padding([.leading,.trailing],8)
                    }
//                    ScrollView(showsIndicators: false){
                        // changing tabs based on tabs...
                        switch tabIndex{
                        case 0:
                            ScrollView{
                                GroupBox(label:
                                            //                                Label("Basic Settings", systemImage: "building.columns")
                                         Text("Basic Settings")
                                ) {
                                    BasicSettingsView(chat_title: $chat_title,
                                                      model_icon: $chat_icon,
                                                      model_icons: $chat_icons,
                                                      model_inferences: $model_inferences,
                                                      ggjt_v3_inferences: $ggjt_v3_inferences,
                                                      model_inference: $model_inference,
                                                      ggjt_v3_inference: $ggjt_v3_inference,
                                                      model_inference_inner: $model_inference_inner,
                                                      model_settings_template: $chat_settings_template,
                                                      model_setting_templates: $chat_setting_templates,
                                                      applying_template: $applying_template,
                                                      apply_setting_template: apply_setting_template)
                                }
                                GroupBox(label:
                                            Text("Model")
                                ) {
                                    ModelSettingsView(model_file_url: $model_file_url,
                                                      model_file_path: $model_file_path,
                                                      model_title: $chat_title,
                                                      clip_model_file_url: $clip_model_file_url,
                                                      clip_model_file_path: $clip_model_file_path,
                                                      clip_model_title: $clip_model_title,
                                                      lora_file_url: $lora_file_url,
                                                      lora_file_path: $lora_file_path,
                                                      lora_title: $lora_title,
                                                      lora_file_scale: $lora_file_scale,
                                                      add_chat_dialog: $add_chat_dialog,
                                                      edit_chat_dialog: $edit_chat_dialog,
                                                      toggleSettings: $toggleSettings,
                                                      models_previews: $models_previews,
                                                      loras_previews: $loras_previews,
                                                      has_lora: $has_lora,
                                                      has_clip: $has_clip)
                                }
                                GroupBox(label:
                                            Text("Prediction settings")
                                ) {
                                    PredictionSettingsView(model_context: $model_context,
                                                           model_n_batch: $model_n_batch,
                                                           n_predict: $n_predict,
                                                           numberOfThreads: $numberOfThreads,
                                                           use_metal: $use_metal,
                                                           use_clip_metal: $use_clip_metal,
                                                           mlock: $mlock,
                                                           mmap: $mmap,
                                                           flash_attn: $flash_attn,
                                                           model_inference: $model_inference,
                                                           model_inference_inner: $model_inference_inner,
                                                           has_clip: $has_clip)
                                }
                            }
                        case 1:
                            PromptSettingsView(prompt_format: $prompt_format,
                                               warm_prompt: $warm_prompt,
                                               skip_tokens: $skip_tokens,
                                               reverse_prompt: $reverse_prompt,
                                               add_bos_token: $add_bos_token,
                                               add_eos_token: $add_eos_token,
                                               parse_special_tokens: $parse_special_tokens,
                                               model_inference: $model_inference)
                        case 2:
                            GroupBox(label:
                                        Text("Sampling settings")
                            ) {
                                SamplingSettingsView(model_sampling: $model_sampling,
                                                     model_samplings: $model_samplings,
                                                     model_temp: $model_temp,
                                                     model_top_k: $model_top_k,
                                                     model_top_p: $model_top_p,
                                                     model_repeat_last_n: $model_repeat_last_n,
                                                     model_repeat_penalty: $model_repeat_penalty,
                                                     mirostat: $mirostat,
                                                     mirostat_tau: $mirostat_tau,
                                                     mirostat_eta: $mirostat_eta,
                                                     tfs_z: $tfs_z,
                                                     typical_p: $typical_p,
                                                     grammar: $grammar,
                                                     model_inference: $model_inference,
                                                     grammars_previews: $grammars_previews)
                            }
                        case 4:
                            RagSettingsView(ragDir:"documents/"+(self.chat_name == "" ? "tmp_chat": self.chat_name ),
                                            chunkSize: $chunkSize,
                                            chunkOverlap: $chunkOverlap,
                                            currentModel: $currentModel,
                                            comparisonAlgorithm: $comparisonAlgorithm,
                                            chunkMethod: $chunkMethod,
                                            ragTop: $ragTop)
                        case 5:
                            DocsView(docsDir:"documents/"+(self.chat_name == "" ? "tmp_chat": self.chat_name )+"/docs",
                                    ragDir:"documents/"+(self.chat_name == "" ? "tmp_chat": self.chat_name ),
                                    chunkSize: $chunkSize,
                                    chunkOverlap: $chunkOverlap,
                                    currentModel: $currentModel,
                                    comparisonAlgorithm: $comparisonAlgorithm,
                                    chunkMethod: $chunkMethod)
                        default:
                            GroupBox(label:
                                        Text("Other settings")
                            ) {
                                AdditionalSettingsView(save_load_state: $save_load_state,
                                                       save_as_template_name: $save_as_template_name,
                                                       chat_style:$chat_style,
                                                       chat_styles:$chat_styles,
                                                       get_chat_options_dict: get_chat_options_dict,
                                                       refresh_templates: refresh_templates)
                            }
                        }
                        
//                    }
                    
                }
                .padding([.leading,.trailing],5)
#if os(macOS)
                .padding(.top, topSafeAreaInset())
                .padding(.bottom, bottomSafeAreaInset())
#else
                .padding(.top, UIApplication.shared.keyWindow?.safeAreaInsets.top)
                .padding(.bottom, UIApplication.shared.keyWindow?.safeAreaInsets.bottom)
#endif
            }
        }
//        .edgesIgnoringSafeArea(.all)
    }
}

#if !os(macOS)
extension UIApplication {
    
    var keyWindow: UIWindow? {
        // Get connected scenes
        return self.connectedScenes
        // Keep only active scenes, onscreen and visible to the user
            .filter { $0.activationState == .foregroundActive }
        // Keep only the first `UIWindowScene`
            .first(where: { $0 is UIWindowScene })
        // Get its associated windows
            .flatMap({ $0 as? UIWindowScene })?.windows
        // Finally, keep only the key window
            .first(where: \.isKeyWindow)
    }
    
}
#endif
//#Preview {
//    ChatSettingsView()
//}
