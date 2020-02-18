//
//  ViewController.swift
//  SpeechToText
//
//  Created by MAC0008 on 18/02/20.
//  Copyright © 2020 MAC0008. All rights reserved.
//

import UIKit
import Speech

class ViewController: UIViewController, SFSpeechRecognizerDelegate {
    
    @IBOutlet weak var txtSpeech: UITextField!
    @IBOutlet weak var microphoneButton: UIButton!
    
    ///This object handles the speech recognition requests. It provides an audio input to the speech recognizer.
    private var recognitionRequest : SFSpeechAudioBufferRecognitionRequest?
    
    ///The recognition task where it gives you the result of the recognition request. Having this object is handy as you can cancel or stop the task.
    private var recognitionTask: SFSpeechRecognitionTask?
    
    ///This is your audio engine. It is responsible for providing your audio input.
    private let audioEngine = AVAudioEngine()
    

    private let speechRecognizer =  SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))
    
    let speechSynthesizer = AVSpeechSynthesizer() //Text To speech
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        microphoneButton.isEnabled = false
        
        speechRecognizer?.delegate = self
        SFSpeechRecognizer.requestAuthorization({(authStatus) in
            var isButtonEnabled = false
        
            switch authStatus{
            case .authorized:
                isButtonEnabled = true
            case .notDetermined:
                isButtonEnabled = false
                print("Speech recognition not yet authorized")
                
            case .denied:
                isButtonEnabled = false
                print("User denied access to speech recognition")
            case .restricted:
                isButtonEnabled = false
                print("Speech recognition restricted on this device")
            @unknown default:
                fatalError()
            }
            
            OperationQueue.main.addOperation() {
                self.microphoneButton.isEnabled = isButtonEnabled
            }
        })
    }

    
    @IBAction func btnSpeakOnClick(_ sender: Any) {
        ///In this function, we must check whether our audioEngine is running. If it is running, the app should stop the audioEngine, terminate the input audio to our recognitionRequest, disable our microphoneButton, and set the button’s title to “Start Recording”.
        
        ///If the audioEngine is working, the app should call startRecording() and set the title of the title of the button to “Stop Recording”.
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            microphoneButton.isEnabled = false
            microphoneButton.setTitle("Start Recording", for: .normal)
        } else {
            startRecording()
            microphoneButton.setTitle("Stop Recording", for: .normal)
        }
    }
    
    @IBAction func btnSaveOnClick(_ sender: Any) {
        
        //Text To Speech
        let speechUtterance = AVSpeechUtterance(string: txtSpeech.text ?? "Please enter Text or speak text")
        
        //        speechUtterance.rate = 0.25
        //        speechUtterance.pitchMultiplier = 0.25
        //        speechUtterance.volume = 0.75
        
        speechSynthesizer.speak(speechUtterance)
    }
    
    @IBAction func btnStopSpeech(_ sender: Any) {
        
        //Stop Speech
        speechSynthesizer.stopSpeaking(at: AVSpeechBoundary.immediate)
    }
    
    func startRecording(){
        
        ///Check if recognitionTask is running. If so, cancel the task and the recognition.
        if recognitionTask != nil{
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        ///Create an AVAudioSession to prepare for the audio recording. Here we set the category of the session as recording, the mode as measurement, and activate it. Note that setting these properties may throw an exception, so you must put it in a try catch clause.
        let audioSession = AVAudioSession.sharedInstance()
        do{
            try audioSession.setCategory(.playAndRecord)
            try audioSession.setMode(.measurement)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        }
        catch {
            print("audioSession properties weren't set because of an error.")
        }
        
        
        ///Instantiate the recognitionRequest. Here we create the SFSpeechAudioBufferRecognitionRequest object. Later, we use it to pass our audio data to Apple’s servers.
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
    
        ///Check if the audioEngine (your device) has an audio input for recording. If not, we report a fatal error.
        let inputNode = audioEngine.inputNode
    
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        
        ///Check if the audioEngine (your device) has an audio input for recording. If not, we report a fatal error.
        recognitionRequest.shouldReportPartialResults = true
        
        /// Start the recognition by calling the recognitionTask method of our speechRecognizer. This function has a completion handler. This completion handler will be called every time the recognition engine has received input, has refined its current recognition, or has been canceled or stopped, and will return a final transcript.
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: {(result, error) in
            var isFinal = false///Define a boolean to determine if the recognition is final.
            

            /// If the result isn’t nil, set the textView.text property as our result‘s best transcription. Then if th    e result is the final result, set isFinal to true.
            if result != nil {
                self.txtSpeech.text = result?.bestTranscription.formattedString
                isFinal = (result?.isFinal)!
                
                print("Result = \(result?.bestTranscription.formattedString ?? "")")
            }
            
            /// If there is no error or the result is final, stop the audioEngine (audio input) and stop the recognitionRequest and recognitionTask. At the same time, we enable the Start Recording button.
            if error != nil || isFinal{
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.microphoneButton.isEnabled = true
                
            }
            
        })
        
        ///Add an audio input to the recognitionRequest. Note that it is ok to add the audio input after starting the recognitionTask. The Speech Framework will start recognizing as soon as an audio input has been added.
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        ///Prepare and start the audioEngine.
        audioEngine.prepare()
        
        do{
            try audioEngine.start()
        }catch{
            print("audioEngine couldn't start because of an error.")
        }
        
        txtSpeech.text = "say Something, I'm Listening"
    }
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available{
            microphoneButton.isEnabled = true
        } else {
            microphoneButton.isEnabled = false
        }
    }

}

