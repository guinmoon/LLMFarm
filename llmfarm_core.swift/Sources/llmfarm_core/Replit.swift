//
//  GPTNeoX.swift
//  Mia
//
//  Created by Byron Everson on 4/19/23.
//

import Foundation
import llmfarm_core_cpp

public class Replit: GPTBase {

    public override func load_model(path: String = "", contextParams: ModelContextParams = .default, params:gpt_context_params ) throws -> Bool{
        self.context = replit_init_from_file(path, params)
        self.promptFormat = .None
        return true
    }
    
    deinit {
        replit_free(context)
    }
    
    public override func gpt_eval(inputBatch:[ModelToken]) throws -> Bool{
        if replit_eval(context, inputBatch, Int32(inputBatch.count), nPast, contextParams.numberOfThreads) != 0 {
            throw ModelError.failedToEval
        }
        return true
    }
    
//    public override func gpt_init_logits() throws -> Bool {
//        if replit_init_logits(context, contextParams.numberOfThreads) != 0 {
//            throw ModelError.failedToEval
//        }
//        return true
//    }
    
    override func sample(ctx: OpaquePointer!,
                last_n_tokens: inout [ModelToken],
                temp: Float32,
                top_k: Int32,
                top_p: Float32,
                tfs_z: Float32,
                typical_p: Float32,
                repeat_last_n: Int32,
                repeat_penalty: Float32,
                alpha_presence: Float32,
                alpha_frequency: Float32,
                mirostat: Int32,
                mirostat_tau: Float32,
                mirostat_eta: Float32,
                penalize_nl: Bool) -> ModelToken {
        // Model input context size
        let n_ctx = gpt_base_n_ctx(ctx)
        
        // Auto params
        
        let top_k = top_k <= 0 ? gpt_base_n_vocab(ctx) : top_k
        let repeat_last_n = repeat_last_n < 0 ? n_ctx : repeat_last_n
        
        if (last_n_tokens.count>0){
            let sampl = replit_sample_repeat(ctx,
                                               last_n_tokens,
                                               last_n_tokens.count,
                                               top_k, top_p, temp,
                                               repeat_last_n,repeat_penalty);
            return sampl
        }else{
            let sampl = replit_sample(ctx, top_k, top_p, temp)
            return sampl
        }
        
    }
    
    public override func gpt_token_to_str(outputToken:Int32) -> String? {
        if let cStr = replit_token_to_str(context, outputToken){
            return String(cString: cStr)
        }
        return nil
    }
    
    public override func llm_tokenize(_ input: String, bos: Bool = false, eos: Bool = false) -> [ModelToken] {
        if input.count == 0 {
            return []
        }
        
        var embeddings = Array<ModelToken>(repeating: gpt_token(), count: input.utf8.count)
        let n = replit_tokenize(context, input, &embeddings, Int32(input.utf8.count), bos)
        assert(n >= 0)
        embeddings.removeSubrange(Int(n)..<embeddings.count)
        
        if eos {
            embeddings.append(gpt_base_token_eos())
        }
        
        return embeddings
    }
}


