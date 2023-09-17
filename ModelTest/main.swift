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
    print("\(str)",terminator: "")
    total_output += str.count
    if(total_output>maxOutputLength){
        return true
    }
    
    return false
}

func set_promt_format(ai: inout AI) throws -> Bool{
    do{
        ai.model.promptFormat = .LLaMa
    }
    catch{
        print(error)
    }
    return true
}

func main(){
    print("Hello.")
    var input_text = "State the meaning of life."
    var modelInference:ModelInference
    var ai = AI(_modelPath: "/Users/guinmoon/dev/alpaca_llama_etc/orca-mini-3b-q4_1.ggu",_chatName: "chat")
    
//    ai.modelPath = "/Users/guinmoon/Library/Containers/com.guinmoon.LLMFarm/Data/Documents/models/dolly-v2-3b-q5_1.bin"
//    modelInference = ModelInference.GPTNeox
////
//
//    ai.modelPath = "/Users/guinmoon/Library/Containers/com.guinmoon.LLMFarm/Data/Documents/models/rp-incite-base-v1-3b-ggmlv3-q5_1.bin"
//    modelInference = ModelInference.GPTNeox
//
    ai.modelPath = "/Users/guinmoon/Library/Containers/com.guinmoon.LLMFarm/Data/Documents/models/magicprompt-stable-diffusion-q5_1.bin"
//    ai.modelPath = "/Users/guinmoon/Library/Containers/com.guinmoon.LLMFarm/Data/Documents/models/cerebras-2.7b-ggjtv3-q4_0.bin"
//    modelInference = ModelInference.GPT2
//
//    ai.modelPath = "/Users/guinmoon/Library/Containers/com.guinmoon.LLMFarm/Data/Documents/models/replit-code-v1-3b-ggml-q5_1.bin"
//    modelInference = ModelInference.Replit
//
    ai.modelPath = "/Users/guinmoon/Library/Containers/com.guinmoon.LLMFarm/Data/Documents/models/santacoder-q5_1.bin"
    modelInference = ModelInference.Starcoder
    input_text = "def qsort"
//
//    ai.modelPath = "/Users/guinmoon/dev/alpaca_llama_etc/q4_1-RWKV-4-Raven-1B5-v12-Eng.bin"
//    input_text = "who are you?"
    
    //ai.modelPath = "/Users/guinmoon/dev/alpaca_llama_etc/orca-mini-3b.ggmlv3.q4_1.bin
//    ai.modelPath = "/Users/guinmoon/dev/alpaca_llama_etc/orca-mini-3b-q4_1.gguf"
    //ai.modelPath = "/Users/guinmoon/Library/Containers/com.guinmoon.LLMFarm/Data/Documents/models/llama-2-7b.ggmlv3.q4_K_M.bin"
//    modelInference = ModelInference.LLama_gguf
    var params:ModelContextParams = .default
    params.use_metal = true
    
    do{
        try ai.loadModel(modelInference,contextParams: params)
    }catch {
        print (error)
        return
    }
    
////    try? set_promt_format(ai: &ai)
//    let exception = tryBlock {
//
////        try? ai.model.promptFormat = .LLaMa
//
//    }
//
//    if exception != nil {
//        print(exception)
//        exit(1)
//    }
//
//
    
//    ai.model.promptFormat = .Custom
//    ai.model.custom_prompt_format = "Below is an instruction that describes a task. Write a response that appropriately completes the request.### Instruction:{{prompt}}### Response:"
    ////
    
    
    //    ai.model.contextParams.seed = 0;
    //    ai.model.promptStyle = .StableLM_Tuned
    
    
    //    let input_text = "Tell about Stavropol."
    //    let prompt = prompt_for_generation(input_text)
    //    input_text = "What groceries?"
    //    var tokens: [llama_token] = []
    //    var tokens_count:Int = 1
    //    llama_load_session_file(ai.model.context,"/Users/guinmoon/dev/alpaca_llama_etc/dump_state.bin",tokens.mutPtr, 0,&tokens_count)
    let prompt = input_text
    let output = try? ai.model.predict(prompt, mainCallback)
    //    llama_save_session_file(ai.model.context,"/Users/guinmoon/dev/alpaca_llama_etc/dump_state.bin",[], 0)
    //    llama_save_state(ai.model.context,"/Users/guinmoon/dev/alpaca_llama_etc/dump_state.bin")
    //
    print(output!)
}

main()
