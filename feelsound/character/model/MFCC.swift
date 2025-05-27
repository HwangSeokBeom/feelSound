//
//  Untitled.swift
//  feelsound
//
//  Created by Hwangseokbeom on 5/23/25.
//

import Accelerate

public class MFCC {
    private let numberOfCoefficients: Int
    private let fftSize: Int
    private let hopSize: Int
    private let sampleRate: Double

    public init?(
        numberOfCoefficients: Int = 26,
        windowSize: Int = 512,
        hopSize: Int = 256,
        sampleRate: Double = 16000.0
    ) {
        self.numberOfCoefficients = numberOfCoefficients
        self.fftSize = windowSize
        self.hopSize = hopSize
        self.sampleRate = sampleRate
    }

    public func process(_ signal: [Float]) -> [[Float]] {
        guard signal.count >= fftSize else { return [] }

        var mfccs: [[Float]] = []

        let frameCount = (signal.count - fftSize) / hopSize + 1

        for i in 0..<frameCount {
            let start = i * hopSize
            let end = start + fftSize
            let frame = Array(signal[start..<end])

            if let mfcc = computeMFCC(frame: frame) {
                mfccs.append(mfcc)
            }
        }

        return mfccs
    }

    private func computeMFCC(frame: [Float]) -> [Float]? {
        // 1. Apply window
        var windowed = frame
        var window = [Float](repeating: 0.0, count: fftSize)
        vDSP_hann_window(&window, vDSP_Length(fftSize), Int32(vDSP_HANN_NORM))
        vDSP_vmul(frame, 1, window, 1, &windowed, 1, vDSP_Length(fftSize))

        // 2. FFT
        var real = [Float](repeating: 0.0, count: fftSize / 2)
        var imag = [Float](repeating: 0.0, count: fftSize / 2)
        var splitComplex = DSPSplitComplex(realp: &real, imagp: &imag)
        let log2n = UInt(round(log2(Double(fftSize))))
        guard let fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2)) else {
            return nil
        }

        windowed.withUnsafeBufferPointer { ptr in
            ptr.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: fftSize) { complexPtr in
                vDSP_ctoz(complexPtr, 2, &splitComplex, 1, vDSP_Length(fftSize / 2))
            }
        }

        vDSP_fft_zrip(fftSetup, &splitComplex, 1, log2n, FFTDirection(FFT_FORWARD))

        // 3. Power spectrum
        var power = [Float](repeating: 0.0, count: fftSize / 2)
        vDSP_zvmags(&splitComplex, 1, &power, 1, vDSP_Length(fftSize / 2))

        // 4. Log (optional, for simplicity we just use raw power spectrum here)
        vDSP_destroy_fftsetup(fftSetup)

        // 5. Truncate or pad to desired MFCC dimension
        let mfcc = Array(power.prefix(numberOfCoefficients))
        return mfcc
    }
}
