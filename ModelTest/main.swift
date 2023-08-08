//
//  main.swift
//  ModelTest
//
//  Created by guinmoon on 20.05.2023.
//

import Foundation
import llmfarm_core
import llmfarm_core_cpp

let maxOutputLength = 256
var total_output = 0

func mainCallback(_ str: String, _ time: Double) -> Bool {

    total_output += str.count
    if(total_output>maxOutputLength){
        return true
    }
    
    return false
}

func main(){
    print("Hello.")
    var input_text = "State the meaning of life."
    
    //    let ai = AI(_modelPath: "/Users/guinmoon/Library/Containers/com.guinmoon.LLMFarm/Data/Documents/models/dolly-v2-3b-q5_1.bin",_chatName: "chat")
    //    try? ai.loadModel(ModelInference.GPTNeoxInference)
    //    ai.model.custom_prompt_format = "Below is an instruction that describes a task. Write a response that appropriately completes the request.### Instruction:{{prompt}}### Response:"
    //    ai.model.promptFormat = .Custom
    //    ai.model.promptFormat = .Dolly_b3
    //    let ai = AI(_modelPath: "/Users/guinmoon/Library/Containers/com.guinmoon.LLMFarm/Data/Documents/models/AI-Dungeon-2-Classic.bin",_chatName: "chat")
    //    try? ai.loadModel(ModelInference.GPT2)
    //    ai.model.promptFormat = .None
    //
    //    let ai = AI(_modelPath: "/Users/guinmoon/dev/alpaca_llama_etc/replit-code-v1-3b-ggml-q5_1.bin",_chatName: "chat")
    //    try? ai.loadModel(ModelInference.Replit)
    //    ai.model.promptFormat = .None
        let ai = AI(_modelPath: "/Users/guinmoon/dev/alpaca_llama_etc/orca-mini-3b.ggmlv3.q4_1.bin",_chatName: "chat")
    //    let ai = AI(_modelPath: "/Users/guinmoon/dev/alpaca_llama_etc/orca-mini-7b.ggmlv3.q3_K_M.bin",_chatName: "chat")
        var params:ModelContextParams = .default
//        params.use_metal = true
        try? ai.loadModel(ModelInference.LLamaInference,contextParams: params)
        ai.model.promptFormat = .LLaMa
    
    //    let ai = AI(_modelPath: "/Users/guinmoon/dev/alpaca_llama_etc/santacoder-q8_0.bin",_chatName: "chat")
    //    try? ai.loadModel(ModelInference.Starcoder)
    //    ai.model.promptFormat = .None
    //    input_text = "def quicksort"
    
//    let ai = AI(_modelPath: "/Users/guinmoon/dev/alpaca_llama_etc/q4_1-RWKV-4-Raven-1B5-v12-Eng98%-Other2%-20230520-ctx4096.bin",_chatName: "chat")
//    try? ai.loadModel(ModelInference.RWKV)
//    ai.model.promptFormat = .None
////    input_text = "who are you?"
    
    ai.model.contextParams.seed = 0;
    //    ai.model.promptStyle = .StableLM_Tuned
    
    
    //    let input_text = "Tell about Stavropol."
    //    let prompt = prompt_for_generation(input_text)
    input_text = "What groceries?"
    var tokens: [llama_token] = []
    var tokens_count:Int = 1
    llama_load_session_file(ai.model.context,"/Users/guinmoon/dev/alpaca_llama_etc/dump_state.bin",tokens.mutPtr, 0,&tokens_count)
    let prompt = input_text
    let output = try?ai.model.predict(prompt, mainCallback)
    llama_save_session_file(ai.model.context,"/Users/guinmoon/dev/alpaca_llama_etc/dump_state.bin",[], 0)
//    llama_save_state(ai.model.context,"/Users/guinmoon/dev/alpaca_llama_etc/dump_state.bin")
//    
    print(output!)
}

main()
