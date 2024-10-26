//
//  ThreeDots.swift
//  LLMFarm
//
//  Created by guinmoon on 26.10.2024.
//

import SwiftUI

struct ThreeDots: View {
    @State var loading = false
    var dotsColor = Color(.blue)
    var body: some View {
        HStack(spacing: 20) {
            Circle()
                .fill(dotsColor)
                .frame(width: 10, height: 10)
                .scaleEffect(loading ? 1.5 : 0.5)
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: loading)
            Circle()
                .fill(dotsColor)
                .frame(width: 10, height: 10)
                .scaleEffect(loading ? 1.5 : 0.5)
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true).delay(0.2), value: loading)
            Circle()
                .fill(dotsColor)
                .frame(width: 10, height: 10)
                .scaleEffect(loading ? 1.5 : 0.5)
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true).delay(0.4), value: loading)
        }
        .onAppear() {
            self.loading = true
        }
    }
}

//#Preview {
//    ThreeDots()
//}
