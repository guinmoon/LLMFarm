//
//  LLMFarmApp.swift
//  LLMFarm
//
//  Created by guinmoon on 20.05.2023.
//

import SwiftUI

#if os(iOS) || os(watchOS) || os(tvOS)

extension UIDevice {
    var hasNotch: Bool {
        let bottom = UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0
        return bottom > 0
    }
}


final class OrientationInfo: ObservableObject {
    enum Orientation {
        case portrait
        case landscape
    }
    
    @Published var orientation: Orientation
    
    private var _observer: NSObjectProtocol?
    
    init() {
        // fairly arbitrary starting value for 'flat' orientations
        if UIDevice.current.orientation.isLandscape {
            self.orientation = .landscape
        }
        else {
            self.orientation = .portrait
        }
        
        // unowned self because we unregister before self becomes invalid
        _observer = NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification, object: nil, queue: nil) { [unowned self] note in
            guard let device = note.object as? UIDevice else {
                return
            }
            if device.orientation.isPortrait {
                self.orientation = .portrait
            }
            else if device.orientation.isLandscape {
                self.orientation = .landscape
            }
        }
    }
    
    deinit {
        if let observer = _observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
#else
final class OrientationInfo: ObservableObject {
    enum Orientation {
        case portrait
        case landscape
    }
    @Published var orientation: Orientation
    init() {
        self.orientation = .landscape
    }
    
    deinit {
    }
}
#endif


@main
struct LLMFarmApp: App {
    @State var chat_selected = false
    @State var add_chat_dialog = false
    @State var edit_chat_dialog = false
    @State var model_name = ""
    @State var chat_name = ""
    @State var title = ""
    @StateObject var aiChatModel = AIChatModel()
    @StateObject var orientationInfo = OrientationInfo()
    @State var isLandscape:Bool = false
    
    func close_chat() -> Void{
        aiChatModel.stop_predict()              
    }
//    var chat_view = nil
    
    var body: some Scene {        
        WindowGroup {
            if (orientationInfo.orientation == .landscape)
            {
                HStack {
                    if !add_chat_dialog{
                        ChatListView(tabSelection: .constant(1),
                                     chat_selected: $chat_selected,
                                     model_name:$model_name,
                                     chat_name:$chat_name,
                                     title: $title,
                                     add_chat_dialog:$add_chat_dialog,
                                     close_chat:close_chat,
                                     edit_chat_dialog:$edit_chat_dialog)
                            .frame(maxWidth: 260,maxHeight: .infinity)
                        //                        .border(Color.red, width: 1)
#if os(iOS) || os(watchOS) || os(tvOS)
                            .padding(.leading,UIDevice.current.hasNotch ? -40: 0)
#endif
                    }else{
                        if !edit_chat_dialog{
                            AddChatView(add_chat_dialog: $add_chat_dialog,
                                        edit_chat_dialog:.constant(false))
                            .frame(maxWidth: 260,maxHeight: .infinity)
                        //                        .border(Color.red, width: 1)
#if os(iOS) || os(watchOS) || os(tvOS)
                            .padding(.leading,UIDevice.current.hasNotch ? -40: 0)
#endif
                        }else{
                            AddChatView(add_chat_dialog: $add_chat_dialog,
                                        edit_chat_dialog:$edit_chat_dialog,
                                        chat_name: aiChatModel.chat_name)
                            .frame(maxWidth: 260,maxHeight: .infinity)
                        //                        .border(Color.red, width: 1)
#if os(iOS) || os(watchOS) || os(tvOS)
                            .padding(.leading,UIDevice.current.hasNotch ? -40: 0)
#endif
                        }
                    }
                    Divider()
                        .overlay(.gray)

                    ChatView(chat_selected: $chat_selected,
                             model_name: $model_name,
                             chat_name: $chat_name,
                             title: $title,
                             close_chat:close_chat,
                             add_chat_dialog:$add_chat_dialog,
                             edit_chat_dialog:$edit_chat_dialog).environmentObject(aiChatModel).environmentObject(orientationInfo)
                        .frame(maxWidth: .infinity,maxHeight: .infinity)
//                        .border(Color.red, width: 1)
                }
            }else{
                if (!chat_selected){
                    //                withAnimation(.easeInOut(duration: 2)) {
                    //                    //                ContentView(chat_selected: $chat_selected,model_name: $model_name)
                    //
                    //                }
                    if !add_chat_dialog{
                        ChatListView(tabSelection: .constant(1),
                                     chat_selected: $chat_selected,
                                     model_name:$model_name,
                                     chat_name:$chat_name,
                                     title: $title,
                                     add_chat_dialog:$add_chat_dialog,
                                     close_chat:close_chat,
                                     edit_chat_dialog:$edit_chat_dialog)
                    }else{
                        AddChatView(add_chat_dialog: $add_chat_dialog,
                                    edit_chat_dialog:$edit_chat_dialog)
                    }
                }
                else{
                    if !add_chat_dialog{
                        withAnimation() {
                            ChatView(chat_selected: $chat_selected,
                                     model_name: $model_name,
                                     chat_name: $chat_name,
                                     title: $title,close_chat:close_chat,
                                     add_chat_dialog: $add_chat_dialog,
                                     edit_chat_dialog:$edit_chat_dialog).environmentObject(aiChatModel).environmentObject(orientationInfo)
                        }
                    }
                    else{
                        if !edit_chat_dialog{
                            AddChatView(add_chat_dialog: $add_chat_dialog,
                                        edit_chat_dialog:.constant(false))
                        }else{
                            AddChatView(add_chat_dialog: $add_chat_dialog,
                                        edit_chat_dialog:$edit_chat_dialog,                                        
                                        chat_name: aiChatModel.chat_name)
                        }
                    }
                }
            }
        }        
    }
}
