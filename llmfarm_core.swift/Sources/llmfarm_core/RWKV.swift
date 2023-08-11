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
            let n_vocab = rwkv_get_logits_len(self.context);
            let n_state = rwkv_get_state_len(self.context);
            self.pointerToLogits = UnsafeMutablePointer<Float>.allocate(capacity: n_vocab)
            self.pointerToStateIn = UnsafeMutablePointer<Float>.allocate(capacity: n_state)
//            self.pointerToStateOut = UnsafeMutablePointer<Float>.allocate(capacity: n_state)
            rwkv_init_state(self.context, pointerToStateIn);
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
        for token in inputBatch{
            rwkv_eval(self.context, UInt32(token), self.pointerToStateIn,self.pointerToStateIn, self.pointerToLogits)
        }
        return true
    }
    
    
    override func gpt_n_vocab(_ ctx: OpaquePointer!) -> Int32{
        return Int32(rwkv_get_logits_len(self.context))
    }
    
    override func gpt_get_logits(_ ctx: OpaquePointer!) -> UnsafeMutablePointer<Float>?{
        return self.pointerToLogits;
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

