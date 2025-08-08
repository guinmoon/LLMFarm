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
    
    @Binding var modelName: String
    @Binding var chatSelection: Dictionary<String, String>?
    @Binding var title: String
    var CloseChat: () -> Void
    @Binding var AfterChatEdit: () -> Void 
    @Binding var addChatDialog:Bool
    @Binding var editChatDialog:Bool
    @State var chatStyle: String = "None"
    @State private var reloadButtonIcon: String = "arrow.counterclockwise.circle"
    @State private var clearChatButtonIcon: String = "eraser.line.dashed.fill"
    
    @State private var scrollProxy: ScrollViewProxy? = nil
    
    @State private var scrollTarget: Int?
    @State private var toggleEditChat = false
    @State private var clearChatAlert = false    
    
    @State private var autoScroll = true
    @State private var enableRAG = false

    @FocusState var focusedField: Field?
    
    @Namespace var bottomID
    
//    func after_chat_edit_func(){
//        aiChatModel.update_chat_params()
//    }
    
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
        if !autoScroll {
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
        if chatSelection == nil {
            return
        }                
        print(chatSelection)
        print("\nreload\n")
        aiChatModel.reload_chat(chatSelection!)
    }
    
    func hard_reload_chat(){
        self.aiChatModel.hard_reload_chat()
    }
    
    private var scrollDownOverlay: some View {
        
        Button {
            Task{
                autoScroll = true
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
    
    private var debugOverlay: some View {
        Text(String(describing: aiChatModel.state))
            .foregroundColor(.white)
            .frame(width: 185, height: 25)
//            .padding([.top, .leading], 5)
            .opacity(0.4)
    }
    
    
    var body: some View {
        VStack{
            VStack{
                if aiChatModel.state == .loading || 
                    aiChatModel.state == .ragIndexLoading ||
                    aiChatModel.state == .ragSearch{
                    VStack {
                        HStack{
                            Text(String(describing: aiChatModel.state))
                                .foregroundColor(.accentColor)
                                .frame(width: 200 /*,height: 25*/)
                    //            .padding([.top, .leading], 5)
                                .opacity(0.4)
                                .offset(x: -75,y: 8)
                                .frame(alignment: .leading)
                                .font(.footnote)
                            ProgressView(value: aiChatModel.load_progress)
                                .padding(.leading,-195)
                                .offset(x: 0,y: -4)
                        }
                    }
                }
            }
            ScrollViewReader { scrollView in
                VStack {
                    List {
                        ForEach(aiChatModel.messages, id: \.id) { message in
                            MessageView(message: message, chatStyle: $chatStyle,status: nil ).id(message.id)
                                .textSelection(.enabled)
                        }
                        .listRowSeparator(.hidden)
                        Text("").id("latest")
//                        Divider()
//                        Button {
//                            Task{
//                                aiChatModel.RegenerateLstMessage()
//                            }
//                        }
//                        label: {
//                            Image(systemName: "arrow.uturn.backward.square")
//                                .resizable()
//                                .foregroundColor(.white)
//                                .frame(width: 25, height: 25)
////                                .padding([.bottom, .trailing], 15)
//                                .opacity(0.4)
//                            Text("Regenerate last message")
//                        }
//                        .buttonStyle(BorderlessButtonStyle())
//                        .id("latest")
                        
                    }
                    .textSelection(.enabled)
                    .listStyle(PlainListStyle())
                    .overlay(scrollDownOverlay, alignment: .bottomTrailing)
//                    .overlay(debugOverlay, alignment: .bottomLeading)
                    
                    
                    
                }
                .textSelection(.enabled)
                .onChange(of: aiChatModel.AI_typing){ ai_typing in
                    scrollToBottom(with_animation: false)
                }
                
                
                .disabled(chatSelection == nil)
                .onAppear(){
                    scrollProxy = scrollView
//                    after_chat_edit = after_chat_edit_func
                    scrollToBottom(with_animation: false)
                }
            }
            .textSelection(.enabled)
            .frame(maxHeight: .infinity)
            .disabled(aiChatModel.state == .loading)
            .onChange(of: chatSelection) { selection in
                Task {
                    if selection == nil{
                        CloseChat()
                    }
                    else{
                        print(selection)
                        chatStyle = selection!["chat_style"] as String? ?? "none"
                        await self.reload()
                    }
                }
            }
            .onTapGesture { location in
                print("Tapped at \(location)")
                focusedField = nil
                autoScroll = false
            }
            .toolbar {
                Button {
                    Task {
                        clearChatAlert = true
                    }
                } label: {
                    Image(systemName: clearChatButtonIcon)
                }
                .alert("Are you sure?", isPresented: $clearChatAlert, actions: {
                    Button("Cancel", role: .cancel, action: {})
                    Button("Clear", role: .destructive, action: {
                        aiChatModel.messages = []
                        save_chat_history(aiChatModel.messages,aiChatModel.chat_name+".json")
                        clearChatButtonIcon = "checkmark"
                        hard_reload_chat()
                        run_after_delay(delay:1200, function:{clearChatButtonIcon = "eraser.line.dashed.fill"})
                    })
                }, message: {
                    Text("The message history will be cleared")
                })
                Button {
                    Task {
                        hard_reload_chat()
                        reloadButtonIcon = "checkmark"
                        run_after_delay(delay:1200, function:{reloadButtonIcon = "arrow.counterclockwise.circle"})
//                        delayIconChange()
                    }
                } label: {
                    Image(systemName: reloadButtonIcon)
                }
                .disabled(aiChatModel.predicting)
                //                .font(.title2)
                Button {
                    Task {
                                            //    add_chat_dialog = true
                        toggleEditChat = true
                        editChatDialog = true
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
                         auto_scroll:$autoScroll,
                         enableRAG:$enableRAG).environmentObject(aiChatModel)
                .disabled(self.aiChatModel.chat_name == "")
//            .focused($focusedField, equals: .firstName)
            
        }
        .sheet(isPresented: $toggleEditChat) {
            ChatSettingsView(add_chat_dialog: $toggleEditChat,
                        edit_chat_dialog: $editChatDialog,
                        chat_name: aiChatModel.chat_name,
                        after_chat_edit: $AfterChatEdit,
                        toggleSettings: .constant(false)).environmentObject(aiChatModel)
#if os(macOS)
                .frame(minWidth: 400,minHeight: 600)
#endif
        }
        .textSelection(.enabled)
    }
}

//struct ChatView_Previews: PreviewProvider {
//    static var previews: some View {
//        ChatView(chat_selected: .constant(true),model_name: .constant(""),chat_name:.constant(""),title: .constant("Title"),close_chat: {},add_chat_dialog:.constant(false),edit_chat_dialog:.constant(false))
//    }
//}
