//
//  Math.swift
//  Mia
//
//  Created by Byron Everson on 2/17/23.
//

import Accelerate
import CoreML

class Math {
    
    // Argmax
    // Returns the index and value of the largest element in the array.
    static func argmax(_ probs: UnsafePointer<Float32>, _ c: Int) -> (Int, Float) {
        var maxValue: Float32 = 0
        var maxIndex: vDSP_Length = 0
        vDSP_maxvi(probs, 1, &maxValue, &maxIndex, vDSP_Length(c))
        return (Int(maxIndex), maxValue)
    }
    
    // Top-K
    // Select the k most-probable elements indices from array
    // Returns both the indices (from the original array) and their softmaxed probabilities.
    static func topK(_ probs: UnsafePointer<Float32>, _ c: Int, _ k: Int = 10) -> ([Int], [Float32]) {
        let probsBuffer = UnsafeBufferPointer(start: probs, count: c)
        let array = Array<Float32>(probsBuffer)
        let x = Array(array.enumerated().map { ($0, $1) }.sorted(by: { $0.1 > $1.1 }).prefix(through: min(k, array.count) - 1))
        let indexes = x.map { $0.0 }
        var probs = x.map { Float32($0.1) }
        softmax(probs.mutPtr, probs.count) // Next step after this will softmax the probs anyway
        return (indexes, probs)
    }
    
    // Chooses a random element from the top-k array, returns the corresponding index and prob within the top-k context
    static func randomK(_ indexedProbs: ([Int], [Float32])) -> (Int, Float32) {
        // Sum of all probabilities (so that we don't have to require that the sum is 1.0):
        let sum: Float32 = 1.0 //probs.reduce(0, +)
        // Random number in the range 0.0 <= rnd < sum :
        var rN = sum * (Float32(arc4random_uniform(UInt32.max)) / Float(UInt32.max))
        // Find the first interval of accumulated probabilities into which `rnd` falls
        for (i, p) in indexedProbs.1.enumerated() {
            if rN < p { return (indexedProbs.0[i], indexedProbs.1[i]) }
            rN -= p
        }
        // This point might be reached due to floating point inaccuracies:
        return (indexedProbs.0[0], indexedProbs.1[0]) //[(probs.count - 1)]
    }
    
    // Top-P
    // Sample from the top tokens with a cumulative probability just above a threshold (nucleus/top-p)
    /*static func topP(_ array: [Double], _ p: Float) -> Int {
        // Sort the input array in ascending order
        let x = array.enumerated().map { ($0, $1) }.sorted { $0.1 > $1.1 }
        let indexes = x.map { $0.0 }
        var probs = x.map { Float($0.1) }
        // Softmax for probability distribution
        softmax(probs.mutPtr, probs.count)
        // Random number in the range 0.0 <= rnd < sum :
        var rN = p * (Float(arc4random_uniform(UInt32.max)) / Float(UInt32.max))
        for (i, prob) in probs.enumerated() {
            if rN < prob { return indexes[i] }
            rN -= prob
        }
        // This point might be reached due to floating point inaccuracies:
        return indexes[(probs.count - 1)]
    }*/
    
    /* Uses subtract max "trick"
     def softmax(X):
         exps = np.exp(X - np.max(X))
         return exps / np.sum(exps)
     */
    // Huggingface softmax function in swift
    static func softmax(_ x: UnsafeMutablePointer<Float32>, _ c: Int, _ temperature: Float32 = 1.0) {
        let c_vDSP = vDSP_Length(c)
        // Temperature (increase/decrease entropy), divide by temp
        //var recip_temp = 1.0 / temperature
        //vDSP_vsmul(x, 1, &recip_temp, x, 1, c_vDSP)
        var temp = temperature
        vDSP_vsdiv(x, 1, &temp, x, 1, c_vDSP)
        // Subtract by max trick (same as used by huggingface gpt2 trick, although other tricks can be used)
        var max: Float32 = 0
        vDSP_maxv(x, 1, &max, c_vDSP)
        var neg_max = -max
        vDSP_vsadd(x, 1, &neg_max, x, 1, c_vDSP)
        // Exponentiate all the elements in the array
        var c_vv = Int32(c)
        vvexpf(x, x, &c_vv)
        // Compute the sum of all exponentiated values
        var sumExp: Float32 = 0
        vDSP_sve(x, 1, &sumExp, c_vDSP)
        // Divide exps by sum of exps
        //var recip_sumExp = 1.0 / sumExp
        //vDSP_vsmul(x, 1, &recip_sumExp, x, 1, c_vDSP)
        vDSP_vsdiv(x, 1, &sumExp, x, 1, c_vDSP)
    }
    
    // Multinomial sampling
    // From https://stackoverflow.com/questions/30309556/generate-random-numbers-with-a-given-distribution
    /*static func randomNumber(probabilities: [Float]) -> Int {
        // Sum of all probabilities (so that we don't have to require that the sum is 1.0):
        let sum = probabilities.reduce(0, +)
        // Random number in the range 0.0 <= rnd < sum :
        let rnd = sum * Float(arc4random_uniform(UInt32.max)) / Float(UInt32.max)
        // Find the first interval of accumulated probabilities into which `rnd` falls:
        var accum: Float = 0.0
        for (i, p) in probabilities.enumerated() {
            accum += p
            if rnd < accum {
                return i
            }
        }
        // This point might be reached due to floating point inaccuracies:
        return (probabilities.count - 1)
    }*/
    
    // Gelu new (tanh appr)
    // 0.5x(1+tanh(sqrt(2/pi)(x+0.044715x^3)))
    static func geluApprTanh(_ x: UnsafeMutablePointer<Float>, _ c: Int) {
        let c_vDSP = vDSP_Length(c)
        var c_vv = Int32(c)
        let y = UnsafeMutablePointer<Float>.allocate(capacity: c) //
        //let yA = [Float](repeating: 0, count: c)
        //let y = yA.mutPtr
        vDSP_vmul(x, 1, x, 1, y, 1, c_vDSP) // x^2
        vDSP_vmul(y, 1, x, 1, y, 1, c_vDSP) // x^3
        var cubed_scalar: Float = 0.044715
        vDSP_vsmul(y, 1, &cubed_scalar, y, 1, c_vDSP) // 0.044715x^3
        vDSP_vadd(y, 1, x, 1, y, 1, c_vDSP) // x+0.044715x^3
        var tanh_appr: Float = 0.7978845608 // sqrt(2/pi)
        vDSP_vsmul(y, 1, &tanh_appr, y, 1, c_vDSP) // sqrt(2/pi)(x+0.044715x^3)
        vvtanhf(y, y, &c_vv) // tanh(sqrt(2/pi)(x+0.044715x^3))
        var one: Float = 1.0
        vDSP_vsadd(y, 1, &one, y, 1, c_vDSP) // (1+tanh(sqrt(2/pi)(x+0.044715x^3)))
        vDSP_vmul(y, 1, x, 1, y, 1, c_vDSP) // x(1+tanh(sqrt(2/pi)(x+0.044715x^3)))
        var half: Float = 0.5
        vDSP_vsmul(y, 1, &half, x, 1, c_vDSP) // 0.5x(1+tanh(sqrt(2/pi)(x+0.044715x^3)))
    }
    
    // Gelu appr using sigmoid
    static func geluApprSig(_ x: UnsafeMutablePointer<Float>, _ c: Int) {
        let c_vDSP = vDSP_Length(c)
        var c_vv = Int32(c)
        //var yA = [Float](repeating: 0, count: c)
        //let y = yA.mutPtr
        let y = UnsafeMutablePointer<Float>.allocate(capacity: c)
        var sigScale: Float = -1.702
        vDSP_vsmul(y, 1, &sigScale, y, 1, c_vDSP) // -1.702x
        vvexpf(y, y, &c_vv) // e^-1.702x
        var one: Float = 1.0
        vDSP_vsadd(y, 1, &one, y, 1, c_vDSP) // (1+e^-1.702x)
        vvrecf(y, y, &c_vv) // 1/(1+e^-1.702x) aka sigmoid(1.702x)
        vDSP_vmul(y, 1, x, 1, y, 1, c_vDSP) // x(sigmoid(1.702x)
    }
    
    // Layer normalization, equivalent to huggingface gpt-2 version
    static func meanVarianceNormalize(_ x: UnsafePointer<Float32>,
                               _ y: UnsafeMutablePointer<Float32>,
                               _ c: Int,
                               _ epsilon: Float32) {
        let c_vDSP = vDSP_Length(c)
        
        // Compute the mean of the input vector
        var mean: Float32 = 0
        vDSP_meanv(x, 1, &mean, c_vDSP)
        
        // Compute the variance of the input vector
        /*var neg_mean = -mean
        vDSP_vsadd(x, 1, &neg_mean, y, 1, c_vDSP)
        var sum_sq_dev: Float = 0
        vDSP_svesq(y, 1, &sum_sq_dev, c_vDSP)
        let variance = sum_sq_dev / Float(c - 1)*/
        
        //variance = torch.mean(torch.square(input - mean), dim=normalized_shape, keepdim=True)
        var neg_mean = -mean
        vDSP_vsadd(x, 1, &neg_mean, y, 1, c_vDSP)
        var variance: Float32 = 0
        vDSP_measqv(y, 1, &variance, c_vDSP)
        
        // Apply the layer normalization to the input vector, y = (x - mean) / sqrt(variance + epsilon)
        var sqrt_variance = 1 / sqrtf(variance + epsilon)
        vDSP_vsmul(y, 1, &sqrt_variance, y, 1, c_vDSP)
    }

    // Conv1D operation from Hugginface
    /**
        1D-convolutional layer as defined by Radford et al. for OpenAI GPT (and also used in GPT-2).

        Basically works like a linear layer but the weights are transposed.

        Args:
            ny (:obj:`int`): The number of output features.
            nx (:obj:`int`): The number of input features.
    **/
    
    /*
    func conv1d(_ x: UnsafePointer<Float>,
                _ y: UnsafeMutablePointer<Float>,
                _ nx: Int, // e.g. contextSize for QKV,
                _ ny: Int, // e.g. 3 x contextSize for QKV
                _ weight: UnsafePointer<Float>, // Should be (nx, ny)
                _ bias: UnsafePointer<Float>) {
        
        //var weight = [Float](repeating: 0, count: nx * nf)
        //var bias = [Float](repeating: 0, count: nf)
        var std: Float = 0.02

        // compute output size
        var size_out = [Int](x.count-1) + [nf]

        // compute matrix multiplication and add bias
        var out = [Float](repeating: 0, count: size_out.reduce(1, *))
        let N = x.count
        let K = nf
        let alpha: Float = 1
        let beta: Float = 1
        let lda = K
        let ldb = N
        let ldc = K
        vDSP_mmul(weight, 1, x, 1, &out, 1, UInt(K), UInt(N), UInt(1))
        vDSP_vadd(out, 1, bias, 1, &out, 1, UInt(K))

        // reshape output tensor
        let size = [nx] + size_out.dropLast()
        var reshaped_out = [Float](repeating: 0, count: size.reduce(1, *))
        vDSP_mmov(&out, &reshaped_out, UInt(K), UInt(N), UInt(nf), UInt(size_out.dropLast().reduce(1, *)), UInt(size_out.last!), UInt(size_out.reduce(1, *)))

        return reshaped_out
    }
     */
    
    
}

