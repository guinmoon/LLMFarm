//
//  ModelSettingsTemplate.swift
//  LLMFarm
//
//  Created by guinmoon on 17.07.2023.
//

import Foundation

struct ChatSettingsTemplate: Hashable {
    var template_name: String = "Custom"
    var inference: String = "llama"
    var context: Int32 = 1024
    var n_batch: Int32 = 512
    var temp: Float = 0.9
    var top_k: Int32 = 40
    var top_p: Float = 0.95
    var repeat_last_n: Int32 = 64
    var repeat_penalty: Float = 1.1
    var prompt_format: String = "{{prompt}}"
    var reverse_prompt:String = ""
    var use_metal:Bool = false
    var use_clip_metal:Bool = false
    var mirostat:Int32 =  0
    var mirostat_tau:Float = 5
    var mirostat_eta :Float =  0.1
    var grammar:String = "<None>"
    var numberOfThreads:Int32 = 0
    var add_bos_token:Bool =  true
    var add_eos_token:Bool = false
    var parse_special_tokens = true
    var mmap:Bool = true
    var mlock:Bool = false
    var flash_attn: Bool = false
    var tfs_z:Float =  1
    var typical_p:Float = 1
    var skip_tokens: String = ""
    
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(template_name)
    }
    
    
    static func == (lhs: ChatSettingsTemplate, rhs: ChatSettingsTemplate) -> Bool {
        return lhs.template_name == rhs.template_name 
    }
}
