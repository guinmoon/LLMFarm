//
//  main.swift
//  LLaVATest
//
//  Created by guinmoon on 10.03.2024.
//

import Foundation
import llmfarm_core
//import llmfarm_core_cpp


//var args = ["progr_name", "-m", "/Users/guinmoon/dev/alpaca_llama_etc/mobilevlm-3b.Q4_K_M.gguf", "--mmproj", "/Users/guinmoon/dev/alpaca_llama_etc/mobilevlm-3b-mmproj-model-f16.gguf",
//            "--image", "/Users/guinmoon/dev/alpaca_llama_etc/Angelina-Jolie-Rome-Film-Fest.jpg", "-ngl","0"]
//
//var cargs = args.map { strdup($0) }
//
//let result = run_llava(Int32(args.count), &cargs,
//                            { c_str in
//    return true
//})
//
print("Hello, World!")
let maxOutputLength = 256
var total_output = 0

func mainCallback(_ str: String, _ time: Double) -> Bool {
    print("\(str)",terminator: "")
    total_output += str.count
    if(total_output>maxOutputLength){
        return true
    }
    return false
}


//load model
let ai = AI(_modelPath: "/Users/guinmoon/dev/alpaca_llama_etc/mobilevlm-3b.Q4_K_M.gguf",_chatName: "chat")
var params:ModelAndContextParams = .default

//set custom prompt format
params.clip_model = "/Users/guinmoon/dev/alpaca_llama_etc/mobilevlm-3b-mmproj-model-f16.gguf"
params.promptFormat = .Custom
params.custom_prompt_format = """
SYSTEM: You are a helpful, respectful and honest assistant.
USER: {prompt}
ASSISTANT:
"""
var input_text = "Who on this picture?"

//params.use_metal = true

try? _ = ai.loadModel_sync(ModelInference.LLama_mm,contextParams:params)
_ = ai.model.make_image_embed("/Users/guinmoon/dev/alpaca_llama_etc/Angelina-Jolie-Rome-Film-Fest.jpg")
let output = try? ai.model.predict(input_text, mainCallback)
