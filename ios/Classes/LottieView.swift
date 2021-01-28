import UIKit
import Flutter
import Lottie

public class LottieView : NSObject, FlutterPlatformView {
    let frame : CGRect
    let viewId : Int64
    
    var animationView: AnimationView?
    var testStream : TestStreamHandler?
    var delegates : [AnyValueProvider]
    var registrarInstance : FlutterPluginRegistrar
    
    
    init(_ frame: CGRect, viewId: Int64, args: Any?, registrarInstance : FlutterPluginRegistrar) {
        self.frame = frame
        self.viewId = viewId
        self.registrarInstance = registrarInstance
        self.delegates = []
        
        super.init()
        
        self.create(args: args)
    }
    
    func create(args: Any?) {
        
        let channel : FlutterMethodChannel = FlutterMethodChannel.init(name: "convictiontech/flutter_lottie_" + String(viewId), binaryMessenger: self.registrarInstance.messenger())
        let handler : FlutterMethodCallHandler = methodCall;
        channel.setMethodCallHandler(handler)
        
        let testChannel = FlutterEventChannel(name: "convictiontech/flutter_lottie_stream_playfinish_"  + String(viewId), binaryMessenger: self.registrarInstance.messenger())
        self.testStream  = TestStreamHandler()
        testChannel.setStreamHandler(testStream as? FlutterStreamHandler & NSObjectProtocol)
        
        
        if let argsDict = args as? Dictionary<String, Any> {
            let url = argsDict["url"] as? String ?? nil;
            let filePath = argsDict["filePath"] as? String ?? nil;
            
            if url != nil {
                self.animationView = AnimationView(filePath: url!)
            }
            
            if filePath != nil {
                print("THIS IS THE ID " + String(viewId) + " " + filePath!)
                let key = self.registrarInstance.lookupKey(forAsset: filePath!)
                let path = Bundle.main.path(forResource: key, ofType: nil)
                self.animationView = AnimationView(filePath: path!)
            }
            
            let loop = argsDict["loop"] as? Bool ?? false
            let reverse = argsDict["reverse"] as? Bool ?? false
            let autoPlay = argsDict["autoPlay"] as? Bool ?? false
            if reverse {
                self.animationView?.loopMode = LottieLoopMode.autoReverse
            }else{
                self.animationView?.loopMode = loop ? LottieLoopMode.loop : LottieLoopMode.playOnce
            }
            //         self.animationView?.completionBlock = completionBlock;
            if(autoPlay) {
                self.animationView?.play(completion: completionBlock);
            }
            
        }
        
    }
    
    public func view() -> UIView {
        return animationView!
    }
    
    public func completionBlock(animationFinished : Bool) -> Void {
        if let ev : FlutterEventSink = self.testStream!.event {
            ev(animationFinished)
        }
    }
    
    
    func methodCall( call : FlutterMethodCall, result: FlutterResult ) {
        var props : Dictionary<String, Any>  = [String: Any]()
        
        if let args = call.arguments as? Dictionary<String, Any> {
            props = args
        }
        
        if(call.method == "play") {
            self.animationView?.currentProgress = AnimationProgressTime(0)
            self.animationView?.play(completion: completionBlock);
        }
        
        if(call.method == "resume") {
            self.animationView?.play(completion: completionBlock);
        }
        
        if(call.method == "playWithProgress") {
            let toProgress = props["toProgress"] as! CGFloat;
            if let fromProgress = props["fromProgress"] as? CGFloat {
                self.animationView?.play(fromProgress: AnimationProgressTime(fromProgress), toProgress: AnimationProgressTime(toProgress), loopMode: self.animationView?.loopMode, completion: completionBlock)
            } else {
                self.animationView?.play(fromProgress: self.animationView?.currentProgress, toProgress:AnimationProgressTime(toProgress), loopMode: self.animationView?.loopMode, completion: completionBlock)
            }
        }
        
        if(call.method == "playWithFrames") {
            let toFrame = props["toFrame"] as! NSNumber;
            if let fromFrame = props["fromFrame"] as? NSNumber {
                self.animationView?.play(fromFrame:  AnimationFrameTime(fromFrame), toFrame:AnimationFrameTime(toFrame), loopMode: self.animationView?.loopMode, completion: completionBlock)
            } else {
                self.animationView?.play(fromFrame: self.animationView?.currentFrame, toFrame:AnimationFrameTime(toFrame), loopMode: self.animationView?.loopMode, completion: completionBlock)
            }
        }
        
        if(call.method == "stop") {
            self.animationView?.stop();
        }
        
        if(call.method == "pause") {
            self.animationView?.pause();
        }
        
        if(call.method == "setAnimationSpeed") {
            self.animationView?.animationSpeed = props["speed"] as! CGFloat
        }
        
        if(call.method == "setAutoReverseAnimation"){
            let rev = props["reverse"] as! Bool
            if  rev{
                self.animationView?.loopMode = LottieLoopMode.autoReverse
            }else {
                self.animationView?.loopMode = LottieLoopMode.loop
            }
        }else if(call.method == "setLoopAnimation"){
            let loop = props["loop"] as! Bool
            self.animationView?.loopMode = loop ? LottieLoopMode.loop : LottieLoopMode.playOnce
        }
        
        if(call.method == "setAnimationProgress") {
            self.animationView?.currentProgress =  AnimationProgressTime(props["progress"] as! CGFloat)
        }
        
        if(call.method == "setProgressWithFrame") {
            let frame = props["frame"] as! NSNumber
            self.animationView?.currentFrame =  AnimationFrameTime(frame);
        }
        
        if(call.method == "isAnimationPlaying") {
            let isAnimationPlaying = self.animationView?.isAnimationPlaying
            result(isAnimationPlaying)
        }
        
        if(call.method == "getAnimationDuration") {
            let animationDuration = self.animationView?.animation?.duration
            result(animationDuration)
        }
        
        if(call.method == "getAnimationProgress") {
            let animationProgress = self.animationView?.currentProgress
            result(animationProgress)
        }
        
        if(call.method == "getAnimationSpeed") {
            let animationSpeed = self.animationView?.animationSpeed
            result(animationSpeed)
        }
        
        if(call.method == "getLoopAnimation") {
            let loopAnimation = self.animationView?.loopMode == LottieLoopMode.loop
            result(loopAnimation)
        }
        
        if(call.method == "getAutoReverseAnimation") {
            let autoReverseAnimation = self.animationView?.loopMode == LottieLoopMode.autoReverse
            result(autoReverseAnimation)
        }
        
        
        if(call.method == "setValue") {
            let value = props["value"] as! String;
            let keyPath = props["keyPath"] as! String;
            if let type = props["type"] as? String {
                setValue(type: type, value: value, keyPath: keyPath)
            }
        }
        
    }
    
    func setValue(type: String, value: String, keyPath: String) -> Void {
        switch type {
        case "LOTColorValue":
            let i = UInt32(value.dropFirst(2), radix: 16)
            let color = UIColor(cgColor: hexToColor(hex8: i!))
            
            let cvp = Color(r: Double(color.ciColor.red), g: Double(color.ciColor.green), b: Double(color.ciColor.blue), a: Double(color.ciColor.alpha));
            
            self.delegates.append(ColorValueProvider(cvp))
            self.animationView?.setValueProvider(self.delegates[self.delegates.count - 1], keypath: AnimationKeypath(keypath: keyPath + ".Color"))
            break;
        case "LOTOpacityValue":
            if let n = NumberFormatter().number(from: value) {
                let f = CGFloat(truncating: n)
                self.delegates.append(FloatValueProvider(f))
                self.animationView?.setValueProvider(self.delegates[self.delegates.count - 1], keypath: AnimationKeypath(keypath: keyPath + ".Opacity"))
            }
            break;
        default:
            break;
        }
    }
    
}
