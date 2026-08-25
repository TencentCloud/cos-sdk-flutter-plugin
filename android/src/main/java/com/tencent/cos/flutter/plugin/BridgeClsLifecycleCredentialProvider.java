package com.tencent.cos.flutter.plugin;

import android.os.Handler;
import android.os.Looper;

import androidx.annotation.NonNull;

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
        // pigeon 25.x 起回调类型由 Reply<T> 改为 Result<T>（success/error 双方法）。
        // 显式实现 error 分支，让 Flutter 侧取密钥失败能立即抛错，而非白等 60 秒超时。
        runMainThread(() ->
                flutterCosApi.fetchClsSessionCredentials(new Pigeon.Result<Pigeon.SessionQCloudCredentials>() {
                    @Override
                    public void success(@NonNull Pigeon.SessionQCloudCredentials result) {
                        future.complete(result);
                    }

                    @Override
                    public void error(@NonNull Throwable error) {
                        future.completeExceptionally(error);
                    }
                })
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
