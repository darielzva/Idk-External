import SwiftUI

struct SplashView: View {
    let onFinished: () -> Void

    // 🎯 Estados externos (vienen del RootView)
    let externalProgress: Double
    let externalStep: String

    // 🎯 Estados internos (animaciones)
    @State private var rotationAngle: Double = 0
    @State private var displayProgress: CGFloat = 0
    @State private var appeared = false
    @State private var glowPulse = false
    @State private var displayStep: String = "INICIANDO SISTEMA..."

    // MARK: - Nombre
    private let appName = SITheme.appName

    init(
        externalProgress: Double = 0,
        externalStep: String = "INICIANDO SISTEMA...",
        onFinished: @escaping () -> Void
    ) {
        self.externalProgress = externalProgress
        self.externalStep = externalStep
        self.onFinished = onFinished
    }

    var body: some View {
        ZStack {
            SIBackground(imageTop: 48, imageWidthRatio: 0.74)

            VStack(spacing: 0) {
                // Deja ver la imagen de fondo arriba; el logo y la barra quedan abajo
                Spacer(minLength: 286)

                logoSection

                Spacer().frame(height: 30)

                // Nombre
                Text(appName)
                    .font(.system(size: 26, weight: .heavy))
                    .tracking(2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .foregroundColor(SITheme.ink)
                    .shadow(color: SITheme.accent.opacity(0.45), radius: 10)
                    .padding(.horizontal, 28)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.2), value: appeared)

                Spacer().frame(height: 18)

                // 🎯 Texto dinámico (paso actual)
                Text(displayStep)
                    .font(.system(size: 11, weight: .bold))
                    .tracking(3)
                    .foregroundColor(SITheme.accent)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .frame(height: 20)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: displayStep)
                    .opacity(appeared ? 1 : 0)

                Spacer().frame(height: 14)

                // 🎯 Barra de progreso real
                progressBar
                    .padding(.horizontal, 80)
                    .opacity(appeared ? 1 : 0)

                Spacer().frame(height: 8)

                // 🎯 Porcentaje
                Text("\(Int(displayProgress * 100))%")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .tracking(2)
                    .foregroundColor(SITheme.inkSoft)
                    .opacity(appeared ? 1 : 0)

                Spacer()

                Text("Hecho por didierxitx7")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(SITheme.inkFaint)
                    .padding(.bottom, 16)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.4), value: appeared)
            }
        }
        .onAppear {
            startAnimations()
        }
        .onChange(of: externalProgress) { newValue in
            withAnimation(.easeInOut(duration: 0.4)) {
                displayProgress = CGFloat(min(max(newValue, 0), 1))
            }
        }
        .onChange(of: externalStep) { newValue in
            withAnimation(.easeInOut(duration: 0.3)) {
                displayStep = newValue
            }
        }
    }

    // MARK: - Logo Section

    private var logoSection: some View {
        ZStack {
            // Halo pulsante (verde)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            SITheme.accent.opacity(glowPulse ? 0.40 : 0.18),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 26,
                        endRadius: 110
                    )
                )
                .frame(width: 230, height: 230)

            // Anillo de puntos girando (verde, con puntos rojos destacados)
            ForEach(0..<28, id: \.self) { i in
                let angle = (Double(i) / 28.0) * 360.0
                let isHighlighted = i % 7 == 0

                Circle()
                    .fill(
                        isHighlighted
                            ? SITheme.accentRed
                            : SITheme.accent.opacity(0.45)
                    )
                    .frame(
                        width: isHighlighted ? 4 : 2.5,
                        height: isHighlighted ? 4 : 2.5
                    )
                    .shadow(
                        color: isHighlighted ? SITheme.accentRed.opacity(0.8) : .clear,
                        radius: isHighlighted ? 4 : 0
                    )
                    .offset(y: -84)
                    .rotationEffect(.degrees(angle + rotationAngle))
            }

            // Anillo conector
            Circle()
                .stroke(Color.white.opacity(0.16), lineWidth: 0.5)
                .frame(width: 168, height: 168)
                .rotationEffect(.degrees(rotationAngle * 0.5))

            // Aro verde -> rojo
            Circle()
                .stroke(SITheme.ringStroke, lineWidth: 2.5)
                .frame(width: 118, height: 118)
                .shadow(color: SITheme.accent.opacity(0.6), radius: 14)

            // Logo principal (imagen verde)
            SILogo(size: 106)
                .shadow(color: .black.opacity(0.4), radius: 10)
        }
        .frame(height: 230)
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.9)
        .animation(.easeOut(duration: 0.6), value: appeared)
    }

    // MARK: - Progress Bar (rojo -> verde)

    private var progressBar: some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(Color.white.opacity(0.12))
                .frame(height: 4)

            Capsule()
                .fill(
                    LinearGradient(
                        colors: [SITheme.accentRed, SITheme.accent],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: displayProgress * 220, height: 4)
                .shadow(color: SITheme.accent.opacity(0.5), radius: 6)
        }
        .frame(width: 220)
    }

    // MARK: - Animaciones (SIN CAMBIOS)

    private func startAnimations() {
        withAnimation(.easeOut(duration: 0.4)) {
            appeared = true
        }

        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            glowPulse = true
        }

        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }
    }
}