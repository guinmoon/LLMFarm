//
//  LLaMa.swift
//  Mia
//
//  Created by Byron Everson on 4/15/23.
//

import Foundation 
import llmfarm_core

public class LLaMa: GPTBase {

//    public override init(path: String, contextParams: ModelContextParams = .default) throws {
//        try super.init()
//        
//        self.promptFormat = .LLaMa_QA
//        
//        self.contextParams = contextParams
//        var params = llama_context_default_params()
//        params.n_ctx = contextParams.context
////        params.n_parts = contextParams.parts
//        params.seed = contextParams.seed
//        params.f16_kv = contextParams.f16Kv
//        params.logits_all = contextParams.logitsAll
//        params.vocab_only = contextParams.vocabOnly
//        params.use_mlock = contextParams.useMlock
//        params.embedding = contextParams.embedding
//        // Check if model file exists
//        if !FileManager.default.fileExists(atPath: path) {
//            throw ModelError.modelNotFound(path)
//        }
//        // Load model at path
//        self.context = llama_init_from_file(path, params)
//        // Print llama arch and cpu features info
//        print(String(cString: llama_print_system_info()))
//    }
    
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
    
//    // Used to keep old context until it needs to be rotated or purge out for new tokens
//    var past: [[ModelToken]] = [] // Will house both queries and responses in order
//    //var n_history: Int32 = 0
//    var nPast: Int32 = 0

    public override func gpt_eval(inputBatch:[ModelToken]) throws -> Bool{
        if llama_eval(context, inputBatch, Int32(inputBatch.count), nPast, contextParams.numberOfThreads) != 0 {
            throw ModelError.failedToEval
        }
        return true
    }
    
    public override func predict(_ input: String, _ callback: ((String, Double) -> Bool) ) throws -> String {
        // Sample parameters
        let params = sampleParams
        // Debug shorter contextLength to purge faster
        let contextLength = Int32(contextParams.context)
        print("Past token count: \(nPast)/\(contextLength) (\(past.count))")
        // Tokenize with prompt style
        var inputTokens = tokenizePrompt(input, promptFormat)
        let inputTokensCount = inputTokens.count
        print("Input tokens: \(inputTokens)")
        // Add new input tokens to past array
        past.append(inputTokens)
        // Create space in context if needed
        if inputTokensCount > contextLength {
            throw ModelError.inputTooLong
        }
        var totalLength = nPast + Int32(inputTokensCount)
        while totalLength > contextLength {
            // Not enough room to predict even a single token so purge
            let forgetCount = Int32(past.first!.count)
            past.removeFirst()
//            llama_shift_kv_cache(context, forgetCount)
            // Update count vars
            nPast -= forgetCount
            totalLength -= forgetCount
            // Print how many tokens are purged
            print("💾 \(forgetCount) tokens purged from context memory")
        }
        // Input
        var inputBatch = Array<llama_token>()
        // Inputs tokens, do not include inputs in output for conversational usage
        while inputTokens.count > 0 {
            // Clear input batch
            inputBatch.removeAll()
            // See how many to eval (up to batch size??? or can we feed the entire input)
            let evalCount = min(inputTokens.count, Int(params.n_batch))
            // Move tokens to batch
            inputBatch.append(contentsOf: inputTokens[0 ..< evalCount])
            inputTokens.removeFirst(evalCount)
            // Eval batch
            if llama_eval(context, inputBatch, Int32(inputBatch.count), nPast, contextParams.numberOfThreads) != 0 {
                throw ModelError.failedToEval
            }
            // Increment past count
            nPast += Int32(evalCount)
        }
        // Output
        var outputRepeatTokens: [ModelToken] = []
        var outputTokens: [ModelToken] = []
        var output = [String]()
        // Loop until target count is reached
        var outputEnabled = true
        while outputEnabled {
            // Pull a generation from context
            let outputToken = sample(
                ctx: context,
                last_n_tokens: &outputRepeatTokens,
                temp: params.temp,
                top_k: params.top_k,
                top_p: params.top_p,
                tfs_z: params.tfs_z,
                typical_p: params.repeat_penalty,
                repeat_last_n: params.repeat_last_n,
                repeat_penalty: params.repeat_penalty,
                alpha_presence: params.presence_penalty,
                alpha_frequency: params.frequence_penalty,
                mirostat: params.mirostat,
                mirostat_tau: params.mirostat_tau,
                mirostat_eta: params.mirostat_eta,
                penalize_nl: params.penalize_nl
            )
            // Add output token to array
            outputTokens.append(outputToken)
            // Repeat tokens update
            outputRepeatTokens.append(outputToken)
            if outputRepeatTokens.count > params.repeat_last_n {
                outputRepeatTokens.removeFirst()
            }
            // Check for eos - end early - check eos before bos in case they are the same
            if outputToken == llama_token_eos() {
                outputEnabled = false
                print("🤖 [EOS]")
                break
            }
            // Check for bos - skip callback if so
            var skipCallback = false
            if outputToken == llama_token_bos() {
                print("🤖 [BOS]")
                skipCallback = true //continue
            }
            // Convert token to string and callback
            if !skipCallback, let cStr = llama_token_to_str(context, outputToken) {
                let str = String(cString: cStr)
                // Append string to output
                output.append(str)
                // Per token callback
                let (output, time) = Utils.time {
                    return str
                }
//                print("🤖 \(output) \(outputToken)") //" \(tokenProb)")
                print("\(output)",terminator: "") //" \(tokenProb)")
                if callback(output, time) {
                    // Early exit if requested by callback
                    print("💀 Early exit")
                    //generating = false
                    outputEnabled = false
                    break
                }
            }
            // Check if we need to run another eval
            if outputEnabled {
                // Send generated token back into model for next generation
                if llama_eval(context, [outputToken], 1, nPast, contextParams.numberOfThreads) != 0 {
                    throw ModelError.failedToEval
                }
                // Increment past count
                nPast += 1
                // Check to see if we need to forget (create space in context)
                if nPast > contextLength {
                    // Not enough room to predict even a single token so purge oldest from past and kv cache
                    // If nothing in past to purge so simply remove tokens from the beginning of the response
                    // Remove a batch of 8 or 16 tokens from beginning of response if no past, this helps reduce the frequency of shifts, but will make the model forget quicker if the forget batch size is too high
                    // In theory, the model can continue to build a response infinitely
                    var forgetCount: Int32 = 16 //8 //1
                    if let first = past.first {
                        forgetCount = Int32(first.count)
                        past.removeFirst()
                    }
//                    llama_shift_kv_cache(context, forgetCount)
                    // Update nPast from purge
                    nPast -= forgetCount
                    // Print how many tokens are purged
                    print("💾 \(forgetCount) tokens purged from context memory")
                }
            }
        }
        // Total tokens used
        print("Total tokens: \(inputTokensCount + outputTokens.count) (\(inputTokensCount) -> \(outputTokens.count))")
        // Return full string (for cases where callback is not used)
        return output.joined()
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

