import Foundation
import Combine
import CryptoKit

// MARK: - Modelo remoto

struct RemotePatch: Codable, Identifiable {
    let id: String
    let patchKey: String
    let displayName: String
    let patchFilename: String
    let category: String
    let mode: String
    let icon: String
    let downloadUrl: String?
    let fileHash: String?
    let fileSize: Int64?
    let version: Int
    let isActive: Bool
    let isBlocked: Bool
    let blockMessage: String?
    let sortOrder: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case patchKey = "patch_key"
        case displayName = "display_name"
        case patchFilename = "patch_filename"
        case category
        case mode
        case icon
        case downloadUrl = "download_url"
        case fileHash = "file_hash"
        case fileSize = "file_size"
        case version
        case isActive = "is_active"
        case isBlocked = "is_blocked"
        case blockMessage = "block_message"
        case sortOrder = "sort_order"
    }
}

// MARK: - Store

@MainActor
final class PatchesStore: ObservableObject {
    
    @Published var remotePatches: [RemotePatch] = []
    @Published var isLoading: Bool = false
    @Published var loadError: String?
    
    private let supabaseURL = SupabaseService.supabaseURL
    private let supabaseAnonKey = SupabaseService.supabaseAnonKey
    
    // MARK: - Directorio de cache
    
    private var patchesDirectoryURL: URL {
        let documents = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]
        let dir = documents.appendingPathComponent("RemotePatches", isDirectory: true)
        try? FileManager.default.createDirectory(
            at: dir,
            withIntermediateDirectories: true
        )
        return dir
    }
    
    // MARK: - Fetch
    
    func fetchPatches() async throws -> [RemotePatch] {
        guard let url = URL(string: "\(supabaseURL)/rest/v1/patches?is_active=eq.true&order=sort_order.asc") else {
            throw NSError(domain: "PatchesStore", code: -1)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw NSError(domain: "PatchesStore", code: -2)
        }
        
        let patches = try JSONDecoder().decode([RemotePatch].self, from: data)
        self.remotePatches = patches
        return patches
    }
    
    // MARK: - Download
    
    func downloadPatch(_ patch: RemotePatch, onProgress: ((Double) -> Void)? = nil) async throws {
        guard let urlString = patch.downloadUrl,
              let url = URL(string: urlString) else {
            throw NSError(domain: "PatchesStore", code: -3)
        }
        
        let localURL = localPatchURL(for: patch)
        
        // Si ya existe y el hash coincide, no descargar
        if FileManager.default.fileExists(atPath: localURL.path) {
            log("patches: \(patch.patchFilename) ya existe localmente")
            // 🎯 Asegurar que también está en PatchProjects
            try? copyToPatchProjects(from: localURL, patch: patch)
            onProgress?(1.0)
            return
        }
        
        log("patches: descargando \(patch.patchFilename)")
        
        let (tempURL, response) = try await URLSession.shared.download(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw NSError(domain: "PatchesStore", code: -4)
        }
        
        try? FileManager.default.removeItem(at: localURL)
        try FileManager.default.moveItem(at: tempURL, to: localURL)
        
        // 🎯 NUEVO: Copiar a la carpeta de 3105
        try copyToPatchProjects(from: localURL, patch: patch)
        
        onProgress?(1.0)
        log("patches: ✓ \(patch.patchFilename) descargado y copiado")
    }
    
    // 🎯 NUEVA FUNCIÓN: Copiar a la carpeta que usa 3105
    private func copyToPatchProjects(from sourceURL: URL, patch: RemotePatch) throws {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]
        let patchProjects = appSupport.appendingPathComponent("PatchProjects", isDirectory: true)
        try FileManager.default.createDirectory(
            at: patchProjects,
            withIntermediateDirectories: true
        )
        
        let filename = "\(patch.patchFilename).3105"
        let destination = patchProjects.appendingPathComponent(filename)
        
        // Si ya existe, comprobar hash
        if FileManager.default.fileExists(atPath: destination.path) {
            if let sourceData = try? Data(contentsOf: sourceURL),
               let destData = try? Data(contentsOf: destination),
               sourceData == destData {
                log("patches: \(filename) ya está copiado en PatchProjects")
                return
            }
            try? FileManager.default.removeItem(at: destination)
        }
        
        try FileManager.default.copyItem(at: sourceURL, to: destination)
        log("patches: 📋 copiado a PatchProjects: \(filename)")
    }
    
    // MARK: - Download All
    
    func downloadAllPatches(
        _ patches: [RemotePatch],
        onEachProgress: ((Int, Int, String) -> Void)? = nil,
        onOverallProgress: ((Double) -> Void)? = nil
    ) async {
        let total = patches.count
        guard total > 0 else { return }
        
        for (index, patch) in patches.enumerated() {
            onEachProgress?(index + 1, total, patch.displayName)
            
            do {
                try await downloadPatch(patch)
            } catch {
                log("patches: error descargando \(patch.patchFilename): \(error)")
            }
            
            let overallProgress = Double(index + 1) / Double(total)
            onOverallProgress?(overallProgress)
        }
    }
    
    // MARK: - Helpers
    
    func localPatchURL(for patch: RemotePatch) -> URL {
        return patchesDirectoryURL
            .appendingPathComponent("\(patch.patchFilename).3105")
    }
    
    func patchExistsLocally(_ patch: RemotePatch) -> Bool {
        return FileManager.default.fileExists(atPath: localPatchURL(for: patch).path)
    }
}
