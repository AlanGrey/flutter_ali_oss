package com.plugin.oss;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;
import android.os.Handler;
import android.os.Looper;

import com.plugin.oss.imp.OssManager;
import com.plugin.oss.imp.OssProgressCallback;
import com.plugin.oss.imp.OssUploadCallback;
import com.plugin.oss.imp.StsToken;

import java.util.HashMap;
import java.util.Map;

import io.flutter.Log;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/** OssPlugin */
public class OssPlugin implements MethodCallHandler, EventChannel.StreamHandler {

    private Context context;
    private MethodChannel methodChannel;
    private EventChannel eventChannel;
    private OssProgressListener ossProgressListener;
    private Handler handler;

    public OssPlugin(Registrar registrar) {
        this.context = registrar.context();
        this.handler = new Handler(Looper.getMainLooper());
        methodChannel = new MethodChannel(registrar.messenger(), "oss_flutter_to_native");
        eventChannel = new EventChannel(registrar.messenger(), "oss_native_to_flutter");
        methodChannel.setMethodCallHandler(this);
        eventChannel.setStreamHandler(this);
        registerNetState(context);
    }

    private void registerNetState(Context context) {
        IntentFilter filter = new IntentFilter();
        filter.addAction(ConnectivityManager.CONNECTIVITY_ACTION);
        context.registerReceiver(netWorkStateReceiver, filter);
    }


    BroadcastReceiver netWorkStateReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            Log.e("OSS", "网络变化");
            ConnectivityManager connMgr = (ConnectivityManager) context.getSystemService(Context.CONNECTIVITY_SERVICE);
            if (connMgr != null) {
                NetworkInfo networkInfo = connMgr.getActiveNetworkInfo();
                if (networkInfo != null && networkInfo.isConnected()) {
                    OssManager.getInstance().requestStsToken();
                }
            }
        }
    };


    /** Plugin registration. */
    public static void registerWith(Registrar registrar) {
        final OssPlugin plugin = new OssPlugin(registrar);
    }

    @Override
    public void onMethodCall(final MethodCall call, Result result) {
        String method = call.method;

        if ("init".equals(method)) {
            init(call, result);
        }

        if ("upload".equals(method)) {

            upload(call, result);

        }


    }

    private void init(final MethodCall call, Result result) {
        String bucket = call.argument("bucket");
        String endpoint = call.argument("endpoint");
        StsToken stsToken = null;
        if (call.hasArgument("stsToken")) {
            stsToken = parseStsToken((Map<String, Object>) call.argument("stsToken"));
        }
        OssManager.getInstance().init(context, bucket, endpoint, stsToken, requestStsToken());
        result.success(true);
    }


    private void upload(final MethodCall call, final Result result) {
        final String objectKey = call.argument("objectKey");
        String filePath = call.argument("filePath");

        OssManager.getInstance().upload(objectKey, filePath, new OssProgressCallback() {
            @Override
            public void onProgress(final String objectKey, final long currentSize, final long totalSize) {
                if (ossProgressListener != null) {
                    handler.post(new Runnable() {
                        @Override
                        public void run() {
                            ossProgressListener.onProgress(objectKey, currentSize, totalSize);
                        }
                    });
                }
            }
        }, new OssUploadCallback() {
            @Override
            public void onSuccess() {
                final Map<String, Object> resultMap = new HashMap();
                resultMap.put("success", true);
                resultMap.put("data", objectKey);
                handler.post(new Runnable() {
                    @Override
                    public void run() {
                        result.success(resultMap);
                    }
                });
            }

            @Override
            public void onError(String code, String msg) {
                final Map<String, Object> resultMap = new HashMap();
                resultMap.put("success", false);
                resultMap.put("code", code);
                resultMap.put("msg", msg);
                handler.post(new Runnable() {
                    @Override
                    public void run() {
                        result.success(resultMap);
                    }
                });

            }
        });
    }


    @Override
    public void onListen(Object o, EventChannel.EventSink eventSink) {
        ossProgressListener = new OssProgressListener(eventSink);
    }

    @Override
    public void onCancel(Object o) {
        ossProgressListener = null;
    }


    OssManager.StsTokenRequest requestStsToken() {

        return new OssManager.StsTokenRequest() {
            @Override
            public void requestStsToken(final OssManager.StsTokenCallback callback) {
                methodChannel.invokeMethod("requestStsToken", null, new Result() {
                    @Override
                    public void success(Object o) {
                        if (callback != null && o != null) {
                            callback.onNewStsToken(parseStsToken((Map<String, Object>) o));
                        }
                    }

                    @Override
                    public void error(String s, String s1, Object o) {

                    }

                    @Override
                    public void notImplemented() {

                    }
                });
            }
        };


    }


    StsToken parseStsToken(Map<String, Object> arg) {
        if (arg != null) {
            StsToken stsToken = new StsToken();
            stsToken.setAccessKeyId((String) arg.get("accessKeyId"));
            stsToken.setAccessKeySecret((String) arg.get("accessKeySecret"));
            stsToken.setSecurityToken((String) arg.get("securityToken"));
            stsToken.setExpiration((String) arg.get("expiration"));
            return stsToken;
        }
        return null;
    }
}
