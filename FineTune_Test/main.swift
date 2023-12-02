//
//  main.swift
//  FineTune_Test
//
//  Created by guinmoon on 30.10.2023.
//

import Foundation
import llmfarm_core


var open_llama_finetune: LLaMa_FineTune = LLaMa_FineTune("/Users/guinmoon/dev/alpaca_llama_etc/open_llama_3b_v2_ggml-model-Q8_0.gguf",
                                        "/Users/guinmoon/dev/alpaca_llama_etc/lora-open-llama-3b-v2-q8_0-shakespeare-LLMFarm.bin",
                                        "/Users/guinmoon/dev/alpaca_llama_etc/pdf/shakespeare.txt")

open_llama_finetune.use_metal = true
open_llama_finetune.threads = 12
try? open_llama_finetune.finetune({
    str in
    print(str)
})




