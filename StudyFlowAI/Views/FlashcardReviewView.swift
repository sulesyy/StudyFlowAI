import SwiftUI

struct FlashcardReviewView: View {
    @State private var cards = FlashcardReviewStore.dueCards()
    @State private var isShowingAnswer = false
    @State private var sessionTotal = 0

    private var current: SavedReviewCard? { cards.first }

    var body: some View {
        Group {
            if let card = current {
                VStack(spacing: 22) {
                    Text("Bugün tekrar: \(cards.count) kart")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    ProgressView(value: Double(max(sessionTotal - cards.count, 0)),
                                 total: Double(max(sessionTotal, 1)))
                    Text(card.deckTitle.uppercased())
                        .font(.caption.weight(.bold)).tracking(1)
                        .foregroundStyle(.secondary)
                    Button { withAnimation { isShowingAnswer.toggle() } } label: {
                        VStack(spacing: 16) {
                            Image(systemName: isShowingAnswer ? "checkmark.circle.fill" : "rectangle.on.rectangle")
                                .font(.largeTitle).foregroundStyle(.indigo)
                            Text(isShowingAnswer ? "Cevap" : "Soru")
                                .font(.headline).foregroundStyle(.secondary)
                            Text(isShowingAnswer ? card.answer : card.question)
                                .font(.title2.weight(.semibold)).multilineTextAlignment(.center)
                                .foregroundStyle(.primary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 280)
                        .padding(22)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("reviewCard")
                    if isShowingAnswer {
                        HStack(spacing: 14) {
                            Button("Tekrar et") { mark(remembered: false) }
                                .buttonStyle(.bordered)
                            Button("Biliyordum") { mark(remembered: true) }
                                .buttonStyle(.borderedProminent)
                        }
                    } else {
                        Text("Yanıtı görmek için karta dokun.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(22)
            } else {
                ContentUnavailableView("Tekrar bekleyen kart yok",
                                       systemImage: "checkmark.circle",
                                       description: Text("Yeni çalışma kartları oluşturduğunda veya tekrar zamanı geldiğinde burada görünür."))
            }
        }
        .navigationTitle("Akıllı tekrar")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { if sessionTotal == 0 { sessionTotal = cards.count } }
    }

    private func mark(remembered: Bool) {
        guard let card = current else { return }
        FlashcardReviewStore.review(id: card.id, remembered: remembered)
        withAnimation {
            cards.removeFirst()
            isShowingAnswer = false
        }
    }
}
