//
//  HTRecognitionViewController.swift
//  HiTranslator
//
//  Created by yubin on 2022/1/5.
//

import UIKit
import SnapKit
import ZKProgressHUD
import CoreVideo
import AVFoundation
import MLKit
import MLImage
import MLKitTextRecognitionChinese
import MLKitTextRecognitionJapanese
import MLKitTextRecognitionKorean

class HTRecognitionViewController: UIViewController, HTNetworkProtocal {
    
    var canRecognition = false
    var isTransResult = false
    
    /// 获取设备
    var device: AVCaptureDevice!
    /// 会话，协调着input到output的数据传输，input和output的桥梁
    var captureSession: AVCaptureSession!
    /// 图像预览层，实时显示捕获的图像
    var previewLayer: AVCaptureVideoPreviewLayer!
    /// 图像流输出
    var output: AVCaptureVideoDataOutput!
    /// 相机开始拍照
    var beganTakePicture: Bool = false
    
    lazy var topV: HTPhotoTopView = {
        let v = HTPhotoTopView.loadFromXib()
        v.leftActionBlock = { [weak self] in
            HTLog.back()
            self?.showBackAD()
            if self?.canRecognition == true {
                self?.captureSession.stopRunning()
            }
            self?.navigationController?.popViewController(animated: true)
        }
        v.selectSourceBlock = { [weak self] in
            let vc = HTLanguageViewController()
            vc.isSource = true
            vc.isFromText = false
            self?.navigationController?.pushViewController(vc, animated: true)
        }
        v.selectTargetBlock = { [weak self] in
            let vc = HTLanguageViewController()
            vc.isSource = false
            vc.isFromText = false
            self?.navigationController?.pushViewController(vc, animated: true)
        }
        return v
    }()
    
    lazy var captureSessionV: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: status_height, width: screen_width, height: screen_height - status_height))
        return view
    }()
    
    lazy var startPhotoBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "photography"), for: .normal)
        btn.addTarget(self, action: #selector(photoAction(sender:)), for: .touchUpInside)
        return btn
    }()
    
    lazy var resultImageView: UIImageView = {
        let imgV = UIImageView()
        imgV.contentMode = .scaleAspectFit
        imgV.isUserInteractionEnabled = true
        imgV.clipsToBounds = true
        imgV.isHidden = true
        return imgV
    }()
    
    private lazy var overlayV: UIView = {
        precondition(isViewLoaded)
        let overlayView = UIView(frame: .zero)
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.clipsToBounds = true
        overlayView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.7)
        overlayView.isHidden = true
        return overlayView
    }()
    
    lazy var closeBtn: UIButton = {
        let closeBtn = UIButton(type: .custom)
        closeBtn.isHidden = true
        closeBtn.setImage(UIImage(named: "close"), for: .normal)
        closeBtn.addTarget(self, action: #selector(closeAction(sender:)), for: .touchUpInside)
        return closeBtn
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        
        HTAdverUtil.shared.loadInterstitialAd(type: .photoInter)
        /// 返回主页广告预加载
        HTAdverUtil.shared.removeCachefirst(type: .backRoot)
        HTAdverUtil.shared.loadInterstitialAd(type: .backRoot)
        
        view.addSubview(captureSessionV)
        view.addSubview(startPhotoBtn)
        startPhotoBtn.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.width.height.equalTo(84)
            make.bottom.equalToSuperview().offset(-50)
        }
        
        view.addSubview(resultImageView)
        resultImageView.snp.makeConstraints { make in
            make.top.equalTo(status_height)
            make.left.right.bottom.equalToSuperview()
        }
        
        view.addSubview(topV)
        
        view.addSubview(overlayV)
        overlayV.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        view.addSubview(closeBtn)
        closeBtn.snp.makeConstraints { make in
            make.width.height.equalTo(56)
            make.right.equalToSuperview()
            make.top.equalToSuperview().offset(24)
        }
        
        self.cameraAuthorization { [weak self] result in
            if result {
                DispatchQueue.main.async {
                    
                    self?.createCaptureSession()
                    self?.configCaptureSession()
                }
            }
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.Language.refreshOcr, object: nil, queue: nil) { _ in
            HTTransUtil.shared.setLanguages(type: .ocr)
            self.topV.sourceLab.text = UserDefaults.standard.value(forKey: LaguageString.ocrSourceTitle) as? String
            self.topV.targetLab.text = UserDefaults.standard.value(forKey: LaguageString.ocrTargetTitle) as? String
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.Remote.config, object: nil, queue: nil) { noti in
            if let vc = self.presentedViewController {
                if let subVC = vc.presentedViewController {
                    subVC.dismiss(animated: false, completion: nil)
                }
                vc.dismiss(animated: false, completion: nil)
            }
        }
        
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
        HTTransUtil.shared.setLanguages(type: .ocr)
    }
    
    func showBackAD() {
        
        HTAdverUtil.shared.showInterstitialAd(type: .backRoot, complete: { result, ad in
            if result, let ad = ad {
                ad.present(fromRootViewController: self)
            }
        })
    }
    
    func showAD() {
        
        HTAdverUtil.shared.showInterstitialAd(type: .photoInter, complete: { result, ad in
            if result, let ad = ad {
                ad.present(fromRootViewController: self)
            }
        })
    }
    
    @objc func photoAction(sender: UIButton) {
        
        HTLog.all_use(type: "o")
        
        self.cameraAuthorization { [weak self] result in
            if result {
                DispatchQueue.main.async {
                    
                    guard self?.isConected() == true else {
                        ZKProgressHUD.showMessage("Please turn on your network or wifi", autoDismissDelay: 1.7)
                        return
                    }
                    self?.beganTakePicture = true
                    HTLog.o_click()
                }
            }
        }
    }
    
    @objc func closeAction(sender: UIButton) {
        self.previewLayer.isHidden = false
        self.captureSession.startRunning()
        self.resultImageView.isHidden = true
        self.overlayV.isHidden = true
        self.closeBtn.isHidden = true
        self.isTransResult = false
    }
    
    func stratTranslate(models: [HTOcrTransModel]) {
        
        HTTransUtil.shared.getTranslateType(text: models[0].text) { type in
            switch type {
            case .offline, .equally: // 离线翻译逐条翻译
                for model in models {
                    HTTransUtil.shared.translate(type: .ocr, text: model.text) { result, type, time, resultText in
                        
                        if result {
                            HTTranslatingView.dismiss()
                            DispatchQueue.main.async() {
                                self.overlayV.isHidden = false
                                self.closeBtn.isHidden = false
                                model.label.text = resultText
                                if self.isTransResult == false {
                                    self.showAD()
                                    if type == .offline {
                                        HTLog.o_success2(type: "off")
                                        HTLog.all_1_off(value: time)
                                    } else if type == .equally {
                                        HTLog.o_success2(type: "sa")
                                        HTLog.all_1_sa()
                                    }
                                    self.isTransResult = true
                                }
                            }
                        } else {
                            HTTranslatingView.dismiss()
                            ZKProgressHUD.showMessage("Error, please try it again", autoDismissDelay: 1.7)
                            self.closeAction(sender: UIButton())
                        }
                    }
                }
            case .online: // 网页翻译组合翻译后再拆分
                var string = ""
                for model in models {
                    if string.count == 0 {
                        string = string + model.text
                    } else {
                        string = string + "\n" + model.text
                    }
                }
                HTTransUtil.shared.translate(type: .ocr, text: string) { result, type, time, resultText in
                    
                    if result {
                        HTTranslatingView.dismiss()
                        DispatchQueue.main.async() {
                            self.showAD()
                            self.overlayV.isHidden = false
                            self.closeBtn.isHidden = false
                            
                            if let textArr = resultText?.components(separatedBy: "\n") {
                                for (index, model) in models.enumerated() {
                                    if textArr.count > index {
                                        model.label.text = textArr[index]
                                    }
                                }
                            }
                            HTLog.o_success2(type: "bi")
                            HTLog.all_1_bi(value: time)
                        }
                    } else {
                        HTTranslatingView.dismiss()
                        ZKProgressHUD.showMessage("Error, please try it again", autoDismissDelay: 1.7)
                        self.closeAction(sender: UIButton())
                    }
                }
            }
        }
        
    }
    
}

extension HTRecognitionViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func createCaptureSession() {
        // SessionPreset,用于设置output输出流的画面质量
        captureSession = AVCaptureSession()
        if UIDevice.current.userInterfaceIdiom == .phone {
            captureSession.sessionPreset = AVCaptureSession.Preset.vga640x480
        } else {
            captureSession.sessionPreset = AVCaptureSession.Preset.photo
        }
        // 设置为高分辨率
        if captureSession.canSetSessionPreset(AVCaptureSession.Preset(rawValue: "AVCaptureSessionPreset1280x720")) {
            captureSession.sessionPreset = AVCaptureSession.Preset(rawValue: "AVCaptureSessionPreset1280x720")
        }
        // 获取输入设备,builtInWideAngleCamera是通用相机,AVMediaType.video代表视频媒体,back表示前置摄像头,如果需要后置摄像头修改为front
        let availbleDevices = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .back).devices
        device = availbleDevices.first
        self.canRecognition = true
    }
    
    func configCaptureSession() {
        captureSession.beginConfiguration()
        do {
            /// 将后置摄像头作为session的input 输入流
            let captureDeviceInput = try AVCaptureDeviceInput(device: device)
            captureSession.addInput(captureDeviceInput)
        } catch {
            print(error.localizedDescription)
        }
        /// 设定视频预览层,也就是相机预览layer
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        ///captureSessionV 中
        captureSessionV.layer.addSublayer(previewLayer)
        previewLayer.frame = CGRect(x: 0, y: 0, width: screen_width, height: screen_height - status_height)
        /// 相机页面展现形式-拉伸充满frame
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        /// 设定输出流
        output = AVCaptureVideoDataOutput()
        /// 指定像素格式
        output.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString):NSNumber(value:kCVPixelFormatType_32BGRA)] as [String : Any]
        /// 是否直接丢弃处理旧帧时捕获的新帧,默认为True,如果改为false会大幅提高内存使用
        output.alwaysDiscardsLateVideoFrames = true
        if captureSession.canAddOutput(output) {
            captureSession.addOutput(output)
        }
        // beginConfiguration()和commitConfiguration()方法中的修改将在commit时同时提交
        captureSession.commitConfiguration()
        captureSession.startRunning()
        // 开新线程进行输出流代理方法调用
        let queue = DispatchQueue(label: "com.brianadvent.captureQueue")
        output.setSampleBufferDelegate(self, queue: queue)
        
        let captureConnection = output.connection(with: .video)
        if captureConnection?.isVideoStabilizationSupported == true {
            /// 这个很重要 这个是为了拍照完成，防止图片旋转90度
            captureConnection?.videoOrientation = self.getCaptureVideoOrientation()
        }
    }
    
    /// 旋转方向
    func getCaptureVideoOrientation() -> AVCaptureVideoOrientation {
        switch UIDevice.current.orientation {
        case .portrait,.faceUp,.faceDown:
            return .portrait
        case .portraitUpsideDown: // 如果这里设置成AVCaptureVideoOrientationPortraitUpsideDown,则视频方向和拍摄时的方向是相反的。
            return .portrait
        case .landscapeLeft:
            return .landscapeRight
        case .landscapeRight:
            return .landscapeLeft
        default:
            return .portrait
        }
    }
    
    /// CMSampleBufferRef=>UIImage
    func imageConvert(sampleBuffer: CMSampleBuffer?) -> UIImage? {
        guard sampleBuffer != nil && CMSampleBufferIsValid(sampleBuffer!) == true else { return nil }
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer!)
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer!)
        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        return UIImage(cgImage: cgImage, scale: 1.0, orientation: .up)
    }
    
    func getImageOrientation() -> UIImage.Orientation {
        switch UIDevice.current.orientation {
        case .portrait,.faceUp,.faceDown:
            return .up
        case .portraitUpsideDown: // 如果这里设置成AVCaptureVideoOrientationPortraitUpsideDown,则视频方向和拍摄时的方向是相反的。
            return .down
        case .landscapeLeft:
            return .left
        case .landscapeRight:
            return .right
        default:
            return .up
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if beganTakePicture == true {
            beganTakePicture = false
            
            DispatchQueue.main.async {
                self.resultImageView.image = self.imageConvert(sampleBuffer: sampleBuffer)
                self.captureSession.stopRunning()
                self.previewLayer.isHidden = true
//                self.resultImageView.isHidden = false
                self.startRecognition()
            }
        }
    }
    
    /// Updates the image view with a scaled version of the given image.
    private func updateImageView(with image: UIImage) {
        let orientation = UIApplication.shared.statusBarOrientation
        var scaledImageWidth: CGFloat = 0.0
        var scaledImageHeight: CGFloat = 0.0
        switch orientation {
        case .portrait, .portraitUpsideDown, .unknown:
            scaledImageWidth = resultImageView.bounds.size.width
            scaledImageHeight = image.size.height * scaledImageWidth / image.size.width
        case .landscapeLeft, .landscapeRight:
            scaledImageWidth = image.size.width * scaledImageHeight / image.size.height
            scaledImageHeight = resultImageView.bounds.size.height
        @unknown default:
            fatalError()
        }
        weak var weakSelf = self
        DispatchQueue.global(qos: .userInitiated).async {
            // Scale image while maintaining aspect ratio so it displays better in the UIImageView.
            var scaledImage = image.scaledImage(
                with: CGSize(width: scaledImageWidth, height: scaledImageHeight)
            )
            scaledImage = scaledImage ?? image
            guard let finalImage = scaledImage else { return }
            DispatchQueue.main.async {
                weakSelf?.resultImageView.image = finalImage
            }
        }
    }
    // UICreateCGImageFromIOSurface
    func startRecognition() {
        removeAnnotations()
        detectTextOnDevice(image: resultImageView.image)
    }
    
    /// Removes the detection annotations from the annotation overlay view.
    private func removeAnnotations() {
        for annotationView in overlayV.subviews {
            annotationView.removeFromSuperview()
        }
    }
    
    /// Clears the results text view and removes any frames that are visible.
    private func clearResults() {
        removeAnnotations()
    }
    
    /// - Parameter image: The image.
    private func detectTextOnDevice(image: UIImage?) {
        guard let image = image else { return }
        
        var textRecognizer = TextRecognizer()
        
        if let language = HTTransUtil.shared.sourceLanguage {
            switch language {
            case .chinese:
                let option = ChineseTextRecognizerOptions()
                textRecognizer = TextRecognizer.textRecognizer(options: option)
            case .japanese:
                let option = JapaneseTextRecognizerOptions()
                textRecognizer = TextRecognizer.textRecognizer(options: option)
            case .korean:
                let option = KoreanTextRecognizerOptions()
                textRecognizer = TextRecognizer.textRecognizer(options: option)
            default:
                let option = TextRecognizerOptions()
                textRecognizer = TextRecognizer.textRecognizer(options: option)
            }
        } else {
            let option = TextRecognizerOptions()
            textRecognizer = TextRecognizer.textRecognizer(options: option)
        }
        
        let visionImage = VisionImage(image: image)
        visionImage.orientation = image.imageOrientation
        
        process(visionImage, with: textRecognizer)
    }
    
    private func process(_ visionImage: VisionImage, with textRecognizer: TextRecognizer?) {
        HTTranslatingView.show()
        self.resultImageView.isHidden = false
        weak var weakSelf = self
        textRecognizer?.process(visionImage) { text, error in
            
            guard let strongSelf = weakSelf else {
                return
            }
            guard error == nil, let text = text else {
                let errorString = error?.localizedDescription ?? "No results returned."
                print("Text recognizer failed with error: \(errorString)")
                return
            }
            
            guard text.blocks.count > 0 else {
                ZKProgressHUD.showMessage("Error, please try it again", autoDismissDelay: 1.7)
                HTTranslatingView.dismiss()
                self.closeAction(sender: UIButton())
                return
            }
            
            HTLog.o_success1()
            HTLog.all_0()
            
            var blockArr: [HTOcrTransModel] = []
            
            // Blocks.
            for block in text.blocks {
                let transformedRect = block.frame.applying(strongSelf.transformMatrix())
                HTRootUtil.addRectangle(
                    transformedRect,
                    to: strongSelf.overlayV,
                    color: UIColor.clear
                )
                let label = UILabel(frame: transformedRect)
                label.numberOfLines = 0
                label.lineBreakMode = .byWordWrapping
                label.textColor = UIColor.ColorFromRGB(0xe3e6e8)
                label.adjustsFontSizeToFitWidth = true
                strongSelf.overlayV.addSubview(label)
                
                blockArr.append(HTOcrTransModel(label: label, text: block.text))
                
            }
            
            strongSelf.stratTranslate(models: blockArr)
            
        }
    }
    
    private func transformMatrix() -> CGAffineTransform {
        guard let image = resultImageView.image else { return CGAffineTransform() }
        let imageViewWidth = resultImageView.frame.size.width
        let imageViewHeight = resultImageView.frame.size.height
        let imageWidth = image.size.width
        let imageHeight = image.size.height
        
        let imageViewAspectRatio = imageViewWidth / imageViewHeight
        let imageAspectRatio = imageWidth / imageHeight
        let scale =
        (imageViewAspectRatio > imageAspectRatio)
        ? imageViewHeight / imageHeight : imageViewWidth / imageWidth
        
        // Image view's `contentMode` is `scaleAspectFit`, which scales the image to fit the size of the
        // image view by maintaining the aspect ratio. Multiple by `scale` to get image's original size.
        let scaledImageWidth = imageWidth * scale
        let scaledImageHeight = imageHeight * scale
        let xValue = (imageViewWidth - scaledImageWidth) / CGFloat(2.0)
        let yValue = (imageViewHeight - scaledImageHeight) / CGFloat(2.0)
        
        var transform = CGAffineTransform.identity.translatedBy(x: xValue, y: yValue)
        transform = transform.scaledBy(x: scale, y: scale)
        return transform
    }
}

// MARK: - 相机权限判断
extension HTRecognitionViewController {
    
    func cameraAuthorization(complete: @escaping ((Bool) -> Void)) {
        
        let authStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        
        if (authStatus == .authorized) {
            complete(true)
        } else if (authStatus == .denied) {
            let alert = UIAlertController(title: "Hi Translator App needs to access camera", message: "Turn on camera to identify the text", preferredStyle: .alert)
            let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            let gosetting = UIAlertAction(title: "Setting", style: .default) { _ in
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
            }
            alert.addAction(cancel)
            alert.addAction(gosetting)
            self.present(alert, animated: true, completion: nil)
            complete(false)
        } else if (authStatus == .restricted) {//
            let alert = UIAlertController(title: "Hi Translator App needs to access camera", message: "Turn on camera to identify the text", preferredStyle: .alert)
            let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            let gosetting = UIAlertAction(title: "Setting", style: .default) { _ in
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
            }
            alert.addAction(cancel)
            alert.addAction(gosetting)
            self.present(alert, animated: true, completion: nil)
            complete(false)
        } else if (authStatus == .notDetermined) {
            HTLog.textpage_p0()
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { (statusFirst) in
                if statusFirst {
                    HTLog.textpage_p1()
                    complete(true)
                } else {
                    complete(false)
                }
            })
        }
    }
}

