package com.plugin.oss.imp;

public interface OssProgressCallback {

    public void onProgress(String objectKey, long currentSize, long totalSize);
}
