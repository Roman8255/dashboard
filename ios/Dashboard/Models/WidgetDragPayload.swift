import CoreTransferable
import UniformTypeIdentifiers

struct WidgetDragPayload: Codable, Hashable, Transferable {
    let typeId: String
    let styleId: String

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .dashboardWidget)
    }
}

extension UTType {
    static let dashboardWidget = UTType(exportedAs: "sk.romanbednarik.dashboard.widget")
}
