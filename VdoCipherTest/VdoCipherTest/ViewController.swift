//
//  ViewController.swift
//  VdoCipherTest
//
//  Created by Saurabh Tanwer on 29/06/21.
//

import UIKit
import AVKit
import MobileCoreServices

class ViewController: UIViewController {
    
    @IBOutlet weak var txfStartPoint: UITextField!
    @IBOutlet weak var txfEndPoint: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
            tap.cancelsTouchesInView = false

            view.addGestureRecognizer(tap)
   
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func cropVideo(sourceURLOriginalFile: URL, startTime:Float, endTime:Float)
    {
        let manager = FileManager.default
        
        guard let documentDirectory = try? manager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true) else {return}
        let mediaType = "mp4"
        if mediaType == kUTTypeMovie as String || mediaType == "mp4" as String {
            let asset = AVAsset(url: sourceURLOriginalFile as URL)
            let length = Float(asset.duration.value) / Float(asset.duration.timescale)
            print("video length: \(length) seconds")
            
            let start = startTime
            let end = endTime
            
            var outputURL = documentDirectory.appendingPathComponent("output")
            do {
                try manager.createDirectory(at: outputURL, withIntermediateDirectories: true, attributes: nil)
                outputURL = outputURL.appendingPathComponent("\(UUID().uuidString).\(mediaType)")
            }catch let error {
                print(error)
            }
            
            //Remove existing file
            _ = try? manager.removeItem(at: outputURL)
            
            
            guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {return}
            exportSession.outputURL = outputURL
            exportSession.outputFileType = .mp4
            
            let startTime = CMTime(seconds: Double(start ), preferredTimescale: 1000)
            let endTime = CMTime(seconds: Double(end ), preferredTimescale: 1000)
            let timeRange = CMTimeRange(start: startTime, end: endTime)
            
            exportSession.timeRange = timeRange
            exportSession.exportAsynchronously{
                switch exportSession.status {
                case .completed:
                    print("exported at \(outputURL)")
                    DispatchQueue.main.async{
                        let player = AVPlayer(url: outputURL)
                        let playerLayer = AVPlayerLayer(player: player)
                        playerLayer.frame = self.view.bounds
                        self.view.layer.addSublayer(playerLayer)
                        player.play()
                        
                        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main) { _ in
                            player.seek(to: CMTime.zero)
                            player.play()
                        }
                    }
                    
                case .failed:
                    print("failed \(exportSession.error)")
                    
                case .cancelled:
                    print("cancelled \(exportSession.error)")
                    
                default: break
                }
            }
        }
    }
    
    @IBAction func acnBtnCropndPlay(_ sender: UIButton) {
        if txfStartPoint.hasText && txfEndPoint.hasText{
            let intStartTime = Float(txfStartPoint.text ?? "0") ?? 0
            let intEndTime = Float(txfEndPoint.text ?? "0") ?? 0
            guard let path = Bundle.main.path(forResource: "combined-gif", ofType:"mp4") else {
                debugPrint("combined-gif.mp4 not found")
                return
            }
            cropVideo(sourceURLOriginalFile: URL(fileURLWithPath: path), startTime: intStartTime, endTime: intEndTime)
        }
    }
    
}

