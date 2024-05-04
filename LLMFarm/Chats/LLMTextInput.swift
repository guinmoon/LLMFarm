//
//  LLMTextInput.swift
//  LLMFarm
//
//  Created by guinmoon on 17.01.2024.
//

import SwiftUI
import PhotosUI

public struct MessageInputViewHeightKey: PreferenceKey {
    /// Default height of 0.
    ///
    public static var defaultValue: CGFloat = 0
    
    
    
    /// Writes the received value to the `PreferenceKey`.
    public static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}


/// View modifier to write the height of a `View` to the ``MessageInputViewHeightKey`` SwiftUI `PreferenceKey`.
extension View {
    func messageInputViewHeight(_ value: CGFloat) -> some View {
        self.preference(key: MessageInputViewHeightKey.self, value: value)
    }
}

#if os(macOS)
extension Image {
    @MainActor
    func getNSImage() -> NSImage? {
        let image = resizable()
            .scaledToFill()
        //            .frame(width: newSize.width, height: newSize.height)
            .clipped()
        return ImageRenderer(content: image).nsImage
    }
    //    func getNSImage() -> NSImage? {
    //        let image = resizable()
    //        return NSImage(data: image)
    //    }
}
#elseif os(iOS)

extension Image {
    @MainActor
         func getUIImage() -> UIImage? {
             let image = resizable()
     //            .scaledToFill()
     //        //            .frame(width: newSize.width, height: newSize.height)
     //            .clipped()
             return ImageRenderer(content: image).uiImage?.fixedOrientation
         }
//    func getUIImage() -> UIImage? {
//        let image = resizable()
//        return UIImage(data: image).fixedOrientation
//    }
    
}
#endif

public struct LLMTextInput: View {
    
    
    
    private let messagePlaceholder: String
    private let show_attachment_btn:Bool
    var focusedField: FocusState<Field?>.Binding
    @EnvironmentObject var aiChatModel: AIChatModel
    @State public var input_text: String = ""
    @State private var messageViewHeight: CGFloat = 0
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImageData: Data? = nil
    @State private var image: Image?
#if os(macOS)
    @State private var platformImage: NSImage?
#else
    @State private var platformImage: UIImage?
#endif
    @State public var img_cahce_path: String?
    @Binding private var auto_scroll:Bool
    
    //    @FocusState private var focusedField: Field?
    
    
    
    
    
    public var body: some View {
        HStack(alignment: .bottom) {
            if self.show_attachment_btn{
                if img_cahce_path != nil && platformImage != nil{
                    HStack{
#if os(macOS)
                        Image(nsImage:platformImage!)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 30,maxHeight: 40)
#else
                        Image(uiImage:platformImage!)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 30,maxHeight: 40)
//                            .clipShape(Circle())
#endif
                        // image!
                    }
                    .cornerRadius(5) /// make the background rounded
                    .overlay( /// apply a rounded border
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(.gray, lineWidth: 1)
                    )
                }
                Group {
                    attachButton
                }
                .frame(minWidth: 33)
                .padding(.leading, -22)
            }
            
            TextField(messagePlaceholder, text: $input_text, axis: .vertical)
                .textFieldStyle(.plain)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background {
                    RoundedRectangle(cornerRadius: 20)
#if os(macOS)
                        .stroke(Color(NSColor.systemGray), lineWidth: 0.2)
#else
                        .stroke(Color(UIColor.systemGray2), lineWidth: 0.2)
#endif
                        .background {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.white.opacity(0.1))
                        }
                        .padding(.trailing, -42)
                        .padding(.leading, self.show_attachment_btn ? 5: 0)
                    
                }
                .focused(focusedField, equals: .msg)
                .lineLimit(1...5)
            Group {
                sendButton
                    .disabled(disable_send())
            }
            .frame(minWidth: 33)
            
        }
        .padding(.horizontal, 16)
#if os(macOS)
        .padding(.top, 2)
#else
        .padding(.top, 6)
#endif
        .padding(.bottom, 10)
        .background(.thinMaterial)
        .background {
            GeometryReader { proxy in
                Color.clear
                    .onAppear {
                        messageViewHeight = proxy.size.height
                    }
                    .onChange(of: input_text) { msg in
                        messageViewHeight = proxy.size.height
                    }
            }
        }
        .messageInputViewHeight(messageViewHeight)
    }
    
    private func disable_send() -> Bool{
        if input_text.isEmpty &&
            !aiChatModel.predicting &&
            img_cahce_path == nil
        {
            return true
        }
        return false
    }
    
    private var sendButton: some View {
        
        
        
        Button(
            action: {
                sendMessageButtonPressed(img_path:img_cahce_path)
            },
            label: {
                Image(systemName: aiChatModel.action_button_icon)
                //                    .accessibilityLabel(String(localized: "SEND_MESSAGE", bundle: .module))
                    .font(.title2)
#if os(macOS)
                    .foregroundColor(disable_send() ? Color(.systemGray) : .accentColor)
#else
                    .foregroundColor(disable_send() ? Color(.systemGray5) : .accentColor)
#endif
            }
        )
        .buttonStyle(.borderless)
        .offset(x: -5, y: -7)
    }
    
    private var attachButton: some View {
        PhotosPicker(
            selection: $selectedPhoto,
            matching: .images
        ) {
            Image(systemName: "plus.circle")
        }
        .font(.title2)
        .buttonStyle(.borderless)
        .offset(x: 10, y: -7)
        .task(id: selectedPhoto)  {
            //            if selectedPhoto?.supportedContentTypes.first == .image {
            //            image = try? await selectedPhoto?.loadTransferable(type: Image.self)
            if let data = try? await selectedPhoto?.loadTransferable(type: Data.self) {
                selectedImageData = data
                if selectedImageData != nil {
#if os(macOS)
                    //                platformImage = image?.getNSImage()
                    platformImage = NSImage(data: selectedImageData!)
                    img_cahce_path = save_image_from_library_to_cache(platformImage)
#elseif os(iOS)
                    platformImage = UIImage(data: selectedImageData!)?.fixedOrientation
                    //                platformImage = image?.getUIImage()
                    img_cahce_path = save_image_from_library_to_cache(platformImage)
#endif
                }
            }
            
            
            //            }
        }
        //        Button(
        //            action: {
        //                print("clicked")
        //            },
        //            label: {
        //
        //                 Image(systemName: "plus.app")
        //                     .font(.title2)
        //                     .foregroundColor(.accentColor)
        //            }
        //        )
        //        .buttonStyle(.borderless)
        //            .offset(x: 5, y: -7)
    }
    
    /// - Parameters:
    ///   - chat: The chat that should be appended to.
    ///   - messagePlaceholder: Placeholder text that should be added in the input field
    public init(
        //        _ chat: Binding<Chat>,
        messagePlaceholder: String? = nil,
        show_attachment_btn: Bool,
        focusedField: FocusState<Field?>.Binding,
        auto_scroll: Binding<Bool>
    ) {
        //        self._chat = chat
        self.messagePlaceholder = messagePlaceholder ?? "Message"
        self.show_attachment_btn = show_attachment_btn
        self.focusedField = focusedField
        self._auto_scroll = auto_scroll
    }
    
    
    
    private func sendMessageButtonPressed(img_path: String?) {
        Task {
            if (aiChatModel.predicting){
                aiChatModel.stop_predict()
            }else
            {
                img_cahce_path = nil
                image = nil
                selectedPhoto = nil
                auto_scroll = true
                Task {
                    aiChatModel.send(message: input_text,img_path: img_path)
                    input_text = ""
                }
            }
        }
        
    }
    
}
//
//#Preview {
//    LLMTextInput()
//}
