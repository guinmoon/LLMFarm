//
//  ModelSettingsTemplate.swift
//  LLMFarm
//
//  Created by guinmoon on 17.07.2023.
//

import Foundation

struct ModelSettingsTemplate: Hashable {
    var template_name: String = "Custom"
    var inference = "llama"
    var context: Int32 = 2048
    var n_batch: Int32 = 512
    var temp: Float = 0.9
    var top_k: Int32 = 40
    var top_p: Float = 0.95
    var repeat_last_n: Int32 = 64
    var repeat_penalty: Float = 1.1
    var prompt_format: String = "{{prompt}}"
    var warm_prompt: String = "\\n\\n\\n"
    var reverse_prompt:String = ""
    var use_metal:Bool = false
    
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(template_name)
    }
    
    static func == (lhs: ModelSettingsTemplate, rhs: ModelSettingsTemplate) -> Bool {
        return lhs.template_name == rhs.template_name 
    }
}
