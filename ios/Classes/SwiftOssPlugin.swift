import Flutter
import UIKit


public class SwiftOssPlugin: NSObject, FlutterPlugin,FlutterStreamHandler {
    
    var methodChannel:FlutterMethodChannel?
    var eventChannel:FlutterEventChannel?
    var progressListener : OssProgressListener?
    let manager = NetworkReachabilityManager()
    
    
    public  init(registrar: FlutterPluginRegistrar) {
        super.init()
        methodChannel = FlutterMethodChannel(name: "oss_flutter_to_native", binaryMessenger: registrar.messenger())
        
        eventChannel = FlutterEventChannel(name: "oss_native_to_flutter", binaryMessenger: registrar.messenger())
        
        registrar.addMethodCallDelegate(self, channel: methodChannel!)
        eventChannel?.setStreamHandler(self)
        self.registerNetStateListener()
    }
    
    
    //网络变化监听
    public func registerNetStateListener(){
        //declare this property where it won't go out of scope relative to your listener
        manager?.listener = { status in
            if  status != .notReachable {
                OssManager.instance.requestStsToken()
            }
        }
        manager?.startListening()//开始监听网络
    }
    
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        SwiftOssPlugin.init(registrar: registrar)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        
        
        let method = call.method
        let arguments = call.arguments as? Dictionary<String, Any> ?? nil
        
        if method == "init" {
            initOss(arguments: arguments!,result: result)
           
            
        }
        
        if method == "upload" {
            upload(arguments: arguments!,result: result)
        }
        
    }
    
    private func initOss(arguments:Dictionary<String, Any>, result: @escaping FlutterResult){
        
        print("初始化OSS")
        
        let bucket = arguments["bucket"] as! String
        let endpoint = arguments["endpoint"] as! String
        
        let stsToken = arguments["stsToken"] as? Dictionary<String,Any>
        var token : StsToken? = nil
        if stsToken != nil {
            
            token = StsToken(accessKeyId: stsToken!["accessKeyId"] as! String, accessKeySecret: stsToken!["accessKeySecret"] as! String, securityToken: stsToken!["securityToken"] as! String, expiration: stsToken!["expiration"] as! String)
            
        }
        
        OssManager.instance.initOss(bucket: bucket,endpoint:endpoint,stsToken:token, stsTokenRequest: { callback in
            self.methodChannel?.invokeMethod("requestStsToken", arguments: nil,result:{ mm in
                if let stsToken = mm as? Dictionary<String,Any> {
                    let  token = StsToken(accessKeyId: stsToken["accessKeyId"] as! String, accessKeySecret: stsToken["accessKeySecret"] as! String, securityToken: stsToken["securityToken"] as! String, expiration: stsToken["expiration"] as! String)
                    print("刷新OSS Token")
                    callback(token)
                    
                }
            })
        })
        
        result(true)
        
        
    }
    
    private func upload(arguments:Dictionary<String, Any>, result: @escaping FlutterResult) {
        let objectKey = arguments["objectKey"] as! String
        let filePath = arguments["filePath"] as! String
        
        OssManager.instance.uploadAsync(objectKey: objectKey,filePath:filePath,progressCallback:{(ok,currentSize,totalSize) in
            print("上传进度",currentSize,"--",totalSize)
            self.progressListener?.onProgress(objectKey:ok,currentSize:currentSize,totalSize:totalSize)
        },uploadCallback: OssUploadCallback(onSuccess:{
            var dic = Dictionary<String,Any>()
            print("上传成功")
            dic["success"] = true
            dic["data"] = objectKey
            result(dic)
            
            
            
        },onError:{(code,msg) in
            
            print("上传失败",code,"--",msg)
            var dic = Dictionary<String,Any>()
            dic["success"] = false
            dic["code"] = code
            dic["msg"] = msg
            result(dic)
        }))
    }
    
    //Flutter 添加对Navite的监听
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        
        progressListener = OssProgressListener(event:events)
        return nil
    }
    //Flutter 取消对Navite的监听
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        progressListener = nil
        
        return nil
    }
}
