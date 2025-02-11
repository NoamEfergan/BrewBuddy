//
//  ShotSummaryView.swift
//  BrewBuddyKit
//
//  Created by Noam Efergan on 11/02/2025.
//

import Models
import SwiftUI

struct ShotSummaryView: View {
    let shot: ShotDataModel
    var body: some View {
        VStack {
            LabeledContent("Grams in", value: "\(shot.gramsIn.formatted())g")
            LabeledContent("Grams out", value: "\(shot.gramsOut.formatted())g")
            LabeledContent("Time", value: "\(shot.time.formatted())s")
        }
    }
}

#Preview {
    ShotSummaryView(shot: .mock)
}
