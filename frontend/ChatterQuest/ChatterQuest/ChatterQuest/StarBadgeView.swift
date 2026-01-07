//
//  StarBadgeView.swift
//  ChatterQuest
//
//  Created by Nyaradzo Mararanje on 12/30/25.
//

import SwiftUI

struct StarBadgeView: View {
    @State private var pulse = false

    var body: some View {
        Image(systemName: "star.fill")
            .font(.title)
            .foregroundColor(.yellow)
            .scaleEffect(pulse ? 1.2 : 1.0)
            .onAppear {
                withAnimation(.easeInOut(duration: 1).repeatForever()) {
                    pulse.toggle()
                }
            }
    }
}

#Preview {
    StarBadgeView()
}
