package com.plugin.oss;

import com.plugin.oss.imp.OssProgressCallback;

import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.EventChannel;

public class OssProgressListener implements OssProgressCallback {

    private EventChannel.EventSink eventSink;

    OssProgressListener(EventChannel.EventSink eventSink) {
        this.eventSink = eventSink;
    }


    @Override
    public void onProgress(String objectKey, long currentSize, long totalSize) {
        Map<String, Object> map = new HashMap();
        map.put("objectKey", objectKey);
        map.put("currentSize", currentSize);
        map.put("totalSize", totalSize);
        eventSink.success(map);
    }
}
