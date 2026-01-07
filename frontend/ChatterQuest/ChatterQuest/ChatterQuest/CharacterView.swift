//
//  Characters.swift
//  ChatterQuest
//
//  Created by Nyaradzo Mararanje on 12/30/25.
//

import SwiftUI

enum GrowthStage {
    case worm
    case cocoon
    case butterfly
}

struct CharacterView: View {
    let stage: GrowthStage
    @State private var bounce = false

    var body: some View {
        Text(stage == .worm ? "🦋" : stage == .cocoon ? "🟡" : "🐛")
            .font(.system(size: 90))
            .offset(y: bounce ? -6 : 6)
            .animation(
                .easeInOut(duration: 1.2)
                .repeatForever(autoreverses: true),
                value: bounce
            )
            .onAppear {
                bounce.toggle()
            }
    }
}

#Preview {
    CharacterView(stage: .worm)
}
