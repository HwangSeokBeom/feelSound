import Foundation
import CoreML

final class EmotionAnalyzer {
    private let tokenizer: WordPieceTokenizer
    private let model: MLModel
    private let labels = ["negative", "neutral", "positive"]
    private let maxLength = 128

    init() {
        guard let tokenizerURL = Bundle.main.url(forResource: "tokenizer", withExtension: "json") else {
            fatalError("❌ tokenizer.json not found in bundle")
        }

        guard let modelURL = Bundle.main.url(forResource: "kc_electra_nsmc", withExtension: "mlmodelc") else {
            fatalError("❌ kc_electra_nsmc.mlmodelc not found in bundle")
        }

        do {
            self.tokenizer = try WordPieceTokenizer(jsonURL: tokenizerURL)
            self.model = try MLModel(contentsOf: modelURL)

            for (name, input) in model.modelDescription.inputDescriptionsByName {
                print("📥 Input name: \(name), shape: \(input.multiArrayConstraint?.shape ?? [])")
            }

        } catch {
            fatalError("❌ 모델 로딩 실패: \(error.localizedDescription)")
        }
    }

    func analyze(text: String) -> String? {
        let tokens = tokenizer.tokenize(text)
        print("📌 Tokenized: \(tokens)")

        let clsId = tokenizer.vocab["[CLS]"] ?? 101
        let sepId = tokenizer.vocab["[SEP]"] ?? 102
        var tokenIds = [clsId] + tokenizer.convertTokensToIds(tokens) + [sepId]

        if tokenIds.count < maxLength {
            tokenIds += Array(repeating: 0, count: maxLength - tokenIds.count)
        } else {
            tokenIds = Array(tokenIds.prefix(maxLength))
        }

        guard let inputArray = try? MLMultiArray(shape: [1, maxLength as NSNumber], dataType: .int32),
              let attentionArray = try? MLMultiArray(shape: [1, maxLength as NSNumber], dataType: .int32) else {
            print("❌ MLMultiArray 생성 실패")
            return nil
        }

        for i in 0..<maxLength {
            inputArray[i] = NSNumber(value: tokenIds[i])
            attentionArray[i] = NSNumber(value: tokenIds[i] == 0 ? 0 : 1)
        }

        do {
            let inputFeatures = try MLDictionaryFeatureProvider(dictionary: [
                "input_ids": MLFeatureValue(multiArray: inputArray),
                "attention_mask": MLFeatureValue(multiArray: attentionArray)
            ])
            let prediction = try model.prediction(from: inputFeatures)

            guard let logits = prediction.featureValue(for: "logits")?.multiArrayValue else {
                print("❌ logits 추출 실패")
                return nil
            }

            let values = (0..<logits.count).map { logits[$0].doubleValue }
            print("📊 Logits: \(values)")
            let maxIndex = values.indices.max(by: { values[$0] < values[$1] }) ?? 0
            return labels.indices.contains(maxIndex) ? labels[maxIndex] : nil

        } catch {
            print("❌ 모델 추론 중 에러 발생: \(error)")
            return nil
        }
    }
}
