//
//  RWKV.swift
//  Mia
//
//  Created by Byron Everson on 4/15/23.
//

import Foundation
import llmfarm_core_cpp

public class RWKV: GPTBase {

    public var tokenizer:Tokenizer
    public var pointerToLogits:UnsafeMutablePointer<Float>? = nil
    public var pointerToStateIn:UnsafeMutablePointer<Float>? = nil
    public var pointerToStateOut:UnsafeMutablePointer<Float>? = nil
    
    
    
    public override init(path: String, contextParams: ModelContextParams = .default) throws {
        let core_resourses = get_core_bundle_path()
        let config = TokenizerConfig(
            vocab: URL(fileURLWithPath: core_resourses! + "/tokenizers/20B_tokenizer_vocab.json"),
            merges: URL(fileURLWithPath: core_resourses! + "/tokenizers/20B_tokenizer_merges.txt")
        )
        self.tokenizer = Tokenizer(config: config)
        try super.init(path: path, contextParams: contextParams)
        
    }
    
    public override func load_model(path: String = "", contextParams: ModelContextParams = .default, params:gpt_context_params ) throws -> Bool{
        self.context = rwkv_init_from_file(path, UInt32(contextParams.numberOfThreads))
        self.promptFormat = .None
        
        return true
    }
    
    deinit {
        rwkv_free(context)
    }
    
    public override func gpt_init_logits() throws -> Bool {
        do{
            if self.contextParams.warm_prompt.count<1{
                self.contextParams.warm_prompt = "\n\n\n"
            }
//            self.contextParams.warm_prompt = "who am i"
            let n_vocab = rwkv_get_logits_len(self.context);
            let n_state = rwkv_get_state_len(self.context);
            self.pointerToLogits = UnsafeMutablePointer<Float>.allocate(capacity: n_vocab)
            self.pointerToStateIn = UnsafeMutablePointer<Float>.allocate(capacity: n_state)
//            self.pointerToStateOut = UnsafeMutablePointer<Float>.allocate(capacity: n_state)
            rwkv_init_state(self.context, pointerToStateIn);
//            rwkv_init_state(self.context, pointerToStateOut);
//            rwkv_init_logits(self.context)
//            rwkv_init_state(self.context, pointerToState);
            let inputs = llm_tokenize(self.contextParams.warm_prompt)
            if try gpt_eval(inputBatch: inputs) == false {
                throw ModelError.failedToEval
            }
            return true
        }
        catch{
            print(error)
        }
        return false
    }
    
    public override func gpt_eval(inputBatch:[ModelToken]) throws -> Bool{
//        var tmp_pointer = self.pointerToStateOut
//        self.pointerToStateOut = self.pointerToStateIn
//        self.pointerToStateIn = tmp_pointer
//        let uint32_input:[UInt32] = inputBatch.map {UInt32($0)}
//        if rwkv_eval_sequence(self.context, uint32_input, uint32_input.count, self.pointerToStateIn, self.pointerToStateIn, self.pointerToLogits) != true {
//            throw ModelError.failedToEval
//        }
        for token in inputBatch{
            rwkv_eval(self.context, UInt32(token), self.pointerToStateIn,self.pointerToStateIn, self.pointerToLogits)
        }
        return true
    }
    
    public override func sample(ctx: OpaquePointer!,
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
        let n_ctx = Int32(4096)
        
        // Auto params
        let n_logits = Int32(rwkv_get_logits_len(self.context))
        let top_k = top_k <= 0 ? n_logits : top_k
        let repeat_last_n = repeat_last_n < 0 ? n_ctx : repeat_last_n
        
        if (last_n_tokens.count>0){
            let sampl = rwkv_sample_repeat(n_logits,self.pointerToLogits,
                                               last_n_tokens,
                                               last_n_tokens.count,
                                               top_k, top_p, temp,
                                               repeat_last_n,repeat_penalty);
            return sampl
        }else{
            let sampl = rwkv_sample(n_logits,self.pointerToLogits, top_k, top_p, temp)
            return sampl
        }
        
    }
    
    
    public override func gpt_token_to_str(outputToken:Int32) -> String? {
        return tokenizer.decode(tokens: [outputToken])
    }
    
    public override func llm_tokenize(_ input: String, bos: Bool = false, eos: Bool = false) -> [ModelToken] {
        if input.count == 0 {
            return []
        }
        let tokens = tokenizer.encode(text: input)
        return tokens
    }
}

