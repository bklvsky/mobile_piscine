//
//  ContentView.swift
//  ex00
//
//  Created by Aleksandra Kachanova on 09/11/2025.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Text(
                "A simple text"
            ).padding(10)
                .background(Color.green.opacity(0.6))
                .cornerRadius(10)
                .font(Font.largeTitle)
            Button("Click me") {
                print("Button pressed!")
            }.padding(10)
            .background(Color.gray.opacity(0.3))
            .cornerRadius(10)
            .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.black, lineWidth: 1))
            .foregroundColor(Color.black)
        }
    }
}

#Preview {
    ContentView()
}
