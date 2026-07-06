import SwiftUI

struct WidgetCard<Content: View>: View {
    var showBackground: Bool = true
    @ViewBuilder let content: Content

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                if showBackground {
                    GlassBackground(cornerRadius: 16)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
