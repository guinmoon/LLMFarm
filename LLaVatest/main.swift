//
//  main.swift
//  FineTune_Test
//
//  Created by guinmoon on 30.10.2023.
//

import Foundation
import llmfarm_core

let model_base = ""
let mmproj = ""
let image_path = ""

// ./llava-cli -m ../llava-v1.5-7b/ggml-model-f16.gguf --mmproj ../llava-v1.5-7b/mmproj-model-f16.gguf --image path/to/an/image.jpg
var args = ["progr_name", "-m", model_base, "--mmproj", mmproj, "--image", image_path, "-ngl","0"]

do{
    print(args)
    var cargs = args.map { strdup($0) }
    self.progressCallback = progressCallback
//        tuneQueue.async{
    self.retain_new_self_ptr()
    try ExceptionCather.catchException {
        let result = run_llava(Int32(args.count), &cargs,
                                    { c_str in
            let LLaMa_FineTune_obj = Unmanaged<LLaMa_FineTune>.fromOpaque(LLaMa_FineTune_obj_ptr!).takeRetainedValue()
            LLaMa_FineTune_obj.retain_new_self_ptr()    
            if c_str != nil{
                let for_print = String(cString:c_str!)
                LLaMa_FineTune_obj.tune_log.append(for_print)
                LLaMa_FineTune_obj.progressCallback!(for_print)
                print("\nProgress: \(for_print)")
            }
            return LLaMa_FineTune_obj.cancel
        })
    }
    for ptr in cargs { free(ptr) }
//        }
}
catch{
    print(error)
    throw error
}
