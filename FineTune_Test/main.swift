//
//  main.swift
//  FineTune_Test
//
//  Created by guinmoon on 30.10.2023.
//

import Foundation
import llmfarm_core


var open_llama_finetune: LLaMa_FineTune = LLaMa_FineTune("/Users/guinmoon/dev/alpaca_llama_etc/openllama-3b-v2-q8_0.gguf",
                                        "/Users/guinmoon/dev/alpaca_llama_etc/lora-open-llama-3b-v2-q8_0-shakespeare-LLMFarm.bin",
                                        "/Users/guinmoon/dev/alpaca_llama_etc/pdf/shakespeare.txt")


try? open_llama_finetune.finetune()




