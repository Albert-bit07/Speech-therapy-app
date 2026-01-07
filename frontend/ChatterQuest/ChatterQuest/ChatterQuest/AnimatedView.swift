//
//  AnimatedView.swift
//  ChatterQuest
//
//  Created by Nyaradzo Mararanje on 12/30/25.
//

import SwiftUI

struct AnimatedWordView: View {
    let word: String
    @State private var scale: CGFloat = 0.8
    @State private var opacity = 0.0

    var body: some View {
        Text(word)
            .font(.system(size: 48, weight: .bold))
            .foregroundColor(.softBlue)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                    scale = 1.0
                    opacity = 1.0
                }
            }
    }
}
