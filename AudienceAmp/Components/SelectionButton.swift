//
//  SelectionButton.swift
//  AudienceAmp
//

import SwiftUI

struct SelectionButton: View {
    let state: Artist.SelectionState
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: iconName)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(iconColor)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: state)
    }

    private var iconName: String {
        switch state {
        case .selected:    return "checkmark.circle.fill"
        case .reviewing:   return "circle.dotted"
        case .notSelected: return "plus.circle"
        }
    }

    private var iconColor: Color {
        switch state {
        case .selected:    return .accentColor
        case .reviewing:   return .orange
        case .notSelected: return .secondary
        }
    }
}
