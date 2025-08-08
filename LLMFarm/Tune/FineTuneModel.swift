//
//  ChatViewModel.swift
//  AlpacaChatApp
//
//  Created by Yoshimasa Niwa on 3/19/23.
//

import Foundation
import SwiftUI
import llmfarm_core

private extension Duration {
    var seconds: Double {
        Double(components.seconds) + Double(components.attoseconds) / 1.0e18
    }
}

public func parse_finetune_log_to_iter_num(_ log_str:String) -> Int{
//    "train_opt_callback: iter=     0 sample=1/26766 sched=0.000000 loss=0.000000"
    var progress = -1
    if let b_index = log_str.endIndex(of: "iter=") {
        if let e_index = log_str.index(of: " sample=") {
            let substring = log_str[b_index...e_index]   // ab
            let iter_str = String(substring).trimmingCharacters(in: .whitespacesAndNewlines)
            return Int(iter_str) ?? -1
        }
    }
    return progress
}

//@MainActor
final class FineTuneModel: ObservableObject {
    enum State {
        case none
        case loading
        case tune
        case export
        case cancel
        case completed
    }
    @Published var state: State = .none
    @Published  var model_file_url: URL = URL(filePath: "/")
    @Published  var model_file_path: String = "Select model"
    @Published  var dataset_file_url: URL = URL(filePath: "/")
    @Published  var dataset_file_path: String = "Select dataset"
    @Published  var export_model_name: String = ""
    @Published  var lora_name: String = ""
    @Published  var lora_file_path: String = "Select Adapter"
    @Published  var lora_file_url: URL = URL(filePath: "/")
    @Published  var n_ctx: Int32 = 64
    @Published  var n_batch: Int32 = 4
    @Published  var adam_iter: Int32 = 30
    @Published  var n_threads: Int32 = 0
    @Published  var use_metal: Bool = false
    @Published  var use_checkpointing: Bool = true
    @Published  var tune_log: String = ""
    @Published  var lora_scale: Double = 1.0
    @Published  var progress = 0.0
    public  var llama_finetune:LLaMa_FineTune? = nil
    
    var tuneQueue = DispatchQueue(label: "LLMFarm-Tune", qos: .userInitiated, attributes: .concurrent, autoreleaseFrequency: .inherit, target: nil)
    
    public func finetune() async {
        Task{
            self.tune_log = ""
            self.state = .loading
            let documents_path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            let model_path = get_path_by_short_name(model_file_path,dest:"models")
            if (model_path == nil || documents_path == nil){
                return
            }
            _ = get_path_by_short_name(lora_name,dest:"lora_adapters")
            let lora_path:String = String(documents_path!.appendingPathComponent("lora_adapters").path(percentEncoded: true) + lora_name)
//            try! lora_path.write(to: URL(fileURLWithPath: lora_path), atomically: true, encoding: String.Encoding.utf8)
            print("Lora_path: \(lora_path)")
            let dataset_path = get_path_by_short_name(dataset_file_path,dest:"datasets")
            if dataset_path == nil{
                return
            }
            llama_finetune = LLaMa_FineTune(model_path!,lora_path,dataset_path!,threads: 
                                                n_threads, adam_iter: adam_iter,batch: n_batch,ctx: n_ctx,
                                            use_checkpointing: use_checkpointing, use_metal: use_metal)
            self.state = .tune
            self.progress = 0.0
            tuneQueue.async{
                do{
                    try self.llama_finetune!.finetune(
                    { progress_str in
                        DispatchQueue.main.async {
                            self.tune_log += "\n\(progress_str)"
                            let tmp_progress = parse_finetune_log_to_iter_num(progress_str)
                            if tmp_progress > 0{
                                self.progress = Double(tmp_progress) / Double(self.adam_iter)
                            }
                            if self.llama_finetune?.cancel == true
                            {
                                self.state = .completed
                                self.llama_finetune = nil
                            }
                        }
                    })
                }
                catch{
                    DispatchQueue.main.async {
                        self.tune_log += "\nERROR: \(error)"
                        self.state = .completed
                    }
                    return
                }
                DispatchQueue.main.async {
                    self.state = .completed
                }
            }
            
        }
    }
    
    public func export_lora() async {
        Task{
            self.tune_log = ""
            self.state = .loading
            let documents_path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            let model_path = get_path_by_short_name(model_file_path,dest:"models")
            if (model_path == nil || documents_path == nil){
                return
            }
            _ = get_path_by_short_name(lora_name,dest:"lora_adapters")
            let lora_path:String = String(documents_path!.appendingPathComponent("lora_adapters").path(percentEncoded: true) + lora_file_path)
            let export_model_path:String = String(documents_path!.appendingPathComponent("models").path(percentEncoded: true) + export_model_name)
//            try! lora_path.write(to: URL(fileURLWithPath: lora_path), atomically: true, encoding: String.Encoding.utf8)
            print("Lora_path: \(export_model_path)")
    
            llama_finetune = LLaMa_FineTune(model_path!,lora_path,"",threads:n_threads,export_model: export_model_path )
            self.state = .export
            self.progress = 0
            tuneQueue.async{
                do{
                    try self.llama_finetune!.export_lora(
                    { progress in
                        DispatchQueue.main.async {
                            self.progress = progress
                        }
                    })
                }
                catch{
                    DispatchQueue.main.async {
                        self.state = .completed
                    }
                    return
                }
                DispatchQueue.main.async {
                    self.state = .completed
                }
            }
            
        }
    }
    
    public func cancel_finetune() async {
        self.llama_finetune?.cancel = true        
        self.state = .cancel
    }
}
