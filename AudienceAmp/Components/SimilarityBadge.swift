//
//  SimilarityBadge.swift
//  AudienceAmp
//

import SwiftUI

struct SimilarityBadge: View {
    let score: Double

    var body: some View {
        Text("\(Int(score * 100))% match")
            .font(.caption2.weight(.medium))
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(badgeColor.opacity(0.15))
            .foregroundStyle(badgeColor)
            .clipShape(Capsule())
    }

    private var badgeColor: Color {
        score >= 0.85 ? .green : score >= 0.70 ? .orange : .secondary
    }
}
