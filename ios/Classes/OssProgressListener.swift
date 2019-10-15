//
//  OssProgressListener.swift
//  oss
//
//  Created by 胡杰 on 2019/5/30.
//

import UIKit

public class OssProgressListener: NSObject {

    var event:FlutterEventSink
    
    init(event:@escaping FlutterEventSink) {
        self.event = event
    }
    
    func onProgress(objectKey:String,currentSize:Int,totalSize:Int){
        
        var dic = Dictionary<String,Any>()
        
        dic["objectKey"] = objectKey
        dic["currentSize"] = currentSize
        dic["totalSize"] = totalSize
        
        event(dic)
    }
    
}
