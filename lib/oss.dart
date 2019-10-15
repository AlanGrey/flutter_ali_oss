import 'dart:async';

import 'package:flutter/services.dart';

typedef OssProgressCallback = Function(int, int);
typedef StsTokenRequest = Future<StsToken> Function();

class Oss {
  static final Oss _oss = Oss._();

  MethodChannel _methodChannel;

  EventChannel _eventChannel;

  Map<String, OssProgressCallback> _progressCallbacks =
      Map<String, OssProgressCallback>();

  StsTokenRequest stsTokenRequest;

  static Oss get instance => _oss;

  Oss._() {
    _eventChannel = const EventChannel("oss_native_to_flutter");
    _eventChannel.receiveBroadcastStream().listen((event) {
      String objectKey = event["objectKey"];
      int currentSize = event["currentSize"];
      int totalSize = event["totalSize"];
      if (_progressCallbacks.containsKey(objectKey)) {
        _progressCallbacks[objectKey](currentSize, totalSize);
      }
    });
    _methodChannel = const MethodChannel('oss_flutter_to_native');
    _methodChannel.setMethodCallHandler(_methodCallHandler);
  }

  Future<dynamic> _methodCallHandler(MethodCall call) async {
    if (call.method == "requestStsToken") {
      //刷新token
      if (stsTokenRequest != null) {
        StsToken stsToken = await stsTokenRequest();
        if (stsToken != null) {
          return stsToken.toMap();
        }
      }
    }
  }

  //上传文件
  Future<OssUploadResult> upload(String objectKey, String filePath,
      OssProgressCallback progressCallback) async {
    if (progressCallback != null) {
      _progressCallbacks[objectKey] = progressCallback;
    }
    dynamic result = await _methodChannel
        .invokeMethod("upload", {"objectKey": objectKey, "filePath": filePath});
    if (progressCallback != null) {
      _progressCallbacks.remove(objectKey);
    }
    print("OSS上传返回$result");
    return OssUploadResult.fromMap(result);
  }

  //初始化
  Future init(String bucket, String endpoint, StsToken stsToken) async {
    Map<String, Object> arg = {"bucket": bucket, "endpoint": endpoint};
    if (stsToken != null) {
      arg["stsToken"] = stsToken.toMap();
    }
    await _methodChannel.invokeMethod("init", arg);
    return true;
  }
}

class OssUploadResult {
  bool success;
  String data;
  String code;
  String msg;

  OssUploadResult();

  factory OssUploadResult.fromMap(dynamic map) {
    final result = OssUploadResult();

    result.success = map["success"];
    if (!result.success) {
      result.code = map["code"];
      result.msg = map["msg"];
    } else {
      result.data = map["data"];
    }
    return result;
  }
}

class StsToken {
  String accessKeyId;
  String accessKeySecret;
  String securityToken;
  String expiration;

  Map<String, String> toMap() {
    return {
      "accessKeyId": accessKeyId,
      "accessKeySecret": accessKeySecret,
      "securityToken": securityToken,
      "expiration": expiration,
    };
  }
}
