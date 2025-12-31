//
//  ContentView.swift
//  SusuLord
//
//  Created by suyinghui on 2025/12/31.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")

            Text("Developed by 苏苏")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
