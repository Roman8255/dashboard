import SwiftUI

struct ClockWidgetView: View {
    let styleId: String

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            WidgetCard {
                switch styleId {
                case "analog":
                    analogFace(date: context.date)
                case "digital":
                    digitalFace(date: context.date, showSeconds: true)
                default:
                    digitalFace(date: context.date, showSeconds: false)
                }
            }
        }
    }

    private func digitalFace(date: Date, showSeconds: Bool) -> some View {
        VStack(spacing: 4) {
            Text(date, format: showSeconds ? .dateTime.hour().minute().second() : .dateTime.hour().minute())
                .font(.system(size: showSeconds ? 22 : 28, weight: .bold, design: .rounded))
                .monospacedDigit()
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            Text(date, format: .dateTime.weekday(.abbreviated).day().month(.abbreviated))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(8)
    }

    private func analogFace(date: Date) -> some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let calendar = Calendar.current
            let hour = Double(calendar.component(.hour, from: date) % 12)
            let minute = Double(calendar.component(.minute, from: date))
            let second = Double(calendar.component(.second, from: date))

            ZStack {
                Circle()
                    .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)

                ForEach(0..<12, id: \.self) { tick in
                    Rectangle()
                        .fill(Color.white.opacity(0.5))
                        .frame(width: 1, height: tick % 3 == 0 ? 6 : 3)
                        .offset(y: -(size / 2 - 8))
                        .rotationEffect(.degrees(Double(tick) * 30))
                }

                hand(length: size * 0.22, width: 3, angle: hour * 30 + minute * 0.5, center: center)
                hand(length: size * 0.32, width: 2, angle: minute * 6, center: center)
                hand(length: size * 0.36, width: 1, angle: second * 6, center: center, color: Color.accentColor)

                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 5, height: 5)
                    .position(center)
            }
        }
        .padding(6)
    }

    private func hand(length: CGFloat, width: CGFloat, angle: Double, center: CGPoint, color: Color = .white) -> some View {
        Rectangle()
            .fill(color)
            .frame(width: width, height: length)
            .offset(y: -length / 2)
            .rotationEffect(.degrees(angle))
            .position(center)
    }
}
