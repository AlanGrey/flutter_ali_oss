//
//  OssManager.swift
//  oss
//
//  Created by 胡杰 on 2019/5/29.
//

import UIKit
import AliyunOSSiOS

class OssManager: NSObject {

    static let instance:OssManager = OssManager.init()
    
    var bucket:String?
    var endpoint:String?
    var stsToken:StsToken?
    var client:OSSClient?
    var stsTokenRequest: StsTokenRequest?
    
    private override init() {
        
    }
    
    func initOss(bucket:String?,endpoint:String?,stsToken:StsToken?,stsTokenRequest:StsTokenRequest?) {
        self.bucket = bucket
        self.endpoint = endpoint
        self.stsToken  = stsToken
        self.stsTokenRequest = stsTokenRequest
        createClient()
        if(stsToken == nil ){
            self.requestStsToken()
        }
    }
    
    
    private func createClient(){
        
        client  = OSSClient.init(endpoint: endpoint!, credentialProvider: credentialProvider())
        
    }
    
    
    //token提供器
    private func credentialProvider() -> OSSCredentialProvider{
        
        return OSSFederationCredentialProvider.init(federationTokenGetter: { () -> OSSFederationToken? in
            if self.stsToken != nil {
                let token =  OSSFederationToken.init()
                token.tAccessKey = self.stsToken!.accessKeyId
                token.tSecretKey = self.stsToken!.accessKeySecret
                token.tToken = self.stsToken!.securityToken
                token.expirationTimeInGMTFormat = self.stsToken!.expiration
                
                if( self.isExpried(expiration: token.expirationTimeInGMTFormat!)) {
                    self.requestStsToken()
                }
                return token
            }
            self.requestStsToken()
            return nil
        })
        
        
    }
    
    private func isExpried(expiration:String)->Bool {
        
        let df = DateFormatter.init()
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        let mis = (df.date(from: expiration)?.timeIntervalSince1970  ?? 0 ) * 1000
        let expirtionDate = Date.init(timeIntervalSince1970: mis / 1000)
        let interval = expirtionDate.timeIntervalSince(NSDate.oss_clockSkewFixed())
        if ( interval < 5 * 60){
            return true
        }
        
        return false
        
    }
    
    
    //刷新token
    private func refreshStsToken(stsToken:StsToken){
        self.stsToken = stsToken
    }
    
    
    //请求新的token
    public func requestStsToken(){
        if stsTokenRequest != nil {
            DispatchQueue.main.async {
                self.stsTokenRequest!{stoken in
                    self.refreshStsToken(stsToken:stoken )
                }
            }
        }
    }
    
    public func upload(objectKey:String,filePath:String,progressCallback:OssProgressCallback?,uploadCallback:OssUploadCallback?){
        
        let request = objectRequest(objectKey: objectKey, filePath: filePath, progressCallback: progressCallback)
        
        
        let ossTask = client?.putObject(request)
        ossTask?.waitUntilFinished()
        if ossTask?.error == nil {
            uploadCallback?.onSuccess()
        }else{
            let error: NSError = (ossTask?.error)! as NSError
            uploadCallback?.onError("\(error.code)",error.description)
        }
    }
    
    public func uploadAsync(objectKey:String,filePath:String,progressCallback:OssProgressCallback?,uploadCallback:OssUploadCallback?){
        
        let request = objectRequest(objectKey: objectKey, filePath: filePath, progressCallback: progressCallback)
        
        
        let ossTask = client?.putObject(request)
        
        ossTask?.continue({ (task) -> Any? in
            // print("阿里 oss上传 ：\(task.error?.localizedDescription)")
            if task.error == nil {
                uploadCallback?.onSuccess()
            }else{
                let error: NSError = (task.error)! as NSError
                uploadCallback?.onError("\(error.code)",error.description)
            }
            return (Any).self
        })
        
        
        
      
    }
    
    
    
    //构建请求
    private func objectRequest(objectKey:String,filePath:String,progressCallback:OssProgressCallback?) ->OSSPutObjectRequest {
        let request = OSSPutObjectRequest.init()
        request.bucketName = bucket!
        request.objectKey = objectKey
        request.uploadingFileURL = URL.init(fileURLWithPath: filePath)
        
        request.uploadProgress = { (send,totalsend,total)  in
            progressCallback?(objectKey,Int(totalsend),Int(total))
        }
        return request
    }
    
    
}

typealias StsTokenRequest = (_ callback: @escaping StsTokenCallback)->Void

typealias StsTokenCallback = (_ stsToken:StsToken)->Void
