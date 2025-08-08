//
//  DistilbertEmbeddingsCPUandGPU.swift
//  RAG_Test
//
//  Created by guinmoon on 17.10.2024.
//

import Foundation

import CoreML
import SimilaritySearchKit
import SimilaritySearchKitDistilbert

public class DistilbertEmbeddingsCPUandGPU: EmbeddingsProtocol {
    public let model: msmarco_distilbert_base_tas_b_512_single_quantized
    public let tokenizer: BertTokenizer
    public let inputDimention: Int = 512
    public let outputDimention: Int = 768

    public init() {
        let modelConfig = MLModelConfiguration()
        
#if targetEnvironment(simulator)
        modelConfig.computeUnits = .cpuOnly
#elseif os(macOS)
        modelConfig.computeUnits = .cpuAndGPU
#else
        modelConfig.computeUnits = .all
#endif
        
        

        do {
            self.model = try msmarco_distilbert_base_tas_b_512_single_quantized(configuration: modelConfig)
        } catch {
            fatalError("Failed to load the Core ML model. Error: \(error.localizedDescription)")
        }

        self.tokenizer = BertTokenizer()
    }

    // MARK: - Dense Embeddings

    public func encode(sentence: String) async -> [Float]? {
        // Encode input text as bert tokens
        let inputTokens = tokenizer.buildModelTokens(sentence: sentence)
        let (inputIds, attentionMask) = tokenizer.buildModelInputs(from: inputTokens)

        // Send tokens through the MLModel
        let embeddings = generateDistilbertEmbeddings(inputIds: inputIds, attentionMask: attentionMask)

        return embeddings
    }

    public func generateDistilbertEmbeddings(inputIds: MLMultiArray, attentionMask: MLMultiArray) -> [Float]? {
        let inputFeatures = msmarco_distilbert_base_tas_b_512_single_quantizedInput(
            input_ids: inputIds,
            attention_mask: attentionMask
        )

        let output = try? model.prediction(input: inputFeatures)

        guard let embeddings = output?.embeddings else {
            return nil
        }

        let embeddingsArray: [Float] = (0..<embeddings.count).map { Float(embeddings[$0].floatValue) }

        return embeddingsArray
    }
}
