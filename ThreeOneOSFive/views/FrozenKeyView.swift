import SwiftUI

struct FrozenKeyView: View {
    @State private var appeared = false
    @State private var rotationAngle: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            RadialGradient(
                colors: [
                    Color.blue.opacity(0.2),
                    Color.clear
                ],
                center: .init(x: 0.5, y: 0.4),
                startRadius: 0,
                endRadius: 400
            )
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                frozenIcon
                
                VStack(spacing: 12) {
                    Text("KEY CONGELADA")
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .tracking(3)
                        .foregroundStyle(.white)
                    
                    Text("Tu key ha sido congelada temporalmente.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Text("Contacta al administrador para reactivarla.")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.top, 4)
                }
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.6).delay(0.2), value: appeared)
                
                Spacer()
                
                Button {
                    retryAccess()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14, weight: .bold))
                        Text("REINTENTAR")
                            .font(.system(size: 13, weight: .heavy))
                            .tracking(2)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.6).delay(0.4), value: appeared)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                appeared = true
            }
            withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                pulseScale = 1.06
            }
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
        }
    }
    
    private var frozenIcon: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.blue.opacity(0.4),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 30,
                        endRadius: 120
                    )
                )
                .frame(width: 280, height: 280)
                .scaleEffect(pulseScale)
            
            Circle()
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                .frame(width: 200, height: 200)
            
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            Color.blue.opacity(0),
                            Color.blue.opacity(0.8),
                            Color.blue.opacity(0),
                            Color.cyan.opacity(0.6),
                            Color.blue.opacity(0)
                        ],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 2, dash: [6, 10])
                )
                .frame(width: 160, height: 160)
                .rotationEffect(.degrees(rotationAngle))
            
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .frame(width: 110, height: 110)
                .shadow(color: .blue.opacity(0.6), radius: 20)
            
            Image(systemName: "snowflake")
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, .cyan],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
        .frame(height: 280)
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.85)
        .animation(.easeOut(duration: 0.7), value: appeared)
    }
    
    private func retryAccess() {
        NotificationCenter.default.post(name: .frozenKeyRetry, object: nil)
    }
}

// MARK: - Notification

extension Notification.Name {
    static let frozenKeyRetry = Notification.Name("frozenKeyRetry")
}
