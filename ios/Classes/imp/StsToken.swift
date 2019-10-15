//
//  StsToken.swift
//  oss
//
//  Created by 胡杰 on 2019/5/29.
//

import UIKit

class StsToken: NSObject {

    var accessKeyId:String
    var accessKeySecret:String
    var securityToken:String
    var expiration:String
    
    init(accessKeyId:String,accessKeySecret:String,securityToken:String,expiration:String) {
        
        self.accessKeyId = accessKeyId
        self.accessKeySecret = accessKeySecret
        self.securityToken = securityToken
        self.expiration = expiration
        
    }
    
}
