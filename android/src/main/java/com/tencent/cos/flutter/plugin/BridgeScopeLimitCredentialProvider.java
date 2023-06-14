package com.tencent.cos.flutter.plugin;

import android.os.Handler;
import android.os.Looper;

import com.tencent.cos.xml.common.ClientErrorCode;
import com.tencent.cos.xml.exception.CosXmlClientException;
import com.tencent.qcloud.core.auth.QCloudCredentials;
import com.tencent.qcloud.core.auth.STSCredentialScope;
import com.tencent.qcloud.core.auth.ScopeLimitCredentialProvider;
import com.tencent.qcloud.core.auth.SessionQCloudCredentials;
import com.tencent.qcloud.core.common.QCloudClientException;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;

import java8.util.concurrent.CompletableFuture;

class BridgeScopeLimitCredentialProvider implements ScopeLimitCredentialProvider {
    private final Pigeon.FlutterCosApi flutterCosApi;

    BridgeScopeLimitCredentialProvider(Pigeon.FlutterCosApi flutterCosApi) {
        super();
        this.flutterCosApi = flutterCosApi;
    }

    @Override
    public SessionQCloudCredentials getCredentials(STSCredentialScope[] stsCredentialScopes) throws QCloudClientException {
        CompletableFuture<Pigeon.SessionQCloudCredentials> future = new CompletableFuture<>();
        //此处调用有可能不是在主线程中 需要切换到主线程 因为调用flutter只能在主线程
        runMainThread(() ->
                flutterCosApi.fetchScopeLimitCredentials(convertSTSCredentialScope(stsCredentialScopes), future::complete)
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

    @Override
    public QCloudCredentials getCredentials() {
        throw new UnsupportedOperationException("not support ths op");
    }

    @Override
    public void refresh() {
    }

    private List<Pigeon.STSCredentialScope> convertSTSCredentialScope(STSCredentialScope[] stsCredentialScopes){
        List<Pigeon.STSCredentialScope> list =  new ArrayList<>();
        if(stsCredentialScopes != null && stsCredentialScopes.length > 0){
            for (STSCredentialScope stsCredentialScope : stsCredentialScopes) {
                list.add(
                        new Pigeon.STSCredentialScope.Builder()
                                .setAction(stsCredentialScope.action)
                                .setRegion(stsCredentialScope.region)
                                .setBucket(stsCredentialScope.bucket)
                                .setPrefix(stsCredentialScope.prefix)
                                .build()
                );
            }
        }
        return list;
    }

    private void runMainThread(Runnable runnable){
        Handler mainHandler = new Handler(Looper.getMainLooper());
        mainHandler.post(runnable);
    }
}
