import SwiftUI

struct PlaceholderWidgetView: View {
    let typeId: String
    let styleId: String

    private var typeDefinition: WidgetTypeDefinition? {
        WidgetRegistry.type(for: typeId)
    }

    private var styleName: String {
        WidgetRegistry.styleName(typeId: typeId, styleId: styleId)
    }

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: typeDefinition?.icon ?? "square.grid.2x2")
                .font(.title2)
                .foregroundStyle(Color.accentColor)

            Text(typeDefinition?.name ?? typeId)
                .font(.caption.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(styleName)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(6)
    }
}

#Preview {
    PlaceholderWidgetView(typeId: "clock", styleId: "minimal")
        .frame(width: 80, height: 80)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
}
