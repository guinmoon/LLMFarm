//
//  main.swift
//  ModelTest
//
//  Created by guinmoon on 20.05.2023.
//

import Foundation
import llmfarm_core
import llmfarm_core_cpp

let maxOutputLength:Int32 = 100
var total_output = 0
var session_tokens: [Int32] = []

func mainCallback(_ str: String, _ time: Double) -> Bool {
    print("\(str)",terminator: "")
    total_output += str.count
    return false
}

func set_promt_format(ai: inout AI) throws -> Bool{
    do{
        ai.model?.contextParams.promptFormat = .None
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
    //        ai.modelPath = "/Users/guinmoon/Library/Containers/com.guinmoon.LLMFarm/Data/Documents/models/rp-incite-base-v1-3b-ggmlv3-q5_1.bin"
    //        modelInference = ModelInference.GPTNeox
    //
    //    ai.modelPath = "/Users/guinmoon/Library/Containers/com.guinmoon.LLMFarm/Data/Documents/models/magicprompt-stable-diffusion-q5_1.bin"
        // ai.modelPath = "/Users/guinmoon/Library/Containers/com.guinmoon.LLMFarm/Data/Documents/models/cerebras-2.7b-ggjtv3-q4_0.bin"
        // modelInference = ModelInference.GPT2
    //
        

    //    ai.modelPath = "/Users/guinmoon/Library/Containers/com.guinmoon.LLMFarm/Data/Documents/models/replit-code-v1-3b-ggml-q5_1.bin"
    //    modelInference = ModelInference.Replit
    //
    //    ai.modelPath = "/Users/guinmoon/Library/Containers/com.guinmoon.LLMFarm/Data/Documents/models/santacoder-q5_1.bin"
    //    modelInference = ModelInference.Starcoder
    //    input_text = "def qsort"
    //
    //        ai.modelPath = "/Users/guinmoon/dev/alpaca_llama_etc/q4_1-RWKV-4-Raven-1B5-v12-Eng.bin"
    //    //    ai.modelPath = "/Users/guinmoon/dev/alpaca_llama_etc/RWKV-4-MIDI-120M-v1-20230714-ctx4096-FP16.bin"
    //    //    ai.modelPath = "/Users/guinmoon/dev/alpaca_llama_etc/Sources/rwkv.cpp-master-8db73b1/tests/tiny-rwkv-660K-FP16.bin"
    //        modelInference = ModelInference.RWKV
    //        input_text = "song about love"
    
    //    ai.modelPath = "/Users/guinmoon/dev/alpaca_llama_etc/tinydolphin-2.8-1.1b.Q8_0.imx.gguf"
    //    ai.modelPath = "/Users/guinmoon/dev/alpaca_llama_etc/gemma-2b-it.Q8_0.gguf"
       ai.modelPath = "/Users/guinmoon/dev/alpaca_llama_etc/LaMini-Flan-T5-248M.Q8_0.gguf"
    
              
    //    ai.modelPath = "/Users/guinmoon/Library/Containers/com.guinmoon.LLMFarm/Data/Documents/models/llama-2-7b-chat-q4_K_M.gguf"
//    ai.modelPath = "/Users/guinmoon/dev/alpaca_llama_etc/openllama-3b-v2-q8_0.gguf"
//    ai.modelPath = "/Users/guinmoon/dev/alpaca_llama_etc/bloom-560m-finetuned-sd-prompts-f16.gguf"
//    ai.modelPath = "/Users/guinmoon/dev/alpaca_llama_etc/SantaCoder-1B-f16.gguf"
//    ai.modelPath = "/Users/guinmoon/dev/alpaca_llama_etc/open_llama_3b_v2_ggml-model-f16.gguf"
//    ai.modelPath = "/Users/guinmoon/dev/alpaca_llama_etc/stablelm-3b-4e1t-Q4_K_M.gguf"
//    ai.modelPath = "/Users/guinmoon/Library/Containers/com.guinmoon.LLMFarm/Data/Documents/models/mpt-7b-storywriter-Q4_K.gguf"
//       ai.modelPath = "/Users/guinmoon/Library/Containers/com.guinmoon.LLMFarm/Data/Documents/models/orca-mini-3b-q4_1.gguf"
        modelInference = ModelInference.LLama_gguf
    //
    var params:ModelAndContextParams = .default
    params.context = 512
    params.n_threads = 14
    //
    params.use_metal = true
    params.n_predict = maxOutputLength
    params.flash_attn = false
    // params.add_bos_token = false
    // params.add_eos_token = true
    params.parse_special_tokens = true
    // params.grammar_path = "/Users/guinmoon/dev/alpaca_llama_etc/LLMFarm/LLMFarm/grammars/json.gbnf"
    // params.grammar_path = "/Users/guinmoon/dev/alpaca_llama_etc/LLMFarm/LLMFarm/grammars/list.gbnf"
//    params.lora_adapters.append(("/Users/guinmoon/dev/alpaca_llama_etc/lora-open-llama-3b-v2-q8_0-my_finetune-LATEST.bin",1.0 ))
//    input_text = "To be or not"
    
    input_text = "Write story about Artem."
    do{

        ai.initModel(modelInference,contextParams: params)
        if ai.model == nil{
            print( "Model load eror.")
            exit(2)
        }
        try ai.loadModel_sync()
        
        
        var output: String?
        try ExceptionCather.catchException {
            output = try? ai.model?.predict(input_text, mainCallback) ?? ""
        }

        print(output)
    }catch {
        print (error)
        return
    }
}

main()
