import Foundation
import SwiftUI
import Combine

// MARK: - Modelo para items guardados en el historial

struct SavedItem: Identifiable, Codable, Equatable {
    let id: UUID
    let content: String
    let sourceURL: String?
    let timestamp: Date
    let title: String

    init(id: UUID = UUID(), content: String, sourceURL: String? = nil, title: String? = nil) {
        self.id = id
        self.content = content
        self.sourceURL = sourceURL
        self.timestamp = Date()

        // Generar título automático si no se proporciona
        if let title = title, !title.isEmpty {
            self.title = title
        } else if let url = sourceURL {
            self.title = url
        } else {
            // Usar las primeras palabras del contenido
            let preview = String(content.prefix(50))
            self.title = preview + (content.count > 50 ? "..." : "")
        }
    }
}

// MARK: - Manager para persistencia de datos

class HistoryManager: NSObject, ObservableObject {
    @Published var savedItems: [SavedItem] = []

    private let userDefaultsKey = "SavedItemsHistory"

    override init() {
        super.init()
        loadItems()
    }

    // Guardar un nuevo item
    func saveItem(_ item: SavedItem) {
        // Verificar si ya existe (evitar duplicados)
        if !savedItems.contains(where: { $0.content == item.content }) {
            savedItems.insert(item, at: 0) // Agregar al inicio
            persist()
        }
    }

    // Eliminar un item
    func deleteItem(_ item: SavedItem) {
        savedItems.removeAll { $0.id == item.id }
        persist()
    }

    // Limpiar todo el historial
    func clearHistory() {
        savedItems.removeAll()
        persist()
    }

    // MARK: - Persistencia

    private func persist() {
        if let encoded = try? JSONEncoder().encode(savedItems) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }

    private func loadItems() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([SavedItem].self, from: data) {
            savedItems = decoded
        }
    }
}
