import SwiftUI

struct AnimatedBackground: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "F8F9FA"),
                    Color(hex: "E9ECEF"),
                    Color(hex: "F8F9FA")
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ForEach(0..<6, id: \.self) { index in
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                getCircleColor(for: index).opacity(0.3),
                                getCircleColor(for: index).opacity(0.1)
                            ]),
                            center: .center,
                            startRadius: 20,
                            endRadius: 100
                        )
                    )
                    .frame(
                        width: getCircleSize(for: index),
                        height: getCircleSize(for: index)
                    )
                    .blur(radius: 20)
                    .offset(
                        x: animate ? getRandomOffset() : -getRandomOffset(),
                        y: animate ? getRandomOffset() : -getRandomOffset()
                    )
                    .animation(
                        Animation.easeInOut(duration: Double.random(in: 3...8))
                            .repeatForever(autoreverses: true)
                            .delay(Double.random(in: 0...2)),
                        value: animate
                    )
            }
        }
        .onAppear {
            animate = true
        }
    }
    
    private func getCircleColor(for index: Int) -> Color {
        let colors = [
            Color(hex: "007AFF"),
            Color(hex: "34C759"), 
            Color(hex: "FF9500"),
            Color(hex: "FF3B30"),
            Color(hex: "5856D6"),
            Color(hex: "FF2D92")
        ]
        return colors[index % colors.count]
    }
    
    private func getCircleSize(for index: Int) -> CGFloat {
        let sizes: [CGFloat] = [120, 80, 150, 100, 90, 130]
        return sizes[index % sizes.count]
    }
    
    private func getRandomOffset() -> CGFloat {
        return CGFloat.random(in: -150...150)
    }
}

struct FloatingCircle: View {
    let color: Color
    let size: CGFloat
    @State private var offset = CGSize.zero
    @State private var opacity: Double = 0.3
    
    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    gradient: Gradient(colors: [
                        color.opacity(opacity),
                        color.opacity(opacity * 0.3)
                    ]),
                    center: .center,
                    startRadius: 10,
                    endRadius: size / 2
                )
            )
            .frame(width: size, height: size)
            .blur(radius: 15)
            .offset(offset)
            .opacity(opacity)
            .onAppear {
                withAnimation(
                    Animation.easeInOut(duration: Double.random(in: 4...8))
                        .repeatForever(autoreverses: true)
                ) {
                    offset = CGSize(
                        width: CGFloat.random(in: -200...200),
                        height: CGFloat.random(in: -200...200)
                    )
                    opacity = Double.random(in: 0.2...0.5)
                }
            }
    }
}

#Preview {
    AnimatedBackground()
} 