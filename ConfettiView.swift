import SwiftUI

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    @State private var opacity: Double = 1.0

    private let colors: [Color] = [
        .brandPurple, .brandPurpleLight, .brandPurpleDark,
        Color(red: 0.98, green: 0.75, blue: 0.30),
        Color(red: 0.30, green: 0.85, blue: 0.55),
        Color(red: 0.95, green: 0.40, blue: 0.50)
    ]

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let now = timeline.date.timeIntervalSinceReferenceDate
                for particle in particles {
                    let elapsed = now - particle.startTime
                    guard elapsed >= 0 else { continue }

                    let gravity: Double = 420
                    let x = size.width / 2 + particle.velocityX * elapsed + particle.drift * sin(elapsed * particle.wobbleSpeed)
                    let y = size.height * 0.35 + particle.velocityY * elapsed + 0.5 * gravity * elapsed * elapsed

                    guard y < size.height + 20 else { continue }

                    let angle = Angle.degrees(particle.rotation + particle.rotationSpeed * elapsed * 360)
                    let rect = CGRect(x: x - particle.size / 2, y: y - particle.size / 2,
                                      width: particle.size, height: particle.size * particle.aspectRatio)

                    context.opacity = max(0, 1.0 - elapsed / 2.8)
                    var transform = context
                    transform.translateBy(x: rect.midX, y: rect.midY)
                    transform.rotate(by: angle)
                    transform.translateBy(x: -rect.midX, y: -rect.midY)
                    transform.fill(
                        Path(roundedRect: rect, cornerRadius: particle.isCircle ? particle.size / 2 : 2),
                        with: .color(particle.color)
                    )
                }
            }
        }
        .opacity(opacity)
        .allowsHitTesting(false)
        .ignoresSafeArea()
        .onAppear {
            spawnParticles()
            withAnimation(.easeIn(duration: 0.5).delay(2.0)) {
                opacity = 0
            }
        }
    }

    private func spawnParticles() {
        let now = Date.now.timeIntervalSinceReferenceDate
        particles = (0..<80).map { _ in
            let angle = Double.random(in: -Double.pi ..< 0) // upward burst
            let speed = Double.random(in: 300...700)
            return ConfettiParticle(
                startTime: now + Double.random(in: 0...0.15),
                velocityX: cos(angle) * speed * Double.random(in: 0.6...1.0),
                velocityY: sin(angle) * speed,
                size: CGFloat.random(in: 5...10),
                aspectRatio: CGFloat.random(in: 0.4...1.0),
                color: colors.randomElement()!,
                rotation: Double.random(in: 0...360),
                rotationSpeed: Double.random(in: 0.5...3.0),
                drift: Double.random(in: -15...15),
                wobbleSpeed: Double.random(in: 2...6),
                isCircle: Bool.random()
            )
        }
    }
}

private struct ConfettiParticle: Sendable {
    let startTime: Double
    let velocityX: Double
    let velocityY: Double
    let size: CGFloat
    let aspectRatio: CGFloat
    let color: Color
    let rotation: Double
    let rotationSpeed: Double
    let drift: Double
    let wobbleSpeed: Double
    let isCircle: Bool
}
