import UIKit
import CoreML
import Vision
import ImageIO

class ViewController: UIViewController {
    
    @IBOutlet var resultLabel: UILabel!
    @IBOutlet weak var buttonOriginalImage: UIButton!
    @IBOutlet var buttonTargetImage: UIButton!
    
    var selectedImage: UIImage!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        predictUsingVision()
        
    }
    @IBAction func pressedChoosePhoto(_ sender: Any) {
        self.chooseImage()
    }
    
    func predictUsingVision() {
        let path = Bundle.main.path(forResource: "puppy", ofType: "jpg")
        let imageURL = NSURL.fileURL(withPath: path!)
        
        let modelFile =  Inceptionv3()   // Resnet50() //GoogLeNetPlaces()
        let model = try! VNCoreMLModel(for: modelFile.model)
        let handler = VNImageRequestHandler(url: imageURL)
        let request = VNCoreMLRequest(model: model, completionHandler: myResultsMethod)
        try! handler.perform( [ request] )
    }
    
    
    
    func myResultsMethod(request: VNRequest, error: Error?) {
        guard let results = request.results as? [VNClassificationObservation] else {
            fatalError("could not get results from ML Vision request")
        }
        
        if let entry = results.first {
            self.resultLabel.text = "\(entry.identifier):\(entry.confidence)"
        } else {
                self.resultLabel.text = "no results."
        }
    }
    

//    處理點選到的相片
    func processImage(image: UIImage) {
        
//        self.preformRequestForFaceRectangle(image: image)
        self.preformRequestForFaceLandmarks(image: image)
        selectedImage = image
    }
    
//_____________________________________________________________________________________________
    //    預製件請求面部矩形
    func preformRequestForFaceRectangle(image: UIImage) {
        
        self.resultLabel.text = "相片處理中。。。"
        
        let handler = VNImageRequestHandler(cgImage: image.cgImage!)
        
        do {
            let request = VNDetectFaceRectanglesRequest(completionHandler: handleFaceFetection)
            try handler.perform([request])
        } catch {
            print(error)
        }
    }
    
    func handleFaceFetection(request: VNRequest, error: Error?){
        //     他有沒有臉
        guard let observations = request.results as? [VNFaceObservation] else {
            fatalError("NO FACE!!!")
        }
        
        self.resultLabel.text = "找到\(observations.count) 張臉"
    }
//_____________________________________________________________________________________________
   
    func preformRequestForFaceLandmarks(image: UIImage) {
//        selectedImage = image
        self.resultLabel.text = "相片處理中。。。"
        
        let handler = VNImageRequestHandler(cgImage: image.cgImage!)
        
        do {
            let request = VNDetectFaceRectanglesRequest(completionHandler: handleFaceLandmarksDetection)
            try handler.perform([request])
        } catch {
            print(error)
        }
    }
    
    func handleFaceLandmarksDetection(request: VNRequest, error: Error?){
        //他有沒有臉
        guard let observations = request.results as? [VNFaceObservation] else {
            fatalError("NO FACE!!!")
        }
        
        self.resultLabel.text = "找到\(observations.count) 張臉"
        //remove box last time
        for vw in self.buttonOriginalImage.subviews where vw.tag == 10 {
            
            vw.removeFromSuperview()
        }
        
        var landmarkRegions: [VNFaceLandmarkRegion2D] = []
        
        for faceObservation in observations {
//            self.addFaceContour(forObservation: faceObservation, toView: self.buttonOriginalImage) //整張臉
            
            
          landmarkRegions = landmarkRegions + self.addFaceFeature(forObservation: faceObservation, toView: self.buttonOriginalImage) // 面部特徵
            
            selectedImage =  self.drawOnImage(source: selectedImage,
                                              boundingRect: faceObservation.boundingBox,
                                              faceLandmarkRegions: landmarkRegions)
        }
        
        self.buttonOriginalImage.setBackgroundImage(selectedImage, for: .normal)
        
    }
//    添加面部輪廓
    func addFaceContour(forObservation face: VNFaceObservation, toView view: UIView){
//        畫出輪廓
//        計算輪廓的大小
//        把繪製出來的輪廓圖放到定位
        
        let box1 = face.boundingBox // !!! this is values from 0 to 1
        let box2 = view.bounds
        
        let w = box1.size.width * box2.width
        let h = box1.size.height * box2.height
        
        let x = box1.origin.x * box2.width
        let y = abs(( box1.origin.y * box2.height ) - box2.height ) - h
        
        let subview = UIView(frame: CGRect(x: x, y: y, width: w, height: h))
        
        subview.layer.borderColor = UIColor.green.cgColor
        subview.layer.borderWidth = 3.0
        subview.layer.cornerRadius = 5.0
        
        subview.tag = 10
        view.addSubview(subview)
    }
//    描繪面部特徵
    func addFaceFeature(forObservation face: VNFaceObservation, toView view: UIView) ->[VNFaceLandmarkRegion2D]{
//     找到所有的面部特徵 眼睛鼻子嘴巴。。。。
//     把他們畫出來
        
        guard let landmarks = face.landmarks else { return [] }
        
        var landmarkRegions: [VNFaceLandmarkRegion2D] = []
        
        if let faceContour = landmarks.faceContour {
            landmarkRegions.append(faceContour)
        }
        
        if let leftEye = landmarks.leftEye {
            landmarkRegions.append(leftEye)
        }
        
        if let rightEye = landmarks.rightEye {
            landmarkRegions.append(rightEye)
        }
        
        if let nose = landmarks.nose {
            landmarkRegions.append(nose)
        }
        
        if let innerLips = landmarks.innerLips {
            landmarkRegions.append(innerLips)
        }
        
        return landmarkRegions
    }
    
//    畫出面部特徵
    
    func drawOnImage(source: UIImage,
                     boundingRect: CGRect,
                     faceLandmarkRegions: [VNFaceLandmarkRegion2D]) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(source.size, false, 1)
        let context = UIGraphicsGetCurrentContext()!
        context.translateBy(x: 0, y: source.size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        context.setBlendMode(CGBlendMode.colorBurn)
        context.setLineJoin(.round)
        context.setLineCap(.round)
        context.setShouldAntialias(true)
        context.setAllowsAntialiasing(true)
        
        let rectWidth = source.size.width * boundingRect.size.width
        let rectHeight = source.size.height * boundingRect.size.height
        
        //draw original image
        let rect = CGRect(x: 0, y:0, width: source.size.width, height: source.size.height)
        context.draw(source.cgImage!, in: rect)
        
        
        //draw bound rect
        var fillColor = UIColor.red
        fillColor.setFill()
        context.addRect(CGRect(x: boundingRect.origin.x * source.size.width, y:boundingRect.origin.y * source.size.height, width: rectWidth, height: rectHeight))
        context.drawPath(using: CGPathDrawingMode.stroke)
        
        
        
        //draw overlay
        fillColor = UIColor.red
        fillColor.setStroke()
        context.setLineWidth(8.0)
        for faceLandmarkRegion in faceLandmarkRegions {
            var points: [CGPoint] = []
            for i in 0..<faceLandmarkRegion.pointCount {
                let point = faceLandmarkRegion.normalizedPoints[i]
                let p = CGPoint(x: CGFloat(point.x), y: CGFloat(point.y))
                points.append(p)
            }
            let mappedPoints = points.map { CGPoint(x: boundingRect.origin.x * source.size.width + $0.x * rectWidth, y: boundingRect.origin.y * source.size.height + $0.y * rectHeight) }
            context.addLines(between: mappedPoints)
            context.drawPath(using: CGPathDrawingMode.stroke)
        }
        
        let coloredImg : UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return coloredImg
    }
    
    
}

extension ViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func chooseImage() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .savedPhotosAlbum
        present(picker, animated: true)
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let uiImage = info[UIImagePickerControllerOriginalImage] as? UIImage else {
            fatalError("no image selected")
        }
        self.buttonOriginalImage.setBackgroundImage(uiImage, for: .normal)
        self.processImage(image: uiImage)
    }
}











