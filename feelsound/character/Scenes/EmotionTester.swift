import Foundation

final class EmotionTester {
    private let analyzer: EmotionAnalyzer

    init(analyzer: EmotionAnalyzer) {
        self.analyzer = analyzer
    }

    func runTest() {
        let testSentences = [
            "정말 기뻐요!",
            "오늘 너무 우울해.",
            "진짜 화난다.",
            "세상이 너무 아름다워.",
            "그냥 그래요.",
            "별 감흥이 없었어.",
            "이건 좀 별로야.",
            "기대 이상이었어!",
            "짜증나.",
            "와 진짜 감동이에요."
        ]

        print("🧪 감정 분석 테스트 시작\n------------------------------")
        for sentence in testSentences {
            print("🗣️ 문장: '\(sentence)'")
            if let result = analyzer.analyze(text: sentence) {
                print("✅ 예측 감정: \(result)\n------------------------------")
            } else {
                print("❌ 예측 실패: 분석 중 오류 발생\n------------------------------")
            }
        }
    }
}
