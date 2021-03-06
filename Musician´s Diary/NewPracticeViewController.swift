//
//  NewPracticeViewController.swift
//  Musician´s Diary
//
//  Created by Joosep Teemaa on 08/04/2018.
//  Copyright © 2018 Mihkel Märtin. All rights reserved.
//

import UIKit
import AVFoundation

class NewPracticeViewController: UIViewController,AVAudioRecorderDelegate {

    //vars
    var db = DiaryDatabase.dbManager
    
    var chosenId : Int!
    var practiceId : Int64!
    
    var currentDate = Date()
    var endDate = Date()
    var startDate = Date()
    
    var paused = false
    var timer = Timer()
    var seconds = 0
    var mikeOn = true
    var isTimerRunning = false
    var recorder: AVAudioRecorder!
    var recorderSettings: [String:Int] = [:]
    var filename: String!
    var filepath: URL!
    var dateFormatter = DateFormatter()

    
    @IBOutlet weak var mikeButton: UIButton!
    @IBOutlet weak var startStopButton: UIButton!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var practiceDescription: UITextField!
    
    @IBAction func startTapped(_ sender: UIButton) {

        SongViewController.shouldAnimateFirstRow = true
        if !isTimerRunning{
            if !paused{
                startDate = Date()
            }
            runTimer()
            if mikeOn {
                record()
                print("started recording")
            }
            isTimerRunning = true
            sender.flash()
            UIView.transition(with : startStopButton, duration : 0.5, options : .transitionCrossDissolve,animations: {self.startStopButton.setTitle("STOP", for: .normal)},completion : nil)
        }
        else{
            timer.invalidate()
            endDate = Date()
            if mikeOn {
                recorder.stop()
                db.editPracticeTime(practiceId:practiceId, startTime: startDate, duration: seconds, endTime: endDate, filename: filename)
            }
            else {
                db.editPracticeTime(practiceId:practiceId, startTime: startDate, duration: seconds, endTime: endDate)
            }
            UIView.transition(with : startStopButton, duration : 0.5, options : .transitionCrossDissolve,animations: {self.startStopButton.setTitle("START", for: .normal)},completion : nil)
            print("stopped recording")
            paused = true
            isTimerRunning = false
            print(seconds)
            print("edited duration")
        }
    }
    
    @IBAction func descriptionChanged(_ sender: Any) {
        db.editPracticeDescription(practiceId : practiceId, description: practiceDescription.text!)
    }
    @IBAction func mikeTapped(_ sender: Any) {
        if mikeOn {
            UIView.transition(with : mikeButton, duration : 0.5, options : .transitionCrossDissolve,animations: {self.mikeButton.setTitle("OFF", for: .normal)},completion : nil)
            mikeOn = false
        }
        else {
            UIView.transition(with : mikeButton, duration : 0.5, options : .transitionCrossDissolve,animations: {self.mikeButton.setTitle("ON", for: .normal)},completion : nil)
            mikeOn = true
        }
    }
    
    func timeString(time:Int) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        return String(format:"%02i:%02i:%02i",hours,minutes,seconds)
    }
    func runTimer() {
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: (#selector(NewPracticeViewController.updateTimer)), userInfo: nil,repeats:true)
        timer.fire()
    }
    @objc func updateTimer() {
        if isTimerRunning{
            seconds += 1
            print("updateTimer")
            print(seconds)
            print(timeString(time: seconds))
            timerLabel.fadeTransition(duration: 0.3)
            timerLabel.text = timeString(time: seconds)
        }
    }
    
    @objc func handleSingleTap(){
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    func getDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirectory = paths[0]
        return documentDirectory
    }
        
        func record() {
            do{
                recorder = try AVAudioRecorder(url: filepath, settings: recorderSettings)
                recorder.delegate = self
                recorder.record()
            }catch{
                displayAlert(title: "Error", message: "recording failed to start")
            }
        }
    
    func displayAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "dismiss", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if isTimerRunning{
            timer.invalidate()
            paused = true
            isTimerRunning = false
            endDate = Date()
            if mikeOn {
                db.editPracticeTime(practiceId:practiceId, startTime: startDate, duration: seconds, endTime: endDate, filename: filename)
            }
            else {
                db.editPracticeTime(practiceId:practiceId, startTime: startDate, duration: seconds, endTime: endDate)
            }
            print(seconds)
            print("edited duration")
            SongViewController.enteringFromLeft = false
        }
        super.viewWillDisappear(true)
    }
    func dateString() -> String {
        dateFormatter.dateFormat = "yyyy-MM-dd-HH:mm"
        return dateFormatter.string(from: Date())
    }
    
    override func viewDidLoad() {
        practiceId = db.newPracticeRow(newId: chosenId)
        print(dateString())
        filename = "\(chosenId!)\(practiceId!)\(dateString()).m4a"
        print(filename)
        let documentDirectoryPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
        let audioDirectoryPath = documentDirectoryPath?.appending("/recordings")
        print(audioDirectoryPath!)
        filepath = URL(string: audioDirectoryPath!.appending(filename))
        print(filepath)
        recorderSettings = [AVFormatIDKey: Int(kAudioFormatMPEG4AAC), AVSampleRateKey: 12000, AVNumberOfChannelsKey: 1, AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue]
        let tapper = UITapGestureRecognizer(target: self, action: #selector(SongViewController.handleSingleTap))
        tapper.cancelsTouchesInView = false
        print("chosenId: ")
        print(chosenId)
        SongViewController.newPracticeId = Int(practiceId)
        print("created new harjutuskord row")
        startStopButton.layer.cornerRadius = 10;
        mikeButton.layer.cornerRadius = 10;
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }



}
