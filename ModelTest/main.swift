//
//  main.swift
//  ModelTest
//
//  Created by guinmoon on 20.05.2023.
//

import Foundation
import llmfarm_core
import llmfarm_core_cpp

let maxOutputLength: Int32 = 100
var totalOutput = 0
var totalTokensOutput: Int32 = 0
var sessionTokens: [Int32] = []
var ai: AI? = nil




func mainCallback(_ str: String, _ time: Double) -> Bool {
    print("\(str)", terminator: "")
    totalOutput += str.count
    totalTokensOutput += 1
    return false
}

func setPromptFormat(ai: inout AI?) throws -> Bool {
    ai?.model?.contextParams.promptFormat = .None
    return true
}

func main() {
    print("Hello.")
    var inputText = "State the meaning of life."
    var modelInference: ModelInference
    ai = AI(_modelPath: "", _chatName: "chat")

//    ai?.modelPath = "/Volumes/Share/gemma-3-4b-it-q4_0.gguf"
//    ai?.modelPath = "/Volumes/VMware Shared Folders/Share/gemma-3-4b-it-q4_0.gguf"
    ai?.modelPath = "/Users/guinmoon_dev/gemma-3-1b-it-Q4_K_M.gguf"
//    ai?.modelPath = "/Volumes/Share/gemma-3-4b-it-q4_0.gguf"
    modelInference = ModelInference.LLama_gguf

    var params: ModelAndContextParams = .default
    params.context = 2048
    params.n_threads = 8
    params.use_metal = false
    params.n_predict = maxOutputLength
    params.flash_attn = false
    params.parse_special_tokens = true

    inputText = "Tell about Stavropol in one sentence."
    do {
        ai?.initModel(modelInference, contextParams: params)
        guard let model = ai?.model else {
            print("Model load error.")
            exit(2)
        }
        try ai?.loadModel_sync()

        var output: String?
        try ExceptionCather.catchException {
            output = try? model.Predict(inputText, mainCallback)
        }

//        llama_kv_cache_seq_rm(model.context, -1, 0, -1)
//        print(output ?? "")
//
//        try ExceptionCather.catchException {
//            output = try? model.Predict("tell more", mainCallback) 
//        }

        print(output ?? "")
    } catch {
        print(error)
        return
    }
}

main()
