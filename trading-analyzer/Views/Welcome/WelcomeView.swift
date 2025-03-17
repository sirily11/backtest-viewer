//
//  WelcomeView.swift
//  trading-analyzer
//
//  Created by Qiwei Li on 3/17/25.
//

import SwiftUI

struct WelcomeView: View {
    @AppStorage("has-initialized") var hasInitialized = false

    @State private var allSet = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(alignment: .center) {
            Image(systemName: "laptopcomputer")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100)
                .foregroundStyle(.purple)

            Text("Welcome to Trading Analyzer")
                .font(.title)
                .fontWeight(.heavy)
                .foregroundStyle(.purple)

            Text("You need to configure the following settings before using the app")

            GeneralSettingsView {
                allSet = true
            }

            Button("Continue") {
                hasInitialized = true
                dismiss()
            }
            .frame(width: 200)
            .disabled(!allSet)
        }
        .padding(
            EdgeInsets(top: 50, leading: 20, bottom: 50, trailing: 20)
        )
        .interactiveDismissDisabled()
    }
}
