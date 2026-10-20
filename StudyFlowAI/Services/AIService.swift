import Foundation

final class AIService {
    static let shared = AIService()
    private init() {}

    private struct ProxyRequest: Encodable { let prompt: String }
    private struct ProxyResponse: Decodable {
        let text: String?
        let error: String?
    }

    private enum ServiceError: LocalizedError {
        case emptyInput
        case badResponse
        case server(String)
        case invalidAIOutput

        var errorDescription: String? {
            switch self {
            case .emptyInput: return "Lütfen önce konu veya PDF metni gir."
            case .badResponse: return "AI sunucusundan geçerli bir yanıt alınamadı."
            case .server(let message): return message
            case .invalidAIOutput: return "Yapay zekâ beklenen biçimde yanıt vermedi. Tekrar deneyebilirsin."
            }
        }
    }

    private func sendPrompt(_ prompt: String, cacheResult: Bool = false) async throws -> String {
        let prompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else { throw ServiceError.emptyInput }
        if cacheResult, let cached = AIContentCache.response(for: prompt) { return cached }
        guard let url = URL(string: AppConfiguration.aiProxyURL) else { throw ServiceError.badResponse }

        var request = URLRequest(url: url, timeoutInterval: 90)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(ProxyRequest(prompt: prompt))

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw ServiceError.badResponse }
        let payload = try? JSONDecoder().decode(ProxyResponse.self, from: data)
        guard (200..<300).contains(http.statusCode) else {
            let providerMessage = payload?.error ?? ""
            let lowercased = providerMessage.lowercased()
            if http.statusCode == 429 || lowercased.contains("quota") || lowercased.contains("rate limit") {
                throw ServiceError.server("Gemini kullanım kotası doldu. Kota yenilendiğinde tekrar deneyebilirsin. Daha önce oluşturduğun konu içerikleri bu cihazda saklanır.")
            }
            throw ServiceError.server(providerMessage.isEmpty ? "AI isteği başarısız oldu (\(http.statusCode))." : providerMessage)
        }
        guard let text = payload?.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else {
            throw ServiceError.badResponse
        }
        if cacheResult { AIContentCache.save(text, for: prompt) }
        return text
    }

    private func decodeJSON<T: Decodable>(_ type: T.Type, from response: String) throws -> T {
        var cleaned = response.trimmingCharacters(in: .whitespacesAndNewlines)
        cleaned = cleaned.replacingOccurrences(of: "```json", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if let first = cleaned.firstIndex(of: "{"), let last = cleaned.lastIndex(of: "}"), first <= last {
            cleaned = String(cleaned[first...last])
        }
        guard let data = cleaned.data(using: .utf8) else { throw ServiceError.invalidAIOutput }
        do { return try JSONDecoder().decode(type, from: data) }
        catch { throw ServiceError.invalidAIOutput }
    }

    private func validateQuiz(_ questions: [QuizQuestion]) throws -> [QuizQuestion] {
        guard questions.count == 5,
              questions.allSatisfy({ !$0.question.isEmpty && $0.options.count == 4 && $0.answer >= 0 && $0.answer < $0.options.count })
        else { throw ServiceError.invalidAIOutput }
        return questions
    }

    private func validateFlashcards(_ cards: [Flashcard]) throws -> [Flashcard] {
        guard cards.count == 10, cards.allSatisfy({ !$0.question.isEmpty && !$0.answer.isEmpty })
        else { throw ServiceError.invalidAIOutput }
        return cards
    }

    private func validatePDFText(_ text: String) throws -> String {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { throw ServiceError.emptyInput }
        guard text.count <= 150_000 else { throw ServiceError.server("PDF metni çok uzun. Daha küçük bir dosya seç.") }
        return text
    }

    func generateSummary(for topic: String) async throws -> String {
        let summary = try await sendPrompt("""
        Sen deneyimli bir öğretmensin. "\(topic)" konusunu kolay anlaşılır, maddeler halinde, örneklerle ve yaklaşık 250 kelimeyle açıkla.
        """, cacheResult: true)
        AIContentCache.saveToLibrary(title: topic, kind: "Konu özeti", text: summary)
        return summary
    }

    func generateQuiz(for topic: String) async throws -> [QuizQuestion] {
        let response = try await sendPrompt("""
        "\(topic)" konusu hakkında tam olarak 5 adet, dörder seçenekli çoktan seçmeli soru oluştur. Cevap alanı sıfır tabanlı doğru seçenek indeksi olsun. Sadece bu JSON'u döndür: {"questions":[{"question":"...","options":["...","...","...","..."],"answer":0}]}. Markdown veya açıklama ekleme.
        """, cacheResult: true)
        let result = try decodeJSON(QuizResponse.self, from: response)
        let questions = try validateQuiz(result.questions)
        let readable = questions.enumerated().map { index, question in
            let labels = ["A", "B", "C", "D"]
            let choices = question.options.enumerated().map { "\(labels[$0.offset]). \($0.element)" }.joined(separator: "\n")
            return "\(index + 1). \(question.question)\n\(choices)\nDoğru yanıt: \(question.options[question.answer])"
        }.joined(separator: "\n\n")
        AIContentCache.saveToLibrary(title: topic, kind: "Quiz", text: readable)
        return questions
    }

    func generateFlashcards(for topic: String) async throws -> [Flashcard] {
        let response = try await sendPrompt("""
        "\(topic)" konusu için tam olarak 10 flashcard oluştur. Sadece şu JSON biçimini döndür: {"flashcards":[{"question":"...","answer":"..."}]}. Markdown veya açıklama ekleme.
        """, cacheResult: true)
        let result = try decodeJSON(FlashcardResponse.self, from: response)
        let cards = try validateFlashcards(result.flashcards)
        let readable = cards.enumerated().map { index, card in
            "Kart \(index + 1)\nSoru: \(card.question)\nCevap: \(card.answer)"
        }.joined(separator: "\n\n")
        AIContentCache.saveToLibrary(title: topic, kind: "Çalışma kartları", text: readable)
        return cards
    }

    func generateDailySuggestion() async throws -> String {
        let suggestion = try await sendPrompt("""
        Üniversite öğrencisi için Türkçe, en fazla 120 kelimelik bugünkü çalışma planı oluştur. Üç konuya 30, 25 ve 20 dakika ayır ve sonunda kısa bir motivasyon cümlesi ekle.
        """)
        AIContentCache.saveToLibrary(title: "Günlük çalışma önerisi", kind: "Günlük öneri", text: suggestion)
        return suggestion
    }

    func summarizePDF(text: String) async throws -> String {
        let text = try validatePDFText(text)
        return try await sendPrompt("Aşağıdaki ders notunu Türkçe ve yaklaşık 250 kelimeyle özetle:\n\n\(text)")
    }

    func generateQuizFromPDF(text: String) async throws -> [QuizQuestion] {
        let text = try validatePDFText(text)
        let response = try await sendPrompt("""
        Aşağıdaki ders notundan tam olarak 5 adet, dörder seçenekli çoktan seçmeli soru oluştur. Cevap alanı sıfır tabanlı doğru seçenek indeksi olsun. Sadece şu JSON'u döndür: {"questions":[{"question":"...","options":["...","...","...","..."],"answer":0}]}. Markdown veya açıklama ekleme.\n\nDers notu:\n\(text)
        """)
        let result = try decodeJSON(QuizResponse.self, from: response)
        return try validateQuiz(result.questions)
    }

    func generateFlashcardsFromPDF(text: String) async throws -> [Flashcard] {
        let text = try validatePDFText(text)
        let response = try await sendPrompt("""
        Aşağıdaki ders notundan tam olarak 10 flashcard oluştur. Sadece şu JSON biçimini döndür: {"flashcards":[{"question":"...","answer":"..."}]}. Markdown veya açıklama ekleme.\n\nDers notu:\n\(text)
        """)
        let result = try decodeJSON(FlashcardResponse.self, from: response)
        return try validateFlashcards(result.flashcards)
    }

    func askPDF(question: String, pdfText: String, history: [ChatMessage]) async throws -> String {
        let text = try validatePDFText(pdfText)
        let question = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty else { throw ServiceError.emptyInput }
        let conversation = history.suffix(12).map { $0.isUser ? "Kullanıcı: \($0.text)" : "Asistan: \($0.text)" }.joined(separator: "\n")
        return try await sendPrompt("""
        StudyFlow AI eğitim asistanısın. Yalnızca PDF içeriğine dayanarak Türkçe ve öğretici cevap ver; cevap PDF'de yoksa bunu belirt.\n\nPDF:\n\(text)\n\nÖnceki konuşma:\n\(conversation)\n\nYeni soru:\n\(question)
        """)
    }
}
