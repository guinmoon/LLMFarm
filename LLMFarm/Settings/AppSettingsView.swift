//
//  SettingsView.swift
//  LLMFarm
//
//  Created by guinmoon on 01.11.2023.
//

import SwiftUI


struct SettingsView: View {
    @EnvironmentObject var fineTuneModel: FineTuneModel
    @Binding var current_detail_view_name:String?
    @State var settings_menu_items = [
        ["icon":"square.stack.3d.up.fill","value":"Models","name":"Models"],
        //        ["icon":"square.stack.3d.up.fill","value":"LoRA","name":"LoRA Adepters"],
        //        ["icon":"square.stack.3d.up.fill","value":"Settings","name":"App Settings"]
    ]
    @State var tabIndex = 0
    
    var body: some View {
        HStack(spacing: 0){
            
            AppSettingTabs(index:$tabIndex)
            
            GeometryReader{_ in
                VStack{
                    
                        HStack{
                            Text("Settings")
                                .fontWeight(.semibold)
                                .font(.title2)
                        }
                        //                            .padding(.top)
                        //                            .padding(.horizontal)
                        .padding([.leading,.trailing],2)
                    
                    // changing tabs based on tabs...
                    switch tabIndex{
                    case 0:
                        ModelsView("models")
                        
                    case 1:
                        DownloadModelsView()
                    case 2:
                        About()
                        
                    default:
                        
                        ModelsView("models")
                        
                    }
                    
                    
                }
#if os(macOS)
                .padding(.top, topSafeAreaInset())
                .padding(.bottom, bottomSafeAreaInset())
#else
                .padding(.top, UIApplication.shared.keyWindow?.safeAreaInsets.top)
                .padding(.bottom, UIApplication.shared.keyWindow?.safeAreaInsets.bottom)
#endif
                .padding([.leading,.trailing],1)
                // due to all edges are ignored...
            }
            
        }
        .edgesIgnoringSafeArea(.all)
        
    }
}
