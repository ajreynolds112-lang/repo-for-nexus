//
//  GenreTag.swift
//  AudienceAmp
//
//  Genre taxonomy — primary genres and their associated sub-genres.
//

import Foundation

struct GenreTag: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let isPrimary: Bool
    let parentGenre: String?            // nil for primary genres
}

// MARK: - Genre Taxonomy

enum GenreTaxonomy {

    static let primaryGenres: [String] = [
        "R&B", "Hip-Hop", "Pop", "Rock", "Electronic",
        "Country", "Latin", "Afrobeats", "Jazz", "Classical",
        "Gospel", "Reggae", "Soul", "Funk", "Alternative"
    ]

    static let subGenres: [String: [String]] = [
        "R&B":        ["Neo Soul", "Contemporary R&B", "Alternative R&B", "Quiet Storm", "New Jack Swing"],
        "Hip-Hop":    ["Trap", "Drill", "Boom Bap", "Cloud Rap", "Conscious Hip-Hop", "Mumble Rap", "Phonk"],
        "Pop":        ["Synth-Pop", "Indie Pop", "Dance Pop", "Electropop", "Art Pop", "K-Pop"],
        "Rock":       ["Indie Rock", "Alternative Rock", "Hard Rock", "Punk", "Emo", "Grunge"],
        "Electronic": ["House", "Techno", "Drum & Bass", "Dubstep", "Ambient", "Lo-Fi", "Future Bass"],
        "Country":    ["Country Pop", "Outlaw Country", "Bluegrass", "Americana", "Country Rock"],
        "Latin":      ["Reggaeton", "Salsa", "Bachata", "Latin Pop", "Cumbia", "Corridos"],
        "Afrobeats":  ["Afropop", "Amapiano", "Highlife", "Afro-fusion", "Juju"],
        "Jazz":       ["Bebop", "Smooth Jazz", "Fusion", "Free Jazz", "Vocal Jazz"],
        "Classical":  ["Baroque", "Romantic", "Contemporary Classical", "Opera", "Chamber Music"],
        "Gospel":     ["Contemporary Gospel", "Traditional Gospel", "Gospel Rap", "Worship"],
        "Reggae":     ["Dancehall", "Dub", "Roots Reggae", "Ska"],
        "Soul":       ["Classic Soul", "Southern Soul", "Blue-Eyed Soul", "Psychedelic Soul"],
        "Funk":       ["P-Funk", "Funk Rock", "Go-Go", "Boogie"],
        "Alternative":["Indie", "Dream Pop", "Shoegaze", "Post-Rock", "Math Rock"]
    ]

    static func subGenres(for primary: String) -> [String] {
        subGenres[primary] ?? []
    }

    static func allTags() -> [GenreTag] {
        var tags: [GenreTag] = []
        for primary in primaryGenres {
            tags.append(GenreTag(name: primary, isPrimary: true, parentGenre: nil))
            for sub in subGenres(for: primary) {
                tags.append(GenreTag(name: sub, isPrimary: false, parentGenre: primary))
            }
        }
        return tags
    }
}
