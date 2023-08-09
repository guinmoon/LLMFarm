//
//  LLaMa.swift
//  Mia
//
//  Created by Byron Everson on 4/15/23.
//

import Foundation 
import llmfarm_core_cpp

public class LLaMa: GPTBase {

    
    public override func load_model(path: String = "", contextParams: ModelContextParams = .default, params:gpt_context_params ) throws -> Bool{
        var params = llama_context_default_params()
        params.n_ctx = contextParams.context
//        params.n_parts = contextParams.parts
        params.seed = UInt32(contextParams.seed)
        params.f16_kv = contextParams.f16Kv
        params.logits_all = contextParams.logitsAll
        params.vocab_only = contextParams.vocabOnly
        params.use_mlock = contextParams.useMlock
        params.embedding = contextParams.embedding
        if contextParams.use_metal{
            params.n_gpu_layers = 1
        }
        self.context = llama_init_from_file(path, params)
        return true
    }
    
    deinit {
        llama_free(context)
    }
    
    // Simple topK, topP, temp sampling, with repeat penalty
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
        let n_ctx = llama_n_ctx(ctx)
        
        // Auto params
        let top_k = top_k <= 0 ? llama_n_vocab(ctx) : top_k
        let repeat_last_n = repeat_last_n < 0 ? n_ctx : repeat_last_n
        
        // Get logits and vocab size
        let vocabSize = llama_n_vocab(ctx)
        guard let logits = llama_get_logits(ctx) else {
            print("LLaMa sample error logits nil")
            return 0
        }
        
        // Create candidates
        var candidates = Array<llama_token_data>()
        for i in 0 ..< vocabSize {
            candidates.append(llama_token_data(id: i, logit: logits[Int(i)], p: 0.0))
        }
        var candidates_p = llama_token_data_array(data: candidates.mutPtr, size: candidates.count, sorted: false)
        
        // Apply penalties
        let nl_token = Int(llama_token_nl())
        let nl_logit = logits[nl_token]
        let last_n_repeat = min(min(Int32(last_n_tokens.count), repeat_last_n), n_ctx)
        llama_sample_repetition_penalty(context, &candidates_p,
                    last_n_tokens.mutPtr.advanced(by: last_n_tokens.count - Int(repeat_last_n)),
                    Int(repeat_last_n), repeat_penalty)
        llama_sample_frequency_and_presence_penalties(ctx, &candidates_p,
                    last_n_tokens.mutPtr.advanced(by: last_n_tokens.count - Int(repeat_last_n)),
                    Int(last_n_repeat), alpha_frequency, alpha_presence)
        if(!penalize_nl) {
            logits[nl_token] = nl_logit
        }
        
        if(temp <= 0) {
            // Greedy sampling
            return llama_sample_token_greedy(ctx, &candidates_p)
        } else {
            if(mirostat == 1) {
                var mirostat_mu: Float = 2.0 * mirostat_tau
                let mirostat_m = 100
                llama_sample_temperature(ctx, &candidates_p, temp)
                return llama_sample_token_mirostat(ctx, &candidates_p, mirostat_tau, mirostat_eta, Int32(mirostat_m), &mirostat_mu);
            } else if(mirostat == 2) {
                var mirostat_mu: Float = 2.0 * mirostat_tau
                llama_sample_temperature(ctx, &candidates_p, temp)
                return llama_sample_token_mirostat_v2(ctx, &candidates_p, mirostat_tau, mirostat_eta, &mirostat_mu)
            } else {
                // Temperature sampling
                llama_sample_top_k(ctx, &candidates_p, top_k, 1)
                llama_sample_tail_free(ctx, &candidates_p, tfs_z, 1)
                llama_sample_typical(ctx, &candidates_p, typical_p, 1)
                llama_sample_top_p(ctx, &candidates_p, top_p, 1)
                llama_sample_temperature(ctx, &candidates_p, temp)
                return llama_sample_token(ctx, &candidates_p)
            }
        }
    }
    


    public override func gpt_eval(inputBatch:[ModelToken]) throws -> Bool{
        if llama_eval(context, inputBatch, Int32(inputBatch.count), nPast, contextParams.numberOfThreads) != 0 {
            throw ModelError.failedToEval
        }
        return true
    }
    
    public override func gpt_token_to_str(outputToken:Int32) -> String? {
        if let cStr = llama_token_to_str(context, outputToken){
            return String(cString: cStr)
        }
        return nil
    }


    public override func gpt_token_bos() -> ModelToken{
        return llama_token_bos()
    }
    
    public override func gpt_token_eos() -> ModelToken{
        return llama_token_eos()
    }
    
    public override func embeddings(_ input: String) throws -> [Float] {
        // Add a space in front of the first character to match OG llama tokenizer behavior
        let input = " " + input

        // tokenize the prompt
        let inputs = llm_tokenize(input)

        guard inputs.count > 0 else {
            return []
        }

        if llama_eval(context, inputs, Int32(inputs.count), Int32(0), contextParams.numberOfThreads) != 0 {
            throw ModelError.failedToEval
        }

        let embeddingsCount = Int(llama_n_embd(context))
        guard let embeddings = llama_get_embeddings(context) else {
            return []
        }
        return Array(UnsafeBufferPointer(start: embeddings, count: embeddingsCount))
    }

    public override func llm_tokenize(_ input: String, bos: Bool = true, eos: Bool = false) -> [ModelToken] {
        if input.count == 0 {
            return []
        }

        var embeddings: [llama_token] = Array<llama_token>(repeating: llama_token(), count: input.utf8.count)
        let n = llama_tokenize(context, input, &embeddings, Int32(input.utf8.count), bos)
        assert(n >= 0)
        embeddings.removeSubrange(Int(n)..<embeddings.count)
        
        if eos {
            embeddings.append(llama_token_eos())
        }
        
        return embeddings
    }
}

