//
//  ChatView.swift
//
//  Created by Guinmoon
//

import SwiftUI

struct ChatView: View {
    
    @EnvironmentObject var aiChatModel: AIChatModel
    @EnvironmentObject var orientationInfo: OrientationInfo
    
// #if os(iOS)
    @State var placeholderString: String = "Type your message..."
    @State private var inputText: String = "Type your message..."
// #else
//     @State var placeholderString: String = ""
//     @State private var inputText: String = ""
// #endif

    
    @Binding var model_name: String
    @Binding var chat_selection: Dictionary<String, String>?
    @Binding var title: String
    var close_chat: () -> Void
    @Binding var add_chat_dialog:Bool
    @Binding var edit_chat_dialog:Bool
    @State private var reload_button_icon: String = "arrow.counterclockwise.circle"
    @State private var clear_chat_button_icon: String = "eraser.line.dashed.fill"
    
    @State private var scrollProxy: ScrollViewProxy? = nil
    
    @State private var scrollTarget: Int?
    @State private var toggleEditChat = false
    @State private var clearChatAlert = false    
    
    @State private var auto_scroll = true

    @FocusState var focusedField: Field?
    
    @Namespace var bottomID
    
    
    
    @FocusState
    private var isInputFieldFocused: Bool
    
    func scrollToBottom(with_animation:Bool = false) {
        var scroll_bug = true
#if os(macOS)
        scroll_bug = false
#else
        if #available(iOS 16.4, *){
            scroll_bug = false
        }
#endif
        if scroll_bug {
            return
        }
        if !auto_scroll {
            return
        }
        let last_msg = aiChatModel.messages.last // try to fixscrolling and  specialized Array._checkSubscript(_:wasNativeTypeChecked:)
        if last_msg != nil && last_msg?.id != nil && scrollProxy != nil{
            if with_animation{
                withAnimation {
                    //                    scrollProxy?.scrollTo(last_msg?.id, anchor: .bottom)
                    scrollProxy?.scrollTo("latest")
                }
            }else{
                //                scrollProxy?.scrollTo(last_msg?.id, anchor: .bottom)
                scrollProxy?.scrollTo("latest")
            }
        }
        
    }
    
    func reload() async{
        if chat_selection == nil {
            return
        }
                
        print(chat_selection)
        print("\nreload\n")
        aiChatModel.reload_chat(chat_selection!)
//         aiChatModel.stop_predict()
// //        await aiChatModel.prepare(model_name,chat_selection!)
//         aiChatModel.model_name = model_name        
//         aiChatModel.chat_name = chat_selection!["chat"] ?? "Not selected"
// //        title = chat_selection!["title"] ?? ""
//         aiChatModel.Title = chat_selection!["title"] ?? ""
//         aiChatModel.messages = []
//         aiChatModel.messages = load_chat_history(chat_selection!["chat"]!+".json")!
//         aiChatModel.AI_typing = -Int.random(in: 0..<100000)
    }
    
    
    private var starOverlay: some View {
        
        Button {
            Task{
                auto_scroll = true
                scrollToBottom()                
            }
        }
        
    label: {
        Image(systemName: "arrow.down.circle")
            .resizable()
            .foregroundColor(.white)
            .frame(width: 25, height: 25)
            .padding([.bottom, .trailing], 15)
            .opacity(0.4)
    }
    .buttonStyle(BorderlessButtonStyle())
    }
    
    
    
    var body: some View {
        VStack{
            VStack{
                if aiChatModel.state == .loading{
                    VStack {
//                        Text("Model loading...")
//                            .padding(.top, 5)
//                            .frame(width: .infinity)
//                            .background(.regularMaterial)
                        ProgressView(value: aiChatModel.load_progress)
                    }
                }
            }
            ScrollViewReader { scrollView in
                VStack {
                    List {
                        ForEach(aiChatModel.messages, id: \.id) { message in
                            MessageView(message: message).id(message.id)
                        }
                        .listRowSeparator(.hidden)
                        Text("").id("latest")
                    }
                    .listStyle(PlainListStyle())
                    .overlay(starOverlay, alignment: .bottomTrailing)
                }
                .onChange(of: aiChatModel.AI_typing){ ai_typing in
                    scrollToBottom(with_animation: false)
                }
                
                
                .disabled(chat_selection == nil)
                .onAppear(){
                    scrollProxy = scrollView
                    scrollToBottom(with_animation: false)                    
                }
            }
            .frame(maxHeight: .infinity)
            .disabled(aiChatModel.state == .loading)
            .onChange(of: chat_selection) { chat_name in
                Task {
                    if chat_name == nil{
                        close_chat()
                    }
                    else{
                        //                    isInputFieldFocused = true
                        await self.reload()
                    }
                }
            }
            .onTapGesture { location in
                print("Tapped at \(location)")
                focusedField = nil
                auto_scroll = false
            }
            .toolbar {
                Button {
                    Task {
                        clearChatAlert = true
                    }
                } label: {
                    Image(systemName: clear_chat_button_icon)
                }
                .alert("Are you sure?", isPresented: $clearChatAlert, actions: {
                    Button("Cancel", role: .cancel, action: {})
                    Button("Clear", role: .destructive, action: {
                        aiChatModel.messages = []
                        save_chat_history(aiChatModel.messages,aiChatModel.chat_name+".json")
                        clear_chat_button_icon = "checkmark"
                        self.aiChatModel.chat = nil
                        run_after_delay(delay:1200, function:{clear_chat_button_icon = "eraser.line.dashed.fill"})
                    })
                }, message: {
                    Text("The message history will be cleared")
                })
                Button {
                    Task {
                        self.aiChatModel.chat = nil
                        reload_button_icon = "checkmark"
                        run_after_delay(delay:1200, function:{reload_button_icon = "arrow.counterclockwise.circle"})
//                        delayIconChange()
                    }
                } label: {
                    Image(systemName: reload_button_icon)
                }
                .disabled(aiChatModel.predicting)
                //                .font(.title2)
                Button {
                    Task {
                                            //    add_chat_dialog = true
                        toggleEditChat = true
                        edit_chat_dialog = true
                        //                        chat_selection = nil
                    }
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }
                //                .font(.title2)
            }
            .navigationTitle(aiChatModel.Title)
            
            LLMTextInput(messagePlaceholder: placeholderString,
                         show_attachment_btn:self.aiChatModel.is_mmodal,
                         focusedField:$focusedField,
                         auto_scroll:$auto_scroll).environmentObject(aiChatModel)
                .disabled(self.aiChatModel.chat_name == "")
//            .focused($focusedField, equals: .firstName)
            
        }
        .sheet(isPresented: $toggleEditChat) {
            AddChatView(add_chat_dialog: $toggleEditChat,
                        edit_chat_dialog: $edit_chat_dialog,
                        chat_name: aiChatModel.chat_name,
                        renew_chat_list: .constant({}),
                        toggleSettings: .constant(false)).environmentObject(aiChatModel)
#if os(macOS)
                .frame(minWidth: 400,minHeight: 600)
#endif
        }
    }
}

//struct ChatView_Previews: PreviewProvider {
//    static var previews: some View {
//        ChatView(chat_selected: .constant(true),model_name: .constant(""),chat_name:.constant(""),title: .constant("Title"),close_chat: {},add_chat_dialog:.constant(false),edit_chat_dialog:.constant(false))
//    }
//}
