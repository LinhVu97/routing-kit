import SwiftUI

struct SwipeBackEdgeOverlay: View {
    let isEnabled: Bool
    let onSwipe: () -> Void

    var body: some View {
        if isEnabled {
            Color.clear
                .frame(width: 20)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 10, coordinateSpace: .global)
                        .onEnded { value in
                            if value.translation.width > 80 {
                                onSwipe()
                            }
                        }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }
}

extension View {
    func fidraSwipeBackEdge(isEnabled: Bool, onSwipe: @escaping () -> Void) -> some View {
        overlay {
            SwipeBackEdgeOverlay(isEnabled: isEnabled, onSwipe: onSwipe)
        }
    }
}
