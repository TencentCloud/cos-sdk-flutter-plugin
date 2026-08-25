package com.tencent.cos.flutter.plugin;

import android.os.Handler;
import android.os.Looper;

import androidx.annotation.NonNull;

import com.tencent.cos.xml.common.ClientErrorCode;
import com.tencent.cos.xml.exception.CosXmlClientException;
import com.tencent.qcloud.core.auth.BasicLifecycleCredentialProvider;
import com.tencent.qcloud.core.auth.QCloudLifecycleCredentials;
import com.tencent.qcloud.core.auth.SessionQCloudCredentials;
import com.tencent.qcloud.core.common.QCloudClientException;

import java.util.concurrent.ExecutionException;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;

import java8.util.concurrent.CompletableFuture;

class BridgeCredentialProvider extends BasicLifecycleCredentialProvider {
    private final Pigeon.FlutterCosApi flutterCosApi;

    BridgeCredentialProvider(Pigeon.FlutterCosApi flutterCosApi) {
        super();
        this.flutterCosApi = flutterCosApi;
    }

    @Override
    protected QCloudLifecycleCredentials fetchNewCredentials() throws QCloudClientException {
        CompletableFuture<Pigeon.SessionQCloudCredentials> future = new CompletableFuture<>();
        //此处调用有可能不是在主线程中 需要切换到主线程 因为调用flutter只能在主线程
        // pigeon 25.x 起回调类型由 Reply<T>（单方法，可用 lambda）改为
        // Result<T>（success/error 双方法）。显式实现 error 分支，让 Flutter 侧
        // 取密钥失败能立即抛错，而不是白等满 60 秒超时。
        runMainThread(() ->
                flutterCosApi.fetchSessionCredentials(new Pigeon.Result<Pigeon.SessionQCloudCredentials>() {
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
                throw new CosXmlClientException(ClientErrorCode.INVALID_CREDENTIALS.getCode(), "fetch credentials error happens");
            }
            Long startTime = sessionQCloudCredentials.getStartTime();
            if (startTime == null) {
                return new SessionQCloudCredentials(
                        sessionQCloudCredentials.getSecretId(),
                        sessionQCloudCredentials.getSecretKey(),
                        sessionQCloudCredentials.getToken(),
                        sessionQCloudCredentials.getExpiredTime());
            } else {
                return new SessionQCloudCredentials(
                        sessionQCloudCredentials.getSecretId(),
                        sessionQCloudCredentials.getSecretKey(),
                        sessionQCloudCredentials.getToken(),
                        startTime,
                        sessionQCloudCredentials.getExpiredTime());
            }

        } catch (InterruptedException | ExecutionException | TimeoutException e) {
            e.printStackTrace();
            throw new CosXmlClientException(ClientErrorCode.INVALID_CREDENTIALS.getCode(), e);
        }
    }

    private void runMainThread(Runnable runnable){
        Handler mainHandler = new Handler(Looper.getMainLooper());
        mainHandler.post(runnable);
    }
}
