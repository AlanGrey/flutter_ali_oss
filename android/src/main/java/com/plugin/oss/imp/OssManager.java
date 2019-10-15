package com.plugin.oss.imp;

import android.content.Context;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import com.alibaba.sdk.android.oss.ClientException;
import com.alibaba.sdk.android.oss.OSSClient;
import com.alibaba.sdk.android.oss.ServiceException;
import com.alibaba.sdk.android.oss.callback.OSSCompletedCallback;
import com.alibaba.sdk.android.oss.callback.OSSProgressCallback;
import com.alibaba.sdk.android.oss.common.auth.OSSFederationCredentialProvider;
import com.alibaba.sdk.android.oss.common.auth.OSSFederationToken;
import com.alibaba.sdk.android.oss.common.utils.DateUtil;
import com.alibaba.sdk.android.oss.model.PutObjectRequest;
import com.alibaba.sdk.android.oss.model.PutObjectResult;


public class OssManager {

    private final static OssManager instance = new OssManager();

    private OssManager() {
    }

    public static OssManager getInstance() {
        return instance;
    }

    private String bucket;
    private String endpoint;
    private Context context;
    private OSSClient client;
    private StsToken stsToken;
    private StsTokenRequest stsTokenRequest;


    public void init(Context context, String bucket, String endpoint, StsToken stsToken, StsTokenRequest stsTokenRequest) {
        this.bucket = bucket;
        this.endpoint = endpoint;
        this.context = context;
        this.stsToken = stsToken;
        this.stsTokenRequest = stsTokenRequest;
        createClient();

        if (stsToken == null) {
            requestStsToken();
        }

    }


    private void createClient() {
        client = new OSSClient(context, endpoint, credentialProvider());
    }


    //刷新token
    private void refreshStsToken(StsToken stsToken) {
        this.stsToken = stsToken;
        //  client.updateCredentialProvider(credentialProvider());
    }

    //请求新的token
    public void requestStsToken() {
        if (stsTokenRequest != null) {
            new Handler(Looper.getMainLooper()).post(new Runnable() {
                @Override
                public void run() {
                    stsTokenRequest.requestStsToken(new StsTokenCallback() {
                        @Override
                        public void onNewStsToken(StsToken stsToken) {
                            refreshStsToken(stsToken);
                        }
                    });
                }
            });
        }
    }


    private OSSFederationCredentialProvider credentialProvider() {
        return new OSSFederationCredentialProvider() {
            @Override
            public OSSFederationToken getFederationToken() {
                //走这里时表示没有token或者token快失效了
                if (stsToken != null) {
                    OSSFederationToken token = new OSSFederationToken(stsToken.getAccessKeyId(), stsToken.getAccessKeySecret(), stsToken.getSecurityToken(), stsToken.getExpiration());
                    if (DateUtil.getFixedSkewedTimeMillis() / 1000 > token.getExpiration() - 5 * 60) {
                        //快过期了
                        requestStsToken();
                    }
                    return token;
                }
                requestStsToken();
                return null;
            }

        };
    }

    //同步上传
    public void upload(String objectKey, String filePath, OssProgressCallback progressCallback, OssUploadCallback uploadCallback) {
        if (client != null) {
            try {
                client.putObject(objectRequest(objectKey, filePath, progressCallback));
                Log.e("OSS", "上传成功");
                if (uploadCallback != null) {
                    uploadCallback.onSuccess();
                }
            } catch (ClientException e) {
                if (!e.isCanceledException()) {
                    if (uploadCallback != null) {
                        uploadCallback.onError("clientException", "ClientException");
                    }
                }
            } catch (ServiceException e) {
                e.printStackTrace();
                if (uploadCallback != null) {
                    uploadCallback.onError(e.getErrorCode(), e.getRawMessage());
                }
            }
        } else {
            if (uploadCallback != null) {
                uploadCallback.onError("clientException", "ClientException not create");
            }
        }
    }

    //异步上传
    public void asyncUpload(String objectKey, String filePath, OssProgressCallback progressCallback, final OssUploadCallback uploadCallback) {
        if (client != null) {
            client.asyncPutObject(objectRequest(objectKey, filePath, progressCallback), new OSSCompletedCallback<PutObjectRequest, PutObjectResult>() {
                @Override
                public void onSuccess(PutObjectRequest request, PutObjectResult result) {
                    if (uploadCallback != null) {

                        uploadCallback.onSuccess();

                    }
                }

                @Override
                public void onFailure(PutObjectRequest request, final ClientException clientException, final ServiceException serviceException) {
                    if (uploadCallback != null) {

                        if (clientException != null) {
                            uploadCallback.onError("clientException", "ClientException not create");
                        } else if (serviceException != null) {
                            uploadCallback.onError(serviceException.getErrorCode(), serviceException.getRawMessage());
                        }


                    }
                }
            });
        }
    }

    private PutObjectRequest objectRequest(final String objectKey, String filePath, final OssProgressCallback progressCallback) {
        PutObjectRequest request = new PutObjectRequest(bucket, objectKey, filePath);
        request.setProgressCallback(new OSSProgressCallback<PutObjectRequest>() {
            @Override
            public void onProgress(PutObjectRequest request, final long currentSize, final long totalSize) {
                // Log.e("OSS", "进度更新" + currentSize + "-" + totalSize);
                if (progressCallback != null) {
                    progressCallback.onProgress(objectKey, currentSize, totalSize);
                }
            }
        });
        return request;
    }


    public interface StsTokenRequest {
        void requestStsToken(StsTokenCallback callback);
    }

    public interface StsTokenCallback {
        void onNewStsToken(StsToken stsToken);
    }

}
