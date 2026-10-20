import Foundation

struct SavedReviewCard: Codable, Identifiable {
    let id: UUID
    let deckTitle: String
    let question: String
    let answer: String
    var dueAt: Date
    var intervalDays: Int
    var reviewCount: Int

    init(id: UUID = UUID(), deckTitle: String, question: String, answer: String,
         dueAt: Date = .now, intervalDays: Int = 0, reviewCount: Int = 0) {
        self.id = id
        self.deckTitle = deckTitle
        self.question = question
        self.answer = answer
        self.dueAt = dueAt
        self.intervalDays = intervalDays
        self.reviewCount = reviewCount
    }
}

enum FlashcardReviewStore {
    private static let key = "StudyFlowReviewCards"

    static func allCards() -> [SavedReviewCard] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let cards = try? JSONDecoder().decode([SavedReviewCard].self, from: data) else { return [] }
        return cards
    }

    static func dueCards(now: Date = .now) -> [SavedReviewCard] {
        allCards().filter { $0.dueAt <= now }.sorted { $0.dueAt < $1.dueAt }
    }

    static func saveDeck(title: String, questions: [(String, String)]) {
        var cards = allCards()
        let existing = cards.filter { $0.deckTitle == title }
        cards.removeAll { $0.deckTitle == title }
        var byQuestion: [String: SavedReviewCard] = [:]
        existing.forEach { byQuestion[$0.question] = $0 }
        cards.append(contentsOf: questions.map { question, answer in
            if var saved = byQuestion[question] {
                saved = SavedReviewCard(id: saved.id, deckTitle: title, question: question,
                                        answer: answer, dueAt: saved.dueAt,
                                        intervalDays: saved.intervalDays, reviewCount: saved.reviewCount)
                return saved
            }
            return SavedReviewCard(deckTitle: title, question: question, answer: answer)
        })
        persist(cards)
    }

    static func review(id: UUID, remembered: Bool, now: Date = .now) {
        var cards = allCards()
        guard let index = cards.firstIndex(where: { $0.id == id }) else { return }
        if remembered {
            let nextInterval: Int
            switch cards[index].reviewCount {
            case 0: nextInterval = 1
            case 1: nextInterval = 3
            default: nextInterval = min(max(cards[index].intervalDays * 2, 6), 60)
            }
            cards[index].intervalDays = nextInterval
            cards[index].reviewCount += 1
            cards[index].dueAt = Calendar.current.date(byAdding: .day, value: nextInterval, to: now) ?? now
        } else {
            cards[index].dueAt = Calendar.current.date(byAdding: .minute, value: 10, to: now) ?? now
            cards[index].intervalDays = 0
            cards[index].reviewCount = 0
        }
        persist(cards)
    }

    static func restore(_ cards: [SavedReviewCard]) { persist(cards) }

    private static func persist(_ cards: [SavedReviewCard]) {
        guard let data = try? JSONEncoder().encode(cards) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
