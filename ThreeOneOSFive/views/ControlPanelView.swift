import SwiftUI

// MARK: - Modelo de toggle

struct PatchToggle: Identifiable {
    let id: String
    let displayName: String
    let patchFilename: String
    let icon: String
    let category: PatchCategory
    
    // Campos dinámicos
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
    
    /// Nombre que se muestra en la interfaz
    var title: String {
        switch self {
        case .aimbot: return "Patches"
        case .hologramas: return "Visuals"
        }
    }
    
    var subtitle: String {
        switch self {
        case .aimbot: return "Gameplay controls"
        case .hologramas: return "Visual options"
        }
    }
    
    var icon: String {
        switch self {
        case .aimbot: return "slider.horizontal.3"
        case .hologramas: return "sparkles"
        }
    }
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
    
    private var activeCount: Int {
        toggles.filter { activeToggles.contains($0.id) }.count
    }
    
    private var keyStatus: AngelKeyStatus {
        AngelKeyStatus.make(
            hasKey: supabase.currentKey != nil,
            isBanned: supabase.currentKey?.isBanned ?? false,
            expiresAt: supabase.currentKey?.expiresAt
        )
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
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            AngelBackground()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    AngelHeader(subtitle: "PATCH LIBRARY", online: true)
                        .padding(.top, 8)
                    
                    // Banners de anuncios (solo tipo banner)
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
                    
                    welcomeCard
                    patchesCard
                    accessCard
                    
                    AngelSignature()
                        .padding(.top, 8)
                        .padding(.bottom, 30)
                }
                .padding(.horizontal, 20)
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
    
    // MARK: - Tarjeta "Listen now"
    
    private var welcomeCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Listen now")
                    .font(.system(size: 32, weight: .heavy))
                    .foregroundStyle(.white)
                
                Spacer()
                
                // Cambiar de versión (antes era el botón de atrás)
                Button {
                    withAnimation {
                        session.selectedMode = nil
                        activeToggles.removeAll()
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 10, weight: .heavy))
                        Text(mode.displayName)
                            .font(.system(size: 11, weight: .heavy))
                            .lineLimit(1)
                    }
                    .foregroundStyle(AngelTheme.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule().fill(AngelTheme.accent.opacity(0.14))
                    )
                }
                .buttonStyle(.plain)
            }
            
            HStack(spacing: 18) {
                ZStack {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(AngelTheme.accentGradient)
                        .frame(width: 118, height: 118)
                        .shadow(color: AngelTheme.accent.opacity(0.3), radius: 16, y: 6)
                    
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundStyle(.black.opacity(0.8))
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Your Patch Library")
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text("\(allToggles.count) modules ready to review")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AngelTheme.secondary)
                    
                    Text(keyStatus.title)
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundStyle(keyStatus.color)
                }
                
                Spacer(minLength: 0)
            }
        }
        .padding(20)
        .angelCard()
    }
    
    // MARK: - Tarjeta Patches / Visuals
    
    private var patchesCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(selectedCategory.title)
                        .font(.system(size: 28, weight: .heavy))
                        .foregroundStyle(.white)
                    Text(selectedCategory.subtitle)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(AngelTheme.secondary)
                }
                
                Spacer()
                
                Text("\(activeCount)/\(toggles.count) ACTIVE")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(AngelTheme.accent)
                    .padding(.top, 6)
            }
            
            categoryPicker
            
            if toggles.isEmpty {
                Text("No hay opciones disponibles")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AngelTheme.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else {
                VStack(spacing: 4) {
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
            }
        }
        .padding(20)
        .angelCard()
    }
    
    // MARK: - Selector de categoría
    
    private var categoryPicker: some View {
        HStack(spacing: 10) {
            ForEach(PatchCategory.allCases) { category in
                let selected = selectedCategory == category
                
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedCategory = category
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: category.icon)
                            .font(.system(size: 14, weight: .semibold))
                        Text(category.title)
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundStyle(selected ? Color.black : Color.white.opacity(0.55))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .fill(
                                selected
                                    ? AnyShapeStyle(AngelTheme.accentGradient)
                                    : AnyShapeStyle(Color.white.opacity(0.07))
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Tarjeta de acceso
    
    private var accessCard: some View {
        let status = keyStatus
        
        return VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: status.icon)
                    .font(.system(size: 16, weight: .bold))
                Text(status.title)
                    .font(.system(size: 16, weight: .heavy))
            }
            .foregroundStyle(status.color)
            
            Text(status.detail)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
                .fixedSize(horizontal: false, vertical: true)
            
            HStack(spacing: 12) {
                Image(systemName: "key.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Remember key")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                    Text(supabase.currentKey?.keyValue ?? "SIN KEY")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(AngelTheme.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Apagarlo = quitar la key (pide confirmación)
                Toggle("", isOn: Binding(
                    get: { true },
                    set: { newValue in
                        if !newValue { showLogoutConfirmation = true }
                    }
                ))
                .labelsHidden()
                .tint(AngelTheme.accent)
                
                Button {
                    showLogoutConfirmation = true
                } label: {
                    Text("Remove key")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AngelTheme.danger)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .angelCard(tint: status.color.opacity(0.35))
    }
    
    // MARK: - Lógica de toggle
    
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
                            color: AngelTheme.danger
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
                        color: AngelTheme.accent
                    )
                }
            } catch let error as PatchPackageError {
                await MainActor.run {
                    processingToggles.remove(toggle.id)
                    showToast(
                        "Error: \(error.localizationKey)",
                        icon: "exclamationmark.triangle.fill",
                        color: AngelTheme.danger
                    )
                }
            } catch {
                await MainActor.run {
                    processingToggles.remove(toggle.id)
                    showToast(
                        "Error al activar el parche",
                        icon: "exclamationmark.triangle.fill",
                        color: AngelTheme.danger
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
                            color: .white.opacity(0.7)
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
                            color: .white.opacity(0.7)
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
                        color: .white.opacity(0.7)
                    )
                }
            } catch {
                await MainActor.run {
                    processingToggles.remove(toggle.id)
                    showToast(
                        "Error al desactivar",
                        icon: "exclamationmark.triangle.fill",
                        color: AngelTheme.danger
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

// MARK: - Fila de toggle

private struct ToggleRow: View {
    let toggle: PatchToggle
    let isOn: Bool
    let isProcessing: Bool
    let onToggle: (Bool) -> Void
    
    private var tint: Color {
        if toggle.isBlocked { return AngelTheme.warn }
        let palette: [Color] = [
            AngelTheme.accent,
            Color(red: 0.55, green: 0.60, blue: 1.00),
            Color(red: 1.00, green: 0.42, blue: 0.45),
            Color(red: 0.35, green: 0.80, blue: 0.75)
        ]
        let sum = toggle.id.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return palette[sum % palette.count]
    }
    
    /// "Aimbot cabeza (Sin Antena)" -> título "Aimbot cabeza", subtítulo "Sin Antena"
    private var parts: (title: String, subtitle: String) {
        let name = toggle.displayName
        if let open = name.firstIndex(of: "("),
           let close = name.lastIndex(of: ")"),
           open < close {
            let title = name[..<open].trimmingCharacters(in: .whitespaces)
            let sub = String(name[name.index(after: open)..<close])
            if !title.isEmpty {
                return (title, sub)
            }
        }
        return (name, toggle.category == .aimbot ? "Gameplay control" : "Visual option")
    }
    
    var body: some View {
        Button {
            onToggle(!isOn)
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(tint.opacity(0.16))
                        .frame(width: 52, height: 52)
                    
                    if isProcessing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: toggle.isBlocked ? "lock.fill" : toggle.icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(tint)
                    }
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(parts.title.uppercased())
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(toggle.isBlocked ? .white.opacity(0.5) : .white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    Text(toggle.isBlocked ? "En mantenimiento" : parts.subtitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(
                            toggle.isBlocked
                                ? AngelTheme.warn.opacity(0.85)
                                : AngelTheme.secondary
                        )
                        .lineLimit(1)
                }
                
                Spacer(minLength: 8)
                
                Text(toggle.isBlocked ? "LOCK" : (isOn ? "ON" : "OFF"))
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(
                        toggle.isBlocked
                            ? AngelTheme.warn
                            : (isOn ? Color.black : Color.white.opacity(0.55))
                    )
                    .frame(minWidth: 44)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule().fill(
                            toggle.isBlocked
                                ? AnyShapeStyle(AngelTheme.warn.opacity(0.15))
                                : (isOn
                                    ? AnyShapeStyle(AngelTheme.accentGradient)
                                    : AnyShapeStyle(Color.white.opacity(0.09)))
                        )
                    )
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white.opacity(0.3))
            }
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isProcessing)
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
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(AngelTheme.card.opacity(0.97))
                .overlay(
                    Capsule()
                        .stroke(AngelTheme.accent.opacity(0.35), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.6), radius: 12, y: 4)
        )
    }
}