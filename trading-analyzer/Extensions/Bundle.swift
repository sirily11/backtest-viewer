//
//  Bundle.swift
//  trading-analyzer
//
//  Created by Qiwei Li on 3/19/25.
//
import SwiftUI

extension Bundle {
    var buildNumber: String {
        return infoDictionary?["CFBundleVersion"] as! String
    }
}
