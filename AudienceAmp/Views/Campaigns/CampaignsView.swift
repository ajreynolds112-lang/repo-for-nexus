//
//  CampaignsView.swift
//  AudienceAmp
//
//  Saved campaigns list — backed by SwiftData.
//

import SwiftUI
import SwiftData

struct CampaignsView: View {

    @Query(sort: \.createdAt, order: .reverse) private var campaigns: [SavedCampaign]
    @Environment(\.modelContext) private var modelContext
    @State private var showDeleteConfirm: SavedCampaign? = nil

    var body: some View {
        NavigationStack {
            Group {
                if campaigns.isEmpty {
                    ContentUnavailableView(
                        "No Saved Campaigns",
                        systemImage: "folder.badge.plus",
                        description: Text("Complete the artist discovery flow to save a campaign.")
                    )
                } else {
                    List {
                        ForEach(campaigns) { campaign in
                            campaignRow(campaign)
                        }
                        .onDelete { indexSet in
                            for idx in indexSet { modelContext.delete(campaigns[idx]) }
                        }
                    }
                }
            }
            .navigationTitle("Campaigns")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private func campaignRow(_ campaign: SavedCampaign) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(campaign.name).font(.subheadline.weight(.semibold))
            Text(campaign.artistNames.prefix(3).joined(separator: ", "))
                .font(.caption).foregroundStyle(.secondary).lineLimit(1)
            HStack {
                Text(campaign.genre).font(.caption2)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Color.accentColor.opacity(0.1))
                    .foregroundStyle(.accentColor).clipShape(Capsule())
                Spacer()
                Text(campaign.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
