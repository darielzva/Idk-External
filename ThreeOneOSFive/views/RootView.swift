import SwiftUI
import UIKit

enum FFMode: String, CaseIterable, Identifiable {
    case normal = "FF NORMAL"
    case max = "FF MAX"
    
    var id: String { rawValue }
    
    var bundleID: String {
        switch self {
        case .normal: return "com.dts.freefireth"
        case .max: return "com.dts.freefiremax"
        }
    }
    
    var folderName: String {
        switch self {
        case .normal: return "FF NORMAL"
        case .max: return "FF MAX"
        }
    }
    
    var displayName: String {
        switch self {
        case .normal: return "FREE FIRE TH"
        case .max: return "FREE FIRE MAX"
        }
    }
}

@MainActor
final class AppSession: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var selectedMode: FFMode? = nil
    
    func logout() {
        isAuthenticated = false
        selectedMode = nil
    }
}

struct RootView: View {
    @StateObject private var session = AppSession()
    @StateObject private var supabase = SupabaseService()
    @StateObject private var patchesStore = PatchesStore()
    @StateObject private var announcementsStore = AnnouncementsStore()
    @EnvironmentObject private var patchStore: PatchProjectStore
    @State private var showSplash = true
    @Environment(\.scenePhase) private var scenePhase
    
    @State private var splashProgress: Double = 0
    @State private var splashStep: String = "INICIANDO SISTEMA..."
    
    var body: some View {
        ZStack {
            // 1️⃣ Splash
            if showSplash {
                SplashView(
                    externalProgress: splashProgress,
                    externalStep: splashStep
                ) {
                    // Callback vacío
                }
                .transition(.opacity)
                .zIndex(2)
                .task {
                    await runSplashSequence()
                }
            }
            // 2️⃣ Modo mantenimiento
            else if supabase.isMaintenanceMode {
                MaintenanceView(message: supabase.maintenanceMessage)
                    .transition(.opacity)
                    .zIndex(4)
            }
            // 3️⃣ Key congelada
            else if supabase.isKeyFrozen {
                FrozenKeyView()
                    .transition(.opacity)
                    .zIndex(3)
            }
            // 4️⃣ Acceso revocado
            else if supabase.isKeyRevoked {
                RevokedAccessView()
                    .transition(.opacity)
                    .zIndex(3)
            }
            // 5️⃣ Flujo normal
            else {
                if !session.isAuthenticated {
                    LoginView(session: session)
                        .environmentObject(supabase)
                        .environmentObject(patchesStore)
                        .transition(.opacity)
                } else if session.selectedMode == nil {
                    ModeSelectionView(session: session)
                        .environmentObject(supabase)
                        .environmentObject(patchesStore)
                        .transition(.opacity)
                } else {
                    ControlPanelView(session: session)
                        .environmentObject(supabase)
                        .environmentObject(patchesStore)
                        .environmentObject(patchStore)
                        .environmentObject(announcementsStore)
                        .transition(.opacity)
                }
            }
        }
        // 🆕 Popup de anuncios (encima de TODO, excepto splash)
        .overlay {
            if !showSplash && !announcementsStore.visiblePopups.isEmpty {
                AnnouncementPopupsContainer(
                    announcements: announcementsStore.visiblePopups,
                    onDismiss: { id in
                        withAnimation(.easeInOut(duration: 0.25)) {
                            announcementsStore.dismiss(id)
                        }
                    },
                    onRestart: {
                        restartApp()
                    }
                )
                .zIndex(999)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: announcementsStore.visiblePopups.count)
        .animation(.easeInOut(duration: 0.25), value: session.isAuthenticated)
        .animation(.easeInOut(duration: 0.25), value: session.selectedMode)
        .animation(.easeInOut(duration: 0.25), value: supabase.isKeyRevoked)
        .animation(.easeInOut(duration: 0.25), value: supabase.isKeyFrozen)
        .animation(.easeInOut(duration: 0.25), value: supabase.isMaintenanceMode)
        .animation(.easeInOut(duration: 0.4), value: showSplash)
        .onAppear {
            // 🎯 Suscripciones Realtime
            supabase.subscribeToMaintenance()
            announcementsStore.subscribeToAnnouncements()
            
            Task {
                await supabase.checkMaintenanceStatus()
            }
            
            NotificationCenter.default.addObserver(
                forName: .frozenKeyRetry,
                object: nil,
                queue: .main
            ) { _ in
                Task {
                    if let key = supabase.currentKey {
                        await revalidateKey(key.keyValue)
                    }
                }
            }
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                Task {
                    await supabase.checkMaintenanceStatus()
                }
                if session.isAuthenticated, let key = supabase.currentKey {
                    Task {
                        await revalidateKey(key.keyValue)
                    }
                }
            }
        }
    }
    
    // MARK: - Splash Sequence
    
    private func runSplashSequence() async {
        let startTime = Date()
        let minimumDuration: TimeInterval = 3.0
        
        await updateSplash(progress: 0.05, step: "INICIANDO SISTEMA...")
        try? await Task.sleep(nanoseconds: 300_000_000)
        
        await updateSplash(progress: 0.15, step: "CONECTANDO...")
        await updateSplash(progress: 0.22, step: "DESCARGANDO CONFIGURACIÓN...")
        
        do {
            // 1. Descargar parches
            let patches = try await patchesStore.fetchPatches()
            log("splash: \(patches.count) parches encontrados en Supabase")
            
            if patches.isEmpty {
                await updateSplash(progress: 0.80, step: "SIN PARCHES REMOTOS")
            } else {
                await patchesStore.downloadAllPatches(
                    patches,
                    onEachProgress: { current, total, name in
                        Task { @MainActor in
                            let baseProgress = 0.25
                            let rangeProgress = 0.55
                            let progress = baseProgress + (Double(current) / Double(total)) * rangeProgress
                            self.splashStep = "DESCARGANDO PARCHES (\(current)/\(total))..."
                            withAnimation(.easeInOut(duration: 0.3)) {
                                self.splashProgress = progress
                            }
                        }
                    },
                    onOverallProgress: { _ in }
                )
            }
            
            // 2. Descargar anuncios
            await updateSplash(progress: 0.85, step: "CARGANDO ANUNCIOS...")
            do {
                _ = try await announcementsStore.fetchAnnouncements()
            } catch {
                log("splash: error cargando anuncios: \(error)")
            }
            
            // 🎯 Recargar el patchStore de 3105 para que detecte los nuevos parches
            await MainActor.run {
                patchStore.reload()
            }
            try? await Task.sleep(nanoseconds: 500_000_000)
            await MainActor.run {
                patchStore.reload()
            }
            
            await updateSplash(progress: 0.92, step: "VERIFICANDO INTEGRIDAD...")
            try? await Task.sleep(nanoseconds: 300_000_000)
            
        } catch {
            log("splash: error cargando datos — usando locales: \(error)")
            await updateSplash(progress: 0.85, step: "SIN CONEXIÓN — USANDO LOCALES")
            try? await Task.sleep(nanoseconds: 500_000_000)
        }
        
        await updateSplash(progress: 1.0, step: "SISTEMA LISTO")
        
        let elapsed = Date().timeIntervalSince(startTime)
        if elapsed < minimumDuration {
            let remaining = minimumDuration - elapsed
            try? await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000_000))
        }
        
        try? await Task.sleep(nanoseconds: 200_000_000)
        
        await MainActor.run {
            withAnimation(.easeInOut(duration: 0.4)) {
                showSplash = false
            }
        }
    }
    
    private func updateSplash(progress: Double, step: String) async {
        await MainActor.run {
            withAnimation(.easeInOut(duration: 0.3)) {
                self.splashProgress = progress
                self.splashStep = step
            }
        }
    }
    
    // MARK: - Revalidar Key
    
    private func revalidateKey(_ keyValue: String) async {
        do {
            _ = try await supabase.verifyKey(keyValue)
            log("root: key revalidated OK")
            await MainActor.run {
                supabase.isKeyFrozen = false
                supabase.isKeyRevoked = false
            }
        } catch let error as SupabaseError {
            log("root: key revalidation failed — \(error)")
            await MainActor.run {
                switch error {
                case .keyBanned, .keyExpired, .keyNotFound, .deviceBanned:
                    supabase.isKeyRevoked = true
                    supabase.isKeyFrozen = false
                case .keyInactive:
                    supabase.isKeyFrozen = true
                    supabase.isKeyRevoked = false
                default:
                    break
                }
            }
        } catch {
            log("root: key revalidation error — \(error)")
        }
    }
    
    // MARK: - 🆕 Reiniciar app
    
    private func restartApp() {
        log("root: usuario pulsó reiniciar app")
        
        // Marcar el popup como "cerrado" para que no vuelva a aparecer
        // cuando el usuario abra la app de nuevo
        if let popupID = announcementsStore.visiblePopups.first?.id {
            announcementsStore.dismiss(popupID)
        }
        
        // Pequeña animación antes de cerrar
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            // iOS no permite reiniciar la app directamente
            // La forma más limpia es forzar un crash/exit controlado
            exit(0)
        }
    }
}
