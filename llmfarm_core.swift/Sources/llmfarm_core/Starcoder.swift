//
//  GPTNeoX.swift
//  Mia
//
//  Created by Byron Everson on 4/19/23.
//

import Foundation
import llmfarm_core_cpp

public class Starcoder: GPTBase {

    public override func load_model(path: String = "", contextParams: ModelContextParams = .default, params:gpt_context_params ) throws -> Bool{
        self.context = starcoder_init_from_file(path, params)
        self.promptFormat = .None
        return true
    }
    
    deinit {
        gpt2_free(context)
    }
    
    public override func gpt_eval(inputBatch:[ModelToken]) throws -> Bool{
        if starcoder_eval(context, inputBatch, Int32(inputBatch.count), nPast, contextParams.numberOfThreads) != 0 {
            throw ModelError.failedToEval
        }
        return true
    }
    
}


