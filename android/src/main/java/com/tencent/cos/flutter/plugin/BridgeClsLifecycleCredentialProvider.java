package com.tencent.cos.flutter.plugin;

import android.os.Handler;
import android.os.Looper;

import com.tencent.qcloud.track.cls.ClsAuthenticationException;
import com.tencent.qcloud.track.cls.ClsLifecycleCredentialProvider;
import com.tencent.qcloud.track.cls.ClsSessionCredentials;

import java.util.concurrent.ExecutionException;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;

import java8.util.concurrent.CompletableFuture;

class BridgeClsLifecycleCredentialProvider extends ClsLifecycleCredentialProvider {
    private final Pigeon.FlutterCosApi flutterCosApi;

    BridgeClsLifecycleCredentialProvider(Pigeon.FlutterCosApi flutterCosApi) {
        super();
        this.flutterCosApi = flutterCosApi;
    }

    @Override
    protected ClsSessionCredentials fetchNewCredentials() throws ClsAuthenticationException {
        CompletableFuture<Pigeon.SessionQCloudCredentials> future = new CompletableFuture<>();
        //此处调用有可能不是在主线程中 需要切换到主线程 因为调用flutter只能在主线程
        runMainThread(() ->
                flutterCosApi.fetchClsSessionCredentials(future::complete)
        );
        try {
            Pigeon.SessionQCloudCredentials sessionQCloudCredentials = future.get(60, TimeUnit.SECONDS);
            if(sessionQCloudCredentials == null){
                throw new ClsAuthenticationException("fetch credentials error happens");
            }
            return new ClsSessionCredentials(
                    sessionQCloudCredentials.getSecretId(),
                    sessionQCloudCredentials.getSecretKey(),
                    sessionQCloudCredentials.getToken(),
                    sessionQCloudCredentials.getExpiredTime());

        } catch (InterruptedException | ExecutionException | TimeoutException e) {
            e.printStackTrace();
            throw new ClsAuthenticationException(e.getMessage());
        }
    }

    private void runMainThread(Runnable runnable){
        Handler mainHandler = new Handler(Looper.getMainLooper());
        mainHandler.post(runnable);
    }
}
