import SwiftUI

// MARK: - Modelo de toggle

struct PatchToggle: Identifiable {
    let id: String
    let displayName: String
    let patchFilename: String
    let icon: String
    let category: PatchCategory
    
    // 🆕 Campos dinámicos
    var isDynamic: Bool = false
    var isBlocked: Bool = false
    var blockMessage: String? = nil
    var downloadURL: String? = nil
    var remoteID: String? = nil
    
    var fullFilename: String { "\(patchFilename).3105" }
    var normalizedName: String { Self.normalize(patchFilename) }
    
    static func normalize(_ name: String) -> String {
        var result = name
        if result.lowercased().hasSuffix(".3105") {
            result = String(result.dropLast(5))
        }
        result = result.trimmingCharacters(in: CharacterSet(charactersIn: " -_"))
        result = result.replacingOccurrences(
            of: "\\s+",
            with: " ",
            options: .regularExpression
        )
        return result.uppercased()
    }
}

enum PatchCategory: String, CaseIterable, Identifiable {
    case aimbot = "Aimbot"
    case hologramas = "Hologramas"
    
    var id: String { rawValue }
}

// MARK: - Registro de parches por modo (hardcodeados)

enum PatchRegistry {
    static func toggles(for mode: FFMode) -> [PatchToggle] {
        switch mode {
        case .normal:
            return [
                PatchToggle(
                    id: "aimbot-cabeza-sin-antena",
                    displayName: "Aimbot cabeza (Sin Antena)",
                    patchFilename: "AIMBOT CABEZA SIN ANTENA",
                    icon: "scope",
                    category: .aimbot
                ),
                PatchToggle(
                    id: "aimbot-pecho-sin-antena",
                    displayName: "Aimbot pecho (Sin Antena)",
                    patchFilename: "AIMBOT PECHO SIN ANTENA",
                    icon: "scope",
                    category: .aimbot
                ),
                PatchToggle(
                    id: "aimbot-cuello-sin-antena",
                    displayName: "Aimbot cuello (Sin Antena)",
                    patchFilename: "CUELLO SIN ANTENA",
                    icon: "scope",
                    category: .aimbot
                ),
                PatchToggle(
                    id: "aimbot-drag-avatar",
                    displayName: "Aimbot drag (Avatar)",
                    patchFilename: "Avatar_Aimdrag",
                    icon: "scope",
                    category: .aimbot
                ),
                PatchToggle(
                    id: "aimbot-balas-magicas",
                    displayName: "Balas mágicas (Sin Antena)",
                    patchFilename: "AVATAR BALAS MAGICAS SIN ANTENA",
                    icon: "sparkles",
                    category: .aimbot
                ),
                PatchToggle(
                    id: "holograma-basico",
                    displayName: "Básico",
                    patchFilename: "BASICO FF NORMAL",
                    icon: "cube.transparent",
                    category: .hologramas
                ),
                PatchToggle(
                    id: "holograma-rtx",
                    displayName: "RTX",
                    patchFilename: "RTX FF NORMAL",
                    icon: "cube.transparent",
                    category: .hologramas
                ),
                PatchToggle(
                    id: "holograma-pj-amarillo",
                    displayName: "PJ Amarillo",
                    patchFilename: "PJ FF NORMAL AMARILLO",
                    icon: "person.fill",
                    category: .hologramas
                ),
            ]
            
        case .max:
            return [
                PatchToggle(
                    id: "aimbot-cabeza-sin-antena-max",
                    displayName: "Aimbot cabeza (Sin Antena)",
                    patchFilename: "CABEZA FF MAX SIN ANTENA",
                    icon: "scope",
                    category: .aimbot
                ),
                PatchToggle(
                    id: "aimbot-cuello-sin-antena-max",
                    displayName: "Aimbot cuello (Sin Antena)",
                    patchFilename: "CUELLO SIN ANTENA FF MAX",
                    icon: "scope",
                    category: .aimbot
                ),
                PatchToggle(
                    id: "aimbot-drag-sin-antena-max",
                    displayName: "Aimbot drag (Sin Antena)",
                    patchFilename: "DRAG FF MAX SIN ANTENA",
                    icon: "scope",
                    category: .aimbot
                ),
                PatchToggle(
                    id: "balas-magicas-max",
                    displayName: "Bala mágica",
                    patchFilename: "BALA MAGICA FF MAX",
                    icon: "sparkles",
                    category: .aimbot
                ),
                PatchToggle(
                    id: "holograma-rtx-max",
                    displayName: "RTX",
                    patchFilename: "RTX FF MAX",
                    icon: "cube.transparent",
                    category: .hologramas
                ),
                PatchToggle(
                    id: "holograma-pj-max",
                    displayName: "PJ",
                    patchFilename: "PJ FF MAX",
                    icon: "person.fill",
                    category: .hologramas
                ),
            ]
        }
    }
}

// MARK: - Panel principal

struct ControlPanelView: View {
    @ObservedObject var session: AppSession
    @EnvironmentObject private var patchStore: PatchProjectStore
    @EnvironmentObject private var supabase: SupabaseService
    @EnvironmentObject private var patchesStore: PatchesStore
    @EnvironmentObject private var announcementsStore: AnnouncementsStore
    @State private var selectedCategory: PatchCategory = .aimbot
    @State private var activeToggles: Set<String> = []
    @State private var processingToggles: Set<String> = []
    @State private var toast: ToastMessage? = nil
    @State private var showSettings = false
    @State private var alert: PatchStoreAlert? = nil
    @State private var showLogoutConfirmation = false
    
    private var mode: FFMode { session.selectedMode ?? .normal }
    
    private var allToggles: [PatchToggle] {
        let hardcoded = PatchRegistry.toggles(for: mode)
        let dynamic = buildDynamicToggles(for: mode)
        return hardcoded + dynamic
    }
    
    private var toggles: [PatchToggle] {
        allToggles.filter { $0.category == selectedCategory }
    }
    
    private func buildDynamicToggles(for mode: FFMode) -> [PatchToggle] {
        let modeString = (mode == .normal) ? "normal" : "max"
        
        return patchesStore.remotePatches.compactMap { remote in
            guard remote.mode == modeString || remote.mode == "both" else {
                return nil
            }
            
            let category: PatchCategory
            switch remote.category.lowercased() {
            case "aimbot":
                category = .aimbot
            case "hologramas", "hologram":
                category = .hologramas
            default:
                category = .aimbot
            }
            
            return PatchToggle(
                id: remote.patchKey,
                displayName: remote.displayName,
                patchFilename: remote.patchFilename,
                icon: remote.icon,
                category: category,
                isDynamic: true,
                isBlocked: remote.isBlocked,
                blockMessage: remote.blockMessage,
                downloadURL: remote.downloadUrl,
                remoteID: remote.id
            )
        }
    }
    
    var body: some View {
        ZStack {
            // FONDO CLARO (Igual que ModeSelectionView)
            ZStack {
                Color(red: 0.93, green: 0.91, blue: 0.88)
                    .ignoresSafeArea()
                
                RadialGradient(
                    colors: [
                        Color.white.opacity(0.9),
                        Color.clear
                    ],
                    center: .init(x: 0.5, y: 0.1),
                    startRadius: 0,
                    endRadius: 500
                )
                .ignoresSafeArea()
                
                LinearGradient(
                    colors: [
                        Color.clear,
                        Color(red: 0.85, green: 0.82, blue: 0.78).opacity(0.4)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            }
            
            VStack(spacing: 0) {
                header
                    .padding(.top, 8)
                
                // Banner de anuncios
                if !announcementsStore.visibleBanners.isEmpty {
                    AnnouncementBannersContainer(
                        announcements: announcementsStore.visibleBanners,
                        onDismiss: { id in
                            withAnimation(.easeInOut(duration: 0.25)) {
                                announcementsStore.dismiss(id)
                            }
                        }
                    )
                }
                
                keyInfoCard
                    .padding(.top, 16)
                
                // CATEGORY PICKER TIPO PASTILLA
                categoryPicker
                    .padding(.top, 20)
                    .padding(.horizontal, 20)
                
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(toggles) { toggle in
                            ToggleRow(
                                toggle: toggle,
                                isOn: activeToggles.contains(toggle.id),
                                isProcessing: processingToggles.contains(toggle.id),
                                onToggle: { newValue in
                                    handleToggle(toggle, isOn: newValue)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
            
            if let toast {
                VStack {
                    Spacer()
                    ToastView(message: toast)
                        .padding(.bottom, 40)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .alert(item: $alert) { alert in
            Alert(
                title: Text(alert.titleKey),
                message: Text(alert.messageKey),
                dismissButton: .default(Text("OK"))
            )
        }
        .confirmationDialog(
            "Cerrar sesión",
            isPresented: $showLogoutConfirmation,
            titleVisibility: .visible
        ) {
            Button("Cerrar sesión", role: .destructive) {
                performLogout()
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Si cierras sesión deberás ingresar tu key de nuevo.")
        }
        .onAppear {
            syncToggleStates()
            Task {
                await loadDynamicPatchesIfNeeded()
            }
        }
    }
    
    // MARK: - Cargar parches dinámicos
    
    private func loadDynamicPatchesIfNeeded() async {
        if !patchesStore.remotePatches.isEmpty { return }
        
        do {
            let patches = try await patchesStore.fetchPatches()
            log("panel: \(patches.count) parches dinámicos cargados")
            await patchesStore.downloadAllPatches(patches)
        } catch {
            log("panel: error cargando parches dinámicos: \(error)")
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        VStack(spacing: 12) {
            HStack {
                Button {
                    withAnimation {
                        session.selectedMode = nil
                        activeToggles.removeAll()
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.black.opacity(0.7))
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(Color.white.opacity(0.5)))
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(0.8),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 10,
                                endRadius: 40
                            )
                        )
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white,
                                    Color(red: 0.9, green: 0.85, blue: 0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 52, height: 52)
                        .shadow(color: Color.white.opacity(0.6), radius: 10)
                    
                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 38, height: 38)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.1), radius: 3)
                }
                
                Spacer()
                
                Button {
                    showLogoutConfirmation = true
                } label: {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.black.opacity(0.7))
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(Color.white.opacity(0.5)))
                }
            }
            .padding(.horizontal, 20)
            
            // NOMBRE IDK
            Text("IDK")
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundStyle(.black.opacity(0.7))
                .tracking(3)
            
            Text("Panel de control")
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundStyle(.black.opacity(0.8))
            
            HStack(spacing: 6) {
                Circle()
                    .fill(.black.opacity(0.4))
                    .frame(width: 6, height: 6)
                Text(mode.displayName)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.black.opacity(0.6))
            }
            
            HStack(spacing: 6) {
                Circle()
                    .fill(Color(red: 0.3, green: 0.7, blue: 0.3))
                    .frame(width: 6, height: 6)
                    .shadow(color: Color(red: 0.3, green: 0.7, blue: 0.3).opacity(0.6), radius: 4)
                Text("Sistema en línea")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.black.opacity(0.5))
            }
            .padding(.top, 4)
        }
    }
    
    // MARK: - Key Info Card
    
    private var keyInfoCard: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.8))
                    .frame(width: 32, height: 32)
                
                Image(systemName: "person.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.black.opacity(0.7))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(supabase.currentKey?.keyValue ?? "SIN KEY")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(.black.opacity(0.8))
                    .lineLimit(1)
                
                Text(supabase.currentKey?.label ?? "Usuario")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.black.opacity(0.5))
                    .lineLimit(1)
            }
            
            Spacer()
            
            Text(daysRemainingText)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(keyStatusColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(keyStatusColor.opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(keyStatusColor.opacity(0.4), lineWidth: 1)
                        )
                )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.9), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, 20)
    }
    
    // MARK: - Key Helpers
    
    private var daysRemainingText: String {
        guard let key = supabase.currentKey else { return "—" }
        
        if key.isBanned {
            return "Baneada"
        }
        
        guard let expiresAt = key.expiresAt,
              let date = parseSupabaseDate(expiresAt) else {
            return "Sin expiración"
        }
        
        let now = Date()
        let diff = date.timeIntervalSince(now)
        
        if diff <= 0 {
            return "Expirada"
        }
        
        let totalMinutes = Int(diff / 60)
        let totalHours = totalMinutes / 60
        let days = totalHours / 24
        let minutes = totalMinutes % 60
        
        if days > 1 {
            return "\(days) días"
        }
        if days == 1 {
            return "1 día"
        }
        if totalHours >= 1 {
            return "\(totalHours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
    
    private func parseSupabaseDate(_ string: String) -> Date? {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso.date(from: string) { return date }
        
        iso.formatOptions = [.withInternetDateTime]
        if let date = iso.date(from: string) { return date }
        
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSZ"
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone(secondsFromGMT: 0)
        if let date = df.date(from: string) { return date }
        
        df.dateFormat = "yyyy-MM-dd HH:mm:ssZ"
        if let date = df.date(from: string) { return date }
        
        let fixed = string.replacingOccurrences(of: " ", with: "T")
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso.date(from: fixed) { return date }
        
        return nil
    }
    
    private var keyStatusColor: Color {
        guard let key = supabase.currentKey else { return .black.opacity(0.5) }
        
        if key.isBanned {
            return Color(red: 0.8, green: 0.3, blue: 0.3)
        }
        
        if let expiresAt = key.expiresAt,
           let date = parseSupabaseDate(expiresAt) {
            let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
            if days < 0 {
                return Color(red: 0.8, green: 0.3, blue: 0.3)
            }
            if days <= 3 {
                return Color(red: 0.85, green: 0.65, blue: 0.3)
            }
        }
        
        return Color(red: 0.2, green: 0.6, blue: 0.2)
    }
    
    // MARK: - Category Picker (ESTILO PASTILLA)
    
    private var categoryPicker: some View {
        HStack(spacing: 10) {
            ForEach(PatchCategory.allCases) { category in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedCategory = category
                    }
                } label: {
                    Text(category.rawValue)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(
                            selectedCategory == category
                                ? .black.opacity(0.8)
                                : .black.opacity(0.4)
                        )
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(selectedCategory == category ? Color.white : Color.white.opacity(0.4))
                                .overlay(
                                    Capsule()
                                        .stroke(
                                            selectedCategory == category
                                                ? Color.white.opacity(0.9)
                                                : Color.white.opacity(0.6),
                                            lineWidth: 1
                                        )
                                )
                                .shadow(
                                    color: selectedCategory == category ? .black.opacity(0.05) : .clear,
                                    radius: 4
                                )
                        )
                }
            }
            Spacer()
        }
    }
    
    // MARK: - Lógica de toggle (SIN CAMBIOS)
    
    private func handleToggle(_ toggle: PatchToggle, isOn: Bool) {
        guard !processingToggles.contains(toggle.id) else { return }
        
        if toggle.isBlocked && isOn {
            showBlockAlert(toggle)
            return
        }
        
        if isOn {
            let conflictingToggles = toggles.filter {
                $0.category == toggle.category && activeToggles.contains($0.id)
            }
            
            if !conflictingToggles.isEmpty {
                for conflict in conflictingToggles {
                    deactivatePatchSilently(conflict)
                }
            }
            
            activatePatch(toggle)
        } else {
            deactivatePatch(toggle)
        }
    }
    
    private func showBlockAlert(_ toggle: PatchToggle) {
        alert = PatchStoreAlert(
            titleKey: "Opción en mantenimiento",
            messageKey: toggle.blockMessage ?? "Esta opción no está disponible en este momento."
        )
    }
    
    private func activatePatch(_ toggle: PatchToggle) {
        processingToggles.insert(toggle.id)
        
        Task.detached(priority: .userInitiated) {
            do {
                guard let item = await findLibraryItem(for: toggle) else {
                    await MainActor.run {
                        processingToggles.remove(toggle.id)
                        showToast(
                            "Parche no encontrado: \(toggle.fullFilename)",
                            icon: "exclamationmark.triangle.fill",
                            color: Color(red: 0.8, green: 0.3, blue: 0.3)
                        )
                    }
                    return
                }
                
                let project: PatchProject
                if item.summary.schemaVersion >= 2 && item.canInspectContents {
                    project = try PatchProjectLibrary.synchronizeWorkspace(item: item)
                } else {
                    guard let p = item.project else {
                        throw PatchPackageError.invalidProject
                    }
                    project = p
                }
                
                _ = try DevicePatchService.apply(project: project)
                
                await MainActor.run {
                    processingToggles.remove(toggle.id)
                    activeToggles.insert(toggle.id)
                    patchStore.reload()
                    showToast(
                        "Parche activado con éxito",
                        icon: "checkmark.circle.fill",
                        color: Color(red: 0.2, green: 0.6, blue: 0.2)
                    )
                }
            } catch let error as PatchPackageError {
                await MainActor.run {
                    processingToggles.remove(toggle.id)
                    showToast(
                        "Error: \(error.localizationKey)",
                        icon: "exclamationmark.triangle.fill",
                        color: Color(red: 0.8, green: 0.3, blue: 0.3)
                    )
                }
            } catch {
                await MainActor.run {
                    processingToggles.remove(toggle.id)
                    showToast(
                        "Error al activar el parche",
                        icon: "exclamationmark.triangle.fill",
                        color: Color(red: 0.8, green: 0.3, blue: 0.3)
                    )
                }
            }
        }
    }
    
    private func deactivatePatch(_ toggle: PatchToggle) {
        processingToggles.insert(toggle.id)
        
        Task.detached(priority: .userInitiated) {
            do {
                guard let item = await findLibraryItem(for: toggle) else {
                    await MainActor.run {
                        processingToggles.remove(toggle.id)
                        activeToggles.remove(toggle.id)
                        showToast(
                            "Parche desactivado",
                            icon: "xmark.circle.fill",
                            color: .black.opacity(0.6)
                        )
                    }
                    return
                }
                
                guard let receipt = DevicePatchService.latestReceipt(projectID: item.id) else {
                    await MainActor.run {
                        processingToggles.remove(toggle.id)
                        activeToggles.remove(toggle.id)
                        showToast(
                            "Parche desactivado",
                            icon: "xmark.circle.fill",
                            color: .black.opacity(0.6)
                        )
                    }
                    return
                }
                
                try DevicePatchService.restore(receipt: receipt)
                
                await MainActor.run {
                    processingToggles.remove(toggle.id)
                    activeToggles.remove(toggle.id)
                    patchStore.reload()
                    showToast(
                        "Parche desactivado",
                        icon: "xmark.circle.fill",
                        color: .black.opacity(0.6)
                    )
                }
            } catch {
                await MainActor.run {
                    processingToggles.remove(toggle.id)
                    showToast(
                        "Error al desactivar",
                        icon: "exclamationmark.triangle.fill",
                        color: Color(red: 0.8, green: 0.3, blue: 0.3)
                    )
                }
            }
        }
    }
    
    private func deactivatePatchSilently(_ toggle: PatchToggle) {
        Task.detached(priority: .userInitiated) {
            guard let item = await findLibraryItem(for: toggle) else { return }
            guard let receipt = DevicePatchService.latestReceipt(projectID: item.id) else { return }
            try? DevicePatchService.restore(receipt: receipt)
            await MainActor.run {
                activeToggles.remove(toggle.id)
                patchStore.reload()
            }
        }
    }
    
    private func findLibraryItem(for toggle: PatchToggle) async -> PatchLibraryItem? {
        let targetNormalized = toggle.normalizedName
        return await MainActor.run {
            patchStore.items.first { item in
                let fileNormalized = PatchToggle.normalize(item.packageURL.lastPathComponent)
                return fileNormalized == targetNormalized
            }
        }
    }
    
    private func syncToggleStates() {
        var active: Set<String> = []
        for toggle in allToggles {
            let targetNormalized = toggle.normalizedName
            if let item = patchStore.items.first(where: {
                PatchToggle.normalize($0.packageURL.lastPathComponent) == targetNormalized
            }), DevicePatchService.latestReceipt(projectID: item.id) != nil {
                active.insert(toggle.id)
            }
        }
        activeToggles = active
    }
    
    private func showToast(_ message: String, icon: String, color: Color) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            toast = ToastMessage(message: message, icon: icon, color: color)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeOut(duration: 0.3)) {
                toast = nil
            }
        }
    }
    
    // MARK: - Logout
    
    private func performLogout() {
        supabase.disconnect()
        activeToggles.removeAll()
        processingToggles.removeAll()
        
        withAnimation(.easeInOut(duration: 0.3)) {
            session.selectedMode = nil
            session.isAuthenticated = false
        }
    }
}

// MARK: - Fila de toggle (COMPACTA)

private struct ToggleRow: View {
    let toggle: PatchToggle
    let isOn: Bool
    let isProcessing: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(toggle.isBlocked 
                          ? Color.orange.opacity(0.15)
                          : Color.white.opacity(0.8))
                    .frame(width: 34, height: 34)
                
                if isProcessing {
                    ProgressView()
                        .tint(.black.opacity(0.6))
                        .scaleEffect(0.8)
                } else if toggle.isBlocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.orange)
                } else {
                    Image(systemName: toggle.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.black.opacity(0.7))
                }
            }
            
            VStack(alignment: .leading, spacing: 1) {
                Text(toggle.displayName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(toggle.isBlocked ? .black.opacity(0.4) : .black.opacity(0.8))
                
                if toggle.isBlocked {
                    Text("En mantenimiento")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.orange.opacity(0.8))
                }
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { isOn },
                set: { onToggle($0) }
            ))
            .labelsHidden()
            .tint(.black.opacity(0.7))
            .scaleEffect(0.85)
            .disabled(isProcessing)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            toggle.isBlocked
                                ? Color.orange.opacity(0.4)
                                : (isOn
                                    ? Color.black.opacity(0.15)
                                    : Color.white.opacity(0.9)),
                            lineWidth: 1
                        )
                )
                .shadow(color: .black.opacity(0.04), radius: 5, x: 0, y: 2)
        )
    }
}

// MARK: - Toast

struct ToastMessage: Equatable {
    let message: String
    let icon: String
    let color: Color
    
    static func == (lhs: ToastMessage, rhs: ToastMessage) -> Bool {
        lhs.message == rhs.message
    }
}

private struct ToastView: View {
    let message: ToastMessage
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: message.icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(message.color)
            Text(message.message)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.black.opacity(0.8))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.95))
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.9), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.1), radius: 12, y: 4)
        )
    }
}
