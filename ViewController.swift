//
//  ViewController.swift
//  SmartCameraML
//
//  Created by Sang Luu on 9/17/17.
//  Copyright © 2017 Sang Luu. All rights reserved.
//

import UIKit
import AVKit
import Vision

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    let labelView: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.black
        label.font = UIFont.systemFont(ofSize: 14)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        let captureSession = AVCaptureSession()
        
        captureSession.sessionPreset = .photo
        
        guard let captureDevice = AVCaptureDevice.default(for: .video) else {return}
        
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else {return}
        
        captureSession.addInput(input)
        
        captureSession.startRunning()
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame
        
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(dataOutput)
        
        view.addSubview(labelView)
        labelView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        labelView.centerYAnchor.constraint(equalTo: view.bottomAnchor, constant: -50).isActive = true
        labelView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        labelView.heightAnchor.constraint(equalToConstant: 30).isActive = true
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let model = try? VNCoreMLModel(for: Resnet50().model) else {return}
        
        let request = VNCoreMLRequest(model: model) { (finishedReq, err) in
            
            guard let results = finishedReq.results as? [VNClassificationObservation] else {return}
            
            guard let firstObservation = results.first else {return}
            
            DispatchQueue.main.async {
                self.labelView.text = firstObservation.identifier + " (\(firstObservation.confidence))"
            }
            
        }
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {return}
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }

}

