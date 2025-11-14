import Foundation

class WebContentFetcher {

    enum FetchError: Error, LocalizedError {
        case invalidURL
        case noData
        case networkError(Error)
        case parsingError

        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "La URL proporcionada no es válida"
            case .noData:
                return "No se pudo obtener contenido de la página"
            case .networkError(let error):
                return "Error de red: \(error.localizedDescription)"
            case .parsingError:
                return "No se pudo extraer el texto de la página"
            }
        }
    }

    func fetchText(from urlString: String) async throws -> String {
        // Validar y crear URL
        guard let url = URL(string: urlString) else {
            throw FetchError.invalidURL
        }

        do {
            // Descargar contenido HTML
            let (data, _) = try await URLSession.shared.data(from: url)

            guard let html = String(data: data, encoding: .utf8) else {
                throw FetchError.noData
            }

            // Extraer texto del HTML
            let cleanText = extractText(from: html)

            if cleanText.isEmpty {
                throw FetchError.parsingError
            }

            return cleanText

        } catch let error as FetchError {
            throw error
        } catch {
            throw FetchError.networkError(error)
        }
    }

    private func extractText(from html: String) -> String {
        var text = html

        // Remover scripts y styles
        text = text.replacingOccurrences(
            of: "<script[^>]*>[\\s\\S]*?</script>",
            with: "",
            options: .regularExpression
        )
        text = text.replacingOccurrences(
            of: "<style[^>]*>[\\s\\S]*?</style>",
            with: "",
            options: .regularExpression
        )

        // Remover todas las etiquetas HTML
        text = text.replacingOccurrences(
            of: "<[^>]+>",
            with: " ",
            options: .regularExpression
        )

        // Decodificar entidades HTML comunes
        let entities = [
            "&nbsp;": " ",
            "&amp;": "&",
            "&quot;": "\"",
            "&apos;": "'",
            "&lt;": "<",
            "&gt;": ">",
            "&#39;": "'",
            "&mdash;": "—",
            "&ndash;": "–"
        ]

        for (entity, character) in entities {
            text = text.replacingOccurrences(of: entity, with: character)
        }

        // Limpiar espacios en blanco excesivos
        text = text.replacingOccurrences(
            of: "\\s+",
            with: " ",
            options: .regularExpression
        )

        // Limpiar líneas vacías múltiples
        text = text.replacingOccurrences(
            of: "\\n\\s*\\n",
            with: "\n\n",
            options: .regularExpression
        )

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
