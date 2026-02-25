//
//  TreeView.swift
//  SSCA
//
//  Created by Chandramohan  on 20/02/26.
//

import SwiftUI

struct TreeView: View {
    
    var energyLevel: Double
    
    var body: some View {
        ZStack {
            
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [Color.green.opacity(energyLevel),
                                                    Color.clear]),
                        center: .center,
                        startRadius: 20,
                        endRadius: 150
                    )
                )
                .animation(.easeInOut(duration: 1), value: energyLevel)
            
            VStack {
                Rectangle()
                    .fill(Color.brown)
                    .frame(width: 20, height: 100)
                
                Circle()
                    .fill(Color.green.opacity(energyLevel))
                    .frame(width: 150, height: 150)
                    .animation(.easeInOut(duration: 1), value: energyLevel)
            }
        }
    }
}
