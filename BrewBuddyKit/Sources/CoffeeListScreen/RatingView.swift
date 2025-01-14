//
//  RatingView.swift
//  BrewBuddyKit
//
//  Created by Noam Efergan on 14/01/2025.
//

import SwiftUI

struct RatingView: View {
  @Binding var rating: Int

  var label = ""
  var maximumRating = 5
  var offImage = Image(systemName: "star")
  var onImage = Image(systemName: "star.fill")
  var offColor = Color.gray
  var onColor = Color.yellow

  var body: some View {
    HStack {
      ForEach(1...maximumRating, id: \.self) { number in
        Button {
          rating = number
        } label: {
          image(for: number)
            .foregroundStyle(number <= rating ? onColor : offColor)
        }
      }
    }
    .buttonStyle(.plain)
    .animation(.easeInOut, value: rating)
  }

  func image(for number: Int) -> Image {
    number <= rating ? onImage : offImage
  }
}

#Preview {
  @Previewable @State var rating = 3
  RatingView(rating: $rating)
}
