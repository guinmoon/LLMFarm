//
//  main.swift
//  FineTune_Test
//
//  Created by guinmoon on 30.10.2023.
//

import Foundation
import llmfarm_core
import llmfarm_core_cpp

func finetune_callback(_ a:Int32) -> Bool{
    print("From Swift \(a)")
    return true
}


let args = ["progr", "--model-base", "/Users/guinmoon/dev/alpaca_llama_etc/openllama-3b-v2-q8_0.gguf", "--lora-out", "/Users/guinmoon/dev/alpaca_llama_etc/lora-open-llama-3b-v2-q8_0-shakespeare-LLMFarm.bin", "--train-data", "/Users/guinmoon/dev/alpaca_llama_etc/pdf/shakespeare.txt",
            "--threads", "12", "--adam-iter", "30", "--batch", "4", "--ctx", "64", "--use-checkpointing"]

// Create [UnsafeMutablePointer<Int8>]:
var cargs = args.map { strdup($0) }
// Call C function:
let result = run_finetune(Int32(args.count), &cargs, { c_str in
    if c_str != nil{
        let for_print = String(cString:c_str!)
        print("Progress: \(for_print)")
    }
    return false
})
// Free the duplicated strings:
for ptr in cargs { free(ptr) }

print("Hello, World!")

