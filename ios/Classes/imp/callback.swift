//
//  OssUploadCallback.swift
//  oss
//
//  Created by 胡杰 on 2019/5/30.
//

import UIKit

class  OssUploadCallback {
    
    var onSuccess:()->Void;
    var onError:(String,String)->Void
    
    init(onSuccess:@escaping ()->Void,onError:@escaping (String,String)->Void) {
    
        self.onSuccess = onSuccess
        self.onError = onError
    }
}



typealias OssProgressCallback = (_ objectKey:String,_ currentSize:Int,_ totalSize:Int)->Void




