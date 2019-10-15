package com.plugin.oss.imp;

public interface OssUploadCallback {

    public void onSuccess();

    public void onError(String code,String msg);
}
