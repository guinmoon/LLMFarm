//
//  main.swift
//  ModelTest
//
//  Created by guinmoon on 20.05.2023.
//

import Foundation
import llmfarm_core
import llmfarm_core_cpp

let maxOutputLength = 500
var total_output = 0
var session_tokens: [Int32] = []

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
//        ai.modelPath = "/Users/guinmoon/Library/Containers/com.guinmoon.LLMFarm/Data/Documents/models/rp-incite-base-v1-3b-ggmlv3-q5_1.bin"
//        modelInference = ModelInference.GPTNeox
    //
    //    ai.modelPath = "/Users/guinmoon/Library/Containers/com.guinmoon.LLMFarm/Data/Documents/models/magicprompt-stable-diffusion-q5_1.bin"
    //    ai.modelPath = "/Users/guinmoon/Library/Containers/com.guinmoon.LLMFarm/Data/Documents/models/cerebras-2.7b-ggjtv3-q4_0.bin"
    //    modelInference = ModelInference.GPT2
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
    
    //    ai.modelPath = "/Users/guinmoon/dev/alpaca_llama_etc/orca-mini-3b.ggmlv3.q4_1.bin"
    //    ai.modelPath = "/Users/guinmoon/Library/Containers/com.guinmoon.LLMFarm/Data/Documents/models/llama-2-7b-chat-q4_K_M.gguf"
//        ai.modelPath = "/Users/guinmoon/dev/alpaca_llama_etc/openllama-3b-v2-q8_0.gguf"
    ai.modelPath = "/Users/guinmoon/Library/Containers/com.guinmoon.LLMFarm/Data/Documents/models/orca-mini-3b-q4_1.gguf"
    modelInference = ModelInference.LLama_gguf
//
    var params:ModelContextParams = .default
//
//    params.use_metal = true
    
//    params.grammar_path = "/Users/guinmoon/dev/alpaca_llama_etc/LLMFarm/LLMFarm/grammars/list.gbnf"
    input_text = "write to do list"
    
    do{
        try ai.loadModel(modelInference,contextParams: params)
    }catch {
        print (error)
        return
    }
    
    
    
    
    
    
    //    input_text = "[INST] <<SYS>>\nYou are a helpful, respectful and honest assistant. Always answer as helpfully as possible.\n<</SYS>>\nTell about Stavropol in one sentence.[/INST]"
    //    input_text = "[INST] <<SYS>>\nYou are a helpful, respectful and honest assistant. Always answer as helpfully as possible.\n<</SYS>>\nTell more.[/INST]"
//    input_text = """
//### User:
//Tell about Stavropol in one sentence
//    
//### Response:
//"""
//    
//    input_text = """
//### User:
//Tell more
//
//### Response:
//"""
//    var tokens: [llama_token] = [Int32](repeating: 0, count: 256)
//    var tokens_count:Int = 1
//    llama_load_state(ai.model.context,"/Users/guinmoon/dev/alpaca_llama_etc/dump_state_.bin")
//    llama_load_session_file(ai.model.context,"/Users/guinmoon/dev/alpaca_llama_etc/dump_state.bin",tokens.mutPtr, 256,&tokens_count)
    
    let output = try? ai.model.predict(input_text, mainCallback)
//    llama_save_session_file(ai.model.context,"/Users/guinmoon/dev/alpaca_llama_etc/dump_state.bin",ai.model.session_tokens, ai.model.session_tokens.count)
//    llama_save_state(ai.model.context,"/Users/guinmoon/dev/alpaca_llama_etc/dump_state_.bin")
    //
    print(output!)
}

main()
