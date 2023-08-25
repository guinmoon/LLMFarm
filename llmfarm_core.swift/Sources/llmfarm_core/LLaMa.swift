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
    
    override func gpt_n_vocab(_ ctx: OpaquePointer!) -> Int32{
        return llama_n_vocab(ctx)
    }
    
    override func gpt_get_logits(_ ctx: OpaquePointer!) -> UnsafeMutablePointer<Float>?{
        return llama_get_logits(ctx);
    }

    public override func gpt_eval(inputBatch:[ModelToken]) throws -> Bool{
        if llama_eval(context, inputBatch, Int32(inputBatch.count), nPast, contextParams.numberOfThreads) != 0 {
            throw ModelError.failedToEval
        }
        return true
    }
    
    public override func gpt_token_to_str(outputToken:Int32) -> String? {
//        var cStringPtr: UnsafeMutablePointer<CChar>? = nil
//        var cStr_len: Int32 = 0;
//        llama_token_to_str(context, outputToken,cStringPtr,cStr_len)
//        if cStr_len>0{
//            return String(cString: cStringPtr!)
//        }
        if let cStr = llama_token_to_str(context, outputToken){
            return String(cString: cStr)
        }
        return nil
    }
    
    public override func gpt_token_nl() -> ModelToken{
//        return llama_token_nl(self.context)
        return llama_token_nl()
    }

    public override func gpt_token_bos() -> ModelToken{
//        return llama_token_bos(self.context)
        return llama_token_bos()
    }
    
    public override func gpt_token_eos() -> ModelToken{
//        return llama_token_eos(self.context)
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
//            embeddings.append(llama_token_eos(self.context))
            embeddings.append(llama_token_eos())
        }
        
        return embeddings
    }
}

