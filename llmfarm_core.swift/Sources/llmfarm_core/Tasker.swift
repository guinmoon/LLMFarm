//
//  Tasker.swift
//  Mia
//
//  Created by Byron Everson on 3/2/23.
//

import Foundation
//import MetalKit

class Tasker {
    
    // MARK: Multi-tasking
    
    // Each sub-branch must be done on a different queue to prevent locked queue
    static let taskerQueue = DispatchQueue(label: "Mia-Task", qos: .utility, attributes: .concurrent)
    
    // Performs the task, count number of times, supplies task with the index
    static func branch(_ count: Int, _ task: @escaping ((Int)->()) ) {
        let group = DispatchGroup()
        for i in 0 ..< count {
            group.enter()
            taskerQueue.async {
                task(i)
                group.leave()
            }
        }
        group.wait()
    }
    
    // Allows for grouping, as having thousands of tasks also might have drawbacks
    static func branchGroup(_ count: Int, _ grouping: Int = 8, _ task: @escaping ((Int)->()) ) {
        let group = DispatchGroup()
        let gc = count / grouping
        for i in 0 ..< gc {
            group.enter()
            taskerQueue.async {
                let g = i * grouping
                for j in 0 ..< grouping {
                    task(g + j)
                }
                group.leave()
            }
        }
        group.wait()
    }
    
    
    // MARK: Metal compute
    /*
    
    private static var encoder: MTLComputeCommandEncoder!
    private static var commandBuffer: MTLCommandBuffer!
    
    private static func computeInit() {
        // Device
        let device = MTLCreateSystemDefaultDevice()!
        let commandQueue = device.makeCommandQueue()!
        let library = try! device.makeLibrary(filepath: "compute.metallib")
        // Pipeline
        let commandBuffer = commandQueue.makeCommandBuffer()!
        encoder = commandBuffer.makeComputeCommandEncoder()!
        encoder.setComputePipelineState(try! device.makeComputePipelineState(function: library.makeFunction(name: "add")!))
        
    }
    
    static func compute(_ a: [Float], _ b: [Float], _ c: [Float]) {
        // Set Data
        let input: [Float] = [1.0, 2.0]
        encoder.setBuffer(
            device.makeBuffer(bytes: input as [Float],
                              length: MemoryLayout<Float>.stride * input.count,
                              options: []),
            offset: 0, index: 0)
        let outputBuffer = device.makeBuffer(length: MemoryLayout<Float>.stride, options: [])!
        encoder.setBuffer(outputBuffer, offset: 0, index: 1)
        // Run Kernel
        let numThreadgroups = MTLSize(width: 1, height: 1, depth: 1)
        let threadsPerThreadgroup = MTLSize(width: 1, height: 1, depth: 1)
        encoder.dispatchThreadgroups(numThreadgroups, threadsPerThreadgroup: threadsPerThreadgroup)
        encoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        // Results
        let result = outputBuffer.contents().load(as: Float.self)
        print(String(format: "%f + %f = %f", input[0], input[1], result))
    }
     
     */
}

