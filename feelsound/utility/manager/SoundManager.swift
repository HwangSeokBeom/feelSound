//
//  SoundManager.swift
//  feelsound
//
//  Created by 심소영 on 5/8/25.
//

import Foundation
import AVFoundation

enum SoundExtension : String{
    case wav = ".wav"
    case mp3 = ".mp3"
}

class SoundManager {
    static let instance = SoundManager()
    
    var player : AVAudioPlayer?
    var session: AVAudioSession?

    func playSound(sound : SoundOption, soundExtension : SoundExtension, loop : Int = 0){
        guard let url = Bundle.main.url(forResource: sound.rawValue, withExtension: soundExtension.rawValue) else {return}
        
        do {
    
            session = AVAudioSession.sharedInstance()

            try session?.setCategory(.playback, mode: .default)
            try session?.setActive(true)
            
            player = try AVAudioPlayer(contentsOf: url)
            player?.numberOfLoops = loop
            player?.play()
        }catch let error {
            print("error\(error)")
        }
    }
}

enum SoundOption : String {
    case confetti = "Confetti"
    case stars = "Progress Stars"
    case politeChicky = "Polite Chicky"
    case timesup = "timesup"
    case tada = "tada"
    case winner = "winner"
    case second = "2nd"
    case third = "3rd"
    case fourth = "4th"
    case unlock = "unlock"
    case pop1 = "Balloon Pop 01"
    case pop2 = "Balloon Pop 02"
    case pop3 = "Click Pop"
    case giggle = "Cheeky Imp Giggle"
    case roll = "21551 single frog croak-full"
    case kiss1 = "05588 cartoon catapult"
    case kiss2 = "Funny Cartoon Kiss"
    case kiss3 = "Big Cartoon Kiss"
    case kiss4 = "Cartoon Kiss 1"
    case kiss5 = "Cartoon Kiss 2"
    case kiss6 = "Cartoon Voice No v1"
    case kiss7 = "Cartoon Voice No v2"
    case surprise1 = "17953 cartoon bug surprised-full"
    case surprise2 = "16222 cartoon cute surprise scream"
    case pinch = "el_synthefx_boing_06_hpx"
    case puzzle = "Puzzle Piece Connect"
    case bubble = "bubble-wrap"
    case angry = "19644 cute crocodile ouch-full"
    case angry1 = "19643 cute crocodile pain-full"
    case tired1 = "tired1"
    case tired2 = "tired2"
    case tired3 = "tired3"
    case tired4 = "tired4"
    case embarrassed = "embarrassed"
    case coin = "Money 01"
    case coin2 = "Money 02"
    case coin3 = "Coin"
    case tone1 = "pianoPlayful"
    case tone2 = "MusicLogoPianoTin SDT041102"
    case drumstick1 = "Drum Sticks Four Count Off With Voice 2"
    case drumstick2 = "Drum Sticks Four Count Off"
    case drumstick3 = "DrumSticks IE02_44_4"
    case drumstick4 = "Little Drum Beat 4"
    case crack1 = "Egg Crack 01"
    case crack2 = "Egg Crack 02"
    case crack3 = "Egg Crack 03"
    case crack4 = "Egg Crack 04"
    case crack5 = "Egg Crack 05"
}
