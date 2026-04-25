//
//  ArtistRowView.swift
//  AudienceAmp
//

import SwiftUI

struct ArtistRowView: View {
    let artist: Artist
    let onToggle: () -> Void
    let onRelated: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: artist.imageURL) { phase in
                switch phase {
                case .success(let img): img.resizable().scaledToFill()
                case .failure:          Image(systemName: "music.mic").foregroundStyle(.secondary)
                                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                                            .background(Color.secondary.opacity(0.15))
                default:                ProgressView()
                }
            }
            .frame(width: 52, height: 52)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(artist.name).font(.subheadline.weight(.semibold)).lineLimit(1)
                    if artist.isRelated {
                        Text("Related").font(.caption2.weight(.medium))
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(Color.purple.opacity(0.15))
                            .foregroundStyle(.purple).clipShape(Capsule())
                    }
                }
                Text(artist.genres.prefix(2).joined(separator: " · "))
                    .font(.caption).foregroundStyle(.secondary).lineLimit(1)
                HStack(spacing: 8) {
                    Label(artist.formattedListeners + " listeners", systemImage: "waveform")
                        .font(.caption2).foregroundStyle(.secondary)
                    SimilarityBadge(score: artist.similarityScore)
                }
            }

            Spacer()

            VStack(spacing: 8) {
                SelectionButton(state: artist.selectionState, action: onToggle)
                Button { onRelated() } label: {
                    Image(systemName: "person.2.badge.plus").font(.caption).foregroundStyle(.secondary)
                }.buttonStyle(.plain).help("Load related artists")
            }
        }
        .padding(12)
        .background(rowBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(borderColor, lineWidth: 1.5))
        .animation(.easeInOut(duration: 0.15), value: artist.selectionState)
    }

    private var rowBackground: Color {
        switch artist.selectionState {
        case .selected:    return Color.accentColor.opacity(0.08)
        case .reviewing:   return Color.orange.opacity(0.06)
        case .notSelected: return Color(.systemBackground)
        }
    }
    private var borderColor: Color {
        switch artist.selectionState {
        case .selected:    return Color.accentColor.opacity(0.5)
        case .reviewing:   return Color.orange.opacity(0.4)
        case .notSelected: return Color.secondary.opacity(0.15)
        }
    }
}
