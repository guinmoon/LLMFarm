//
//  SplitViews.swift
//  LLMFarm
//
//  Created by guinmoon on 03.07.2023.
//

import Foundation
import SwiftUI

fileprivate struct SplitView<P: View, S: View>: View {
    private let layout: Layout
    private let zIndex: Double
    @Binding var fraction: CGFloat
    @Binding var secondaryHidden: Bool
    private let primary: P
    private let secondary: S
    private let visibleThickness: CGFloat = 2
    private let invisibleThickness: CGFloat = 30
    @State var overallSize: CGSize = .zero
    @State var primaryWidth: CGFloat?
    @State var primaryHeight: CGFloat?

    var hDrag: some Gesture {
        // As we drag the Splitter horizontally, adjust the primaryWidth and recalculate fraction
        DragGesture()
            .onChanged { gesture in
                primaryWidth = gesture.location.x
                fraction = gesture.location.x / overallSize.width
            }
    }

    var vDrag: some Gesture {
        // As we drag the Splitter vertically, adjust the primaryHeight and recalculate fraction
        DragGesture()
            .onChanged { gesture in
                primaryHeight = gesture.location.y
                fraction = gesture.location.y / overallSize.height
            }
    }

    enum Layout: CaseIterable {
        /// The orientation of the primary and seconday views (e.g., Vertical = VStack, Horizontal = HStack)
        case Horizontal
        case Vertical
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            switch layout {
            case .Horizontal:
                // When we init the view, primaryWidth is nil, so we calculate it from the
                // fraction that was passed-in. This lets us specify the location of the Splitter
                // when we instantiate the SplitView.
                let pWidth = primaryWidth ?? width()
                let sWidth = overallSize.width - pWidth - visibleThickness
                primary
                    .frame(width: pWidth)
                secondary
                    .frame(width: sWidth)
                    .offset(x: pWidth + visibleThickness, y: 0)
                Splitter(orientation: .Vertical, visibleThickness: visibleThickness)
                    .frame(width: invisibleThickness, height: overallSize.height)
                    .position(x: pWidth + visibleThickness / 2, y: overallSize.height / 2)
                    .zIndex(zIndex)
                    .gesture(hDrag, including: .all)
            case .Vertical:
                // When we init the view, primaryHeight is nil, so we calculate it from the
                // fraction that was passed-in. This lets us specify the location of the Splitter
                // when we instantiate the SplitView.
                let pHeight = primaryHeight ?? height()
                let sHeight = overallSize.height - pHeight - visibleThickness
                primary
                    .frame(height: pHeight)
                secondary
                    .frame(height: sHeight)
                    .offset(x: 0, y: pHeight + visibleThickness)
                Splitter(orientation: .Horizontal, visibleThickness: visibleThickness)
                    .frame(width: overallSize.width, height: invisibleThickness)
                    .position(x: overallSize.width / 2, y: pHeight + visibleThickness / 2)
                    .zIndex(zIndex)
                    .gesture(vDrag, including: .all)
            }
        }
        .background(GeometryReader { geometry in
            // Track the overallSize using a GeometryReader on the ZStack that contains the
            // primary, secondary, and splitter
            Color.clear
                .preference(key: SizePreferenceKey.self, value: geometry.size)
                .onPreferenceChange(SizePreferenceKey.self) {
                    overallSize = $0
                }
        })
        .contentShape(Rectangle())
    }
    
    init(layout: Layout, zIndex: Double = 0, fraction: Binding<CGFloat>, secondaryHidden: Binding<Bool>, @ViewBuilder primary: (()->P), @ViewBuilder secondary: (()->S)) {
        self.layout = layout
        self.zIndex = zIndex
        _fraction = fraction
        _primaryWidth = State(initialValue: nil)
        _primaryHeight = State(initialValue: nil)
        _secondaryHidden = secondaryHidden
        self.primary = primary()
        self.secondary = secondary()
    }
    
    private func width() -> CGFloat {
        if secondaryHidden {
            return overallSize.width - visibleThickness / 2
        } else {
            return (overallSize.width * fraction) - (visibleThickness / 2)
        }
    }
    
    private func height() -> CGFloat {
        if secondaryHidden {
            return overallSize.height - visibleThickness / 2
        } else {
            return (overallSize.height * fraction) - (visibleThickness / 2)
        }
    }
    
}

fileprivate struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}
struct Splitter: View {
    
    private let orientation: Orientation
    private let color: Color
    private let inset: CGFloat
    private let visibleThickness: CGFloat
    private var invisibleThickness: CGFloat
    
    enum Orientation: CaseIterable {
        /// The orientation of the Divider itself.
        /// Thus, use Horizontal in a VSplitView and Vertical in an HSplitView
        case Horizontal
        case Vertical
    }
    
    var body: some View {
        ZStack(alignment: .center) {
            switch orientation {
            case .Horizontal:
                Color.clear
                    .frame(height: invisibleThickness)
                    .padding(0)
                RoundedRectangle(cornerRadius: visibleThickness / 2)
                    .fill(color)
                    .frame(height: visibleThickness)
                    .padding(EdgeInsets(top: 0, leading: inset, bottom: 0, trailing: inset))
            case .Vertical:
                Color.clear
                    .frame(width: invisibleThickness)
                    .padding(0)
                RoundedRectangle(cornerRadius: visibleThickness / 2)
                    .fill(color)
                    .frame(width: visibleThickness)
                    .padding(EdgeInsets(top: inset, leading: 0, bottom: inset, trailing: 0))
            }
        }
        .contentShape(Rectangle())
    }
    
    init(orientation: Orientation, color: Color = .gray, inset: CGFloat = 8, visibleThickness: CGFloat = 2, invisibleThickness: CGFloat = 30) {
        self.orientation = orientation
        self.color = color
        self.inset = inset
        self.visibleThickness = visibleThickness
        self.invisibleThickness = invisibleThickness
    }
}

struct HSplitView<P: View, S: View>: View {
    let zIndex: Double
    @Binding var fraction: CGFloat
    @Binding var secondaryHidden: Bool
    let primary: ()->P
    let secondary: ()->S
    
    var body: some View {
        SplitView(layout: .Horizontal, fraction: $fraction, secondaryHidden: $secondaryHidden, primary: primary, secondary: secondary)
    }
    
    init(zIndex: Double = 0, fraction: Binding<CGFloat>, secondaryHidden: Binding<Bool>? = nil, @ViewBuilder primary: @escaping (()->P), @ViewBuilder secondary: @escaping (()->S)) {
        self.zIndex = zIndex
        _fraction = fraction
        _secondaryHidden = secondaryHidden ?? .constant(false)
        self.primary = primary
        self.secondary = secondary
    }
}
