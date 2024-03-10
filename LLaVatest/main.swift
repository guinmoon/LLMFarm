//
//  main.swift
//  LLaVATest
//
//  Created by guinmoon on 10.03.2024.
//

import Foundation
import llmfarm_core_cpp


var args = ["progr_name", "-m", "/Users/guinmoon/dev/alpaca_llama_etc/mobilevlm-3b.Q4_K_M.gguf", "--mmproj", "/Users/guinmoon/dev/alpaca_llama_etc/mobilevlm-3b-mmproj-model-f16.gguf",
            "--image", "/Users/guinmoon/dev/alpaca_llama_etc/Angelina-Jolie-Rome-Film-Fest.jpg", "-ngl","0"]

var cargs = args.map { strdup($0) }

let result = run_llava(Int32(args.count), &cargs,
                            { c_str in
    return true
})

print("Hello, World!")

