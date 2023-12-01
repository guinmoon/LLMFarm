//
//  ChatView.swift
//
//  Created by Guinmoon
//

import SwiftUI

struct ChatView: View {
    
    @EnvironmentObject var aiChatModel: AIChatModel
    @EnvironmentObject var orientationInfo: OrientationInfo
        
    #if os(iOS)
    var placeholderString: String = "Type your message..."
    @State private var inputText: String = "Type your message..."
    #else
    var placeholderString: String = ""
    @State private var inputText: String = ""
    #endif
    
    
    @Binding var model_name: String
    @Binding var chat_selection: String?
    @Binding var title: String
    var close_chat: () -> Void
    @Binding var add_chat_dialog:Bool
    @Binding var edit_chat_dialog:Bool
    @State private var reload_button_icon: String = "arrow.counterclockwise.circle"
    
    @State private var scrollProxy: ScrollViewProxy? = nil
    
    @State private var scrollTarget: Int?
    
    @Namespace var bottomID
    
    
    
    @FocusState
    private var isInputFieldFocused: Bool
    
    func scrollToBottom(with_animation:Bool = false) {
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
        print("\nreload\n")
        aiChatModel.stop_predict()
        await aiChatModel.prepare(model_name,chat_selection!)
        aiChatModel.messages = []
        aiChatModel.messages = load_chat_history(chat_selection!+".json")!
        aiChatModel.AI_typing = -Int.random(in: 0..<100000)
    }
    
    private func delayIconChange() {
        // Delay of 7.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            reload_button_icon = "arrow.counterclockwise.circle"
        }
    }
    
    var body: some View {
        VStack{
            if aiChatModel.state == .loading{
                Text("Model loading...")
                    .padding(.top, 5)
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
                    
                    HStack{
                        //#if os(macOS)
                        //                        DidEndEditingTextField(text: $inputText, didEndEditing: { input in})
                        //                                                           .frame( alignment: .leading)
                        ////#else
                        //                        TextField(placeholderString, text: $inputText,  axis: .vertical)
                        //                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        //                            .lineLimit(1...10)
                        TextEditor(text: $inputText)
                            .padding(.vertical, 6)
<<<<<<< HEAD
                            .padding(.leading, 5)
                            .lineSpacing(1)
=======
//                            .padding(.leading, 5)
                            .lineSpacing(8)
>>>>>>> 8060d5a (llama.cpp updated to b1575, its not final commit to this update)
                            .font(.system(.body))
                            .foregroundColor(inputText == placeholderString ? .gray : .primary)
                            .onTapGesture {
                                if inputText == placeholderString {
                                    inputText = ""
                                }
                            }
                        
                        //#endif
                        Button {
                            Task {
                                let text = inputText
                                inputText = placeholderString
                                if (aiChatModel.predicting){
                                    aiChatModel.stop_predict()
                                }else
                                {
                                    DispatchQueue.main.async {
                                        aiChatModel.send(message: text)
                                    }
                                }
                            }
                        } label: {
                            Image(systemName: aiChatModel.action_button_icon)
                        }
                        .padding(.horizontal, 6.0)
                        .disabled((inputText.isEmpty && !aiChatModel.predicting))
                        //                        .keyboardShortcut(.defaultAction)
#if os(macOS)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
#endif
                    }
                    .padding(.leading, 10)
                    .padding(.trailing, 5)
                    .padding(.bottom, 5)
                    .onChange(of: aiChatModel.AI_typing){ ai_typing in
                        //                .onChange(of: aiChatModel.messages.count){ count in
                        // Fix for theese https://developer.apple.com/forums/thread/712510
#if os(macOS)
                        if (aiChatModel.predicting){
                            scrollToBottom(with_animation: true)
                        }else{
                            scrollToBottom(with_animation: false)
                        }
#endif
                        if #available(iOS 16.4, *){
                            if (aiChatModel.predicting){
                                scrollToBottom(with_animation: true)
                            }else{
                                scrollToBottom(with_animation: false)
                            }
                        }
                    }
                    .frame(height:47)
                    .background(.regularMaterial)
                    //                .padding(.bottom)
                    //                .padding(.leading)
                    //                .padding(.trailing)
                }
                .navigationTitle($title)
                .toolbar {
                    Button {
                        Task {
                            self.aiChatModel.chat = nil
                            reload_button_icon = "checkmark"
                            delayIconChange()
                        }
                    } label: {
                        Image(systemName: reload_button_icon)
                    }
                    .disabled(aiChatModel.predicting)
                    //                .font(.title2)
                    
                    Button {
                        Task {
                            //                        add_chat_dialog = true
                            edit_chat_dialog = true
                            //                        chat_selection = nil
                        }
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                    //                .font(.title2)
                }
                .disabled(chat_selection == nil)
                .onAppear(){
                    scrollProxy = scrollView
#if os(macOS)
                    scrollToBottom(with_animation: false)
#endif
                    if #available(iOS 16.4, *) {
                        scrollToBottom(with_animation: false)
                    }
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
        }
    }
}

//struct ChatView_Previews: PreviewProvider {
//    static var previews: some View {
//        ChatView(chat_selected: .constant(true),model_name: .constant(""),chat_name:.constant(""),title: .constant("Title"),close_chat: {},add_chat_dialog:.constant(false),edit_chat_dialog:.constant(false))
//    }
//}
