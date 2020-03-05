//
//  ViewController.swift
//  CameraApp
//
//  Created by Nipuna Chhabra on 3/4/20.
//  Copyright © 2020 Nipuna. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate{
    
    let captureSession = AVCaptureSession()
    var previewLayer:CALayer!
    
    var captureDevice:AVCaptureDevice!
    
    var takePhoto = false
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareCamera()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        prepareCamera()
    }
    
    func beginSession() {
        do{
            let captureDeviceInput = try  AVCaptureDeviceInput(device: captureDevice)
            captureSession.addInput(captureDeviceInput)
        }catch{
            print(error.localizedDescription)
        }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            self.previewLayer = previewLayer
            self.view.layer.addSublayer(self.previewLayer)
            self.previewLayer.frame = self.view.layer.frame
            captureSession.startRunning()
            
            let dataOutput = AVCaptureVideoDataOutput()
            dataOutput.videoSettings = [((kCVPixelBufferPixelFormatTypeKey as NSString) as String):NSNumber(value:kCVPixelFormatType_32BGRA)]
            
            dataOutput.alwaysDiscardsLateVideoFrames = true
            
            if captureSession.canAddOutput(dataOutput){
                captureSession.addOutput(dataOutput)
            }
            
            captureSession.commitConfiguration()
            
            let queue = DispatchQueue(label: "Nipuna")
            dataOutput.setSampleBufferDelegate(self, queue:queue)
    }
    
    func prepareCamera() {
        captureSession.sessionPreset = AVCaptureSession.Preset.photo
        
        let availableDevices = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType:AVMediaType.video, position: .back).devices
        captureDevice = availableDevices.first
            beginSession()
        }


    @IBAction func takePhoto(_ sender: Any) {
        takePhoto = true
    }
    
    func  getImageFromSampleBuffer(buffer:CMSampleBuffer) -> UIImage? {
        if let pixelBuffer = CMSampleBufferGetImageBuffer(buffer){
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            let context = CIContext()
            
            let imageRect = CGRect(x: 0, y: 0, width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer))
            if let image = context.createCGImage(ciImage, from: imageRect){
                return UIImage(cgImage: image, scale: UIScreen.main.scale, orientation: .right)
                
            }
        }
        
        return nil
    }
    
    
    func captureOutput(_captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!){
        
        if takePhoto{
            takePhoto = false
            
            if let image = self.getImageFromSampleBuffer(buffer: sampleBuffer){
                DispatchQueue.main.async {
                    let photoVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "PhotoVC") as! PhotoViewController
                    photoVC.takenPhoto = image
                    DispatchQueue.main.async {
                        self.present(photoVC, animated:true, completion:{self.stopCaptureSession()})
                    }
            }

        }
    }
}
    
    func stopCaptureSession() {
        self.captureSession.stopRunning()
        if let inputs = captureSession.inputs as? [AVCaptureDeviceInput]{
            for input in inputs{
                self.captureSession.removeInput(input)}
        }
    }
}
