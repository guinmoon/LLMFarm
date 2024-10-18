//
//  SettingsView.swift
//  LLMFarm
//
//  Created by guinmoon on 01.11.2023.
//

import SwiftUI


struct SettingsView: View {
    @EnvironmentObject var fineTuneModel: FineTuneModel
    let app_version = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
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
                        VStack{
                            HStack{
                                Text("Settings")
                                    .fontWeight(.semibold)
                                    .font(.title2)
                            }
//                            .padding(.top)
//                            .padding(.horizontal)
                            .padding([.leading,.trailing],2)
                        }
                        // changing tabs based on tabs...
                        switch tabIndex{
                        case 0:
                            ModelsView("models")

                        case 1:
                                DownloadModelsView()
//                        case 2:
//                            GroupBox(label:
//                                     Text("Models")
//                            ) {
//                                ModelsView("lora_adapters")
//                            }
                        default:
 
                                ModelsView("models")
                            
                        }
                        
                        VStack{
                            HStack{
                                Image("ava0_48")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 40))
                            }
                            .buttonStyle(.borderless)
                            .controlSize(.large)
                            Text("LLMFarm v\(app_version)\nAuthor Artem Savkin\n2024")
                                .font(.footnote)
                                .frame(maxWidth: .infinity)
                                .multilineTextAlignment(.center)
                            
                            
                        }.opacity(0.4)
                            .frame(maxWidth: .infinity,alignment: .center)
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
