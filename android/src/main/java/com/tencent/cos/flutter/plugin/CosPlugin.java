package com.tencent.cos.flutter.plugin;

import android.content.Context;
import android.os.Handler;
import android.os.Looper;
import android.text.TextUtils;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.tencent.cos.xml.CosXmlBaseService;
import com.tencent.cos.xml.CosXmlService;
import com.tencent.cos.xml.CosXmlServiceConfig;
import com.tencent.cos.xml.common.COSStorageClass;
import com.tencent.cos.xml.exception.CosXmlClientException;
import com.tencent.cos.xml.exception.CosXmlServiceException;
import com.tencent.cos.xml.listener.CosXmlBooleanListener;
import com.tencent.cos.xml.listener.CosXmlResultListener;
import com.tencent.cos.xml.listener.CosXmlResultSimpleListener;
import com.tencent.cos.xml.model.CosXmlRequest;
import com.tencent.cos.xml.model.CosXmlResult;
import com.tencent.cos.xml.model.PresignedUrlRequest;
import com.tencent.cos.xml.model.bucket.DeleteBucketRequest;
import com.tencent.cos.xml.model.bucket.GetBucketAccelerateRequest;
import com.tencent.cos.xml.model.bucket.GetBucketAccelerateResult;
import com.tencent.cos.xml.model.bucket.GetBucketLocationRequest;
import com.tencent.cos.xml.model.bucket.GetBucketLocationResult;
import com.tencent.cos.xml.model.bucket.GetBucketRequest;
import com.tencent.cos.xml.model.bucket.GetBucketResult;
import com.tencent.cos.xml.model.bucket.GetBucketVersioningRequest;
import com.tencent.cos.xml.model.bucket.GetBucketVersioningResult;
import com.tencent.cos.xml.model.bucket.HeadBucketRequest;
import com.tencent.cos.xml.model.bucket.PutBucketAccelerateRequest;
import com.tencent.cos.xml.model.bucket.PutBucketRequest;
import com.tencent.cos.xml.model.bucket.PutBucketVersioningRequest;
import com.tencent.cos.xml.model.object.DeleteObjectRequest;
import com.tencent.cos.xml.model.object.GetObjectRequest;
import com.tencent.cos.xml.model.object.HeadObjectRequest;
import com.tencent.cos.xml.model.object.PutObjectRequest;
import com.tencent.cos.xml.model.service.GetServiceRequest;
import com.tencent.cos.xml.model.service.GetServiceResult;
import com.tencent.cos.xml.model.tag.AccelerateConfiguration;
import com.tencent.cos.xml.model.tag.InitiateMultipartUpload;
import com.tencent.cos.xml.model.tag.ListAllMyBuckets;
import com.tencent.cos.xml.model.tag.ListBucket;
import com.tencent.cos.xml.model.tag.LocationConstraint;
import com.tencent.cos.xml.model.tag.VersioningConfiguration;
import com.tencent.cos.xml.transfer.COSXMLDownloadTask;
import com.tencent.cos.xml.transfer.COSXMLTask;
import com.tencent.cos.xml.transfer.COSXMLUploadTask;
import com.tencent.cos.xml.transfer.InitMultipleUploadListener;
import com.tencent.cos.xml.transfer.TransferConfig;
import com.tencent.cos.xml.transfer.TransferManager;
import com.tencent.cos.xml.utils.DigestUtils;
import com.tencent.qcloud.core.auth.QCloudCredentialProvider;
import com.tencent.qcloud.core.auth.ShortTimeCredentialProvider;
import com.tencent.qcloud.core.task.TaskExecutors;

import java.net.InetAddress;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import java8.util.concurrent.CompletableFuture;

/**
 * CosPlugin
 */
public class CosPlugin implements FlutterPlugin, Pigeon.CosApi, Pigeon.CosServiceApi, Pigeon.CosTransferApi {
    private static final String TAG = "CosPlugin";

    private static final String DEFAULT_KEY = "";
    private Context context;
    private Pigeon.FlutterCosApi flutterCosApi;
    private final Map<String, CosXmlService> cosServices = new HashMap<>();
    private final Map<String, TransferManager> transferManagers = new HashMap<>();
    private final Map<String, COSXMLTask> taskMap = new HashMap<>();

    private QCloudCredentialProvider qCloudCredentialProvider = null;
    private Map<String, List<String>> dnsMap = null;
    private boolean initDnsFetch = false;
    private final Object credentialProviderLock = new Object();
    public static ThreadPoolExecutor COMMAND_EXECUTOR = null;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        context = flutterPluginBinding.getApplicationContext();
        Pigeon.CosApi.setup(flutterPluginBinding.getBinaryMessenger(), this);
        Pigeon.CosServiceApi.setup(flutterPluginBinding.getBinaryMessenger(), this);
        Pigeon.CosTransferApi.setup(flutterPluginBinding.getBinaryMessenger(), this);
        flutterCosApi = new Pigeon.FlutterCosApi(flutterPluginBinding.getBinaryMessenger());
        CosXmlBaseService.BRIDGE = "Flutter";

        COMMAND_EXECUTOR = new ThreadPoolExecutor(2, 10, 5L,
                TimeUnit.SECONDS, new LinkedBlockingQueue<Runnable>(Integer.MAX_VALUE));
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    }

    @Override
    public void initWithPlainSecret(@NonNull String secretId, @NonNull String secretKey) {
        qCloudCredentialProvider = new ShortTimeCredentialProvider(
                secretId,
                secretKey,
                600
        );
        synchronized (credentialProviderLock) {
            credentialProviderLock.notify();
        }
    }

    @Override
    public void initWithSessionCredential() {
        qCloudCredentialProvider = new BridgeCredentialProvider(flutterCosApi);
        synchronized (credentialProviderLock) {
            credentialProviderLock.notify();
        }
    }

    @Override
    public void initWithScopeLimitCredential() {
        qCloudCredentialProvider = new BridgeScopeLimitCredentialProvider(flutterCosApi);
        synchronized (credentialProviderLock) {
            credentialProviderLock.notify();
        }
    }

    @Override
    public void initCustomerDNS(@NonNull Map<String, List<String>> dnsMap) {
        this.dnsMap = dnsMap;
    }

    @Override
    public void initCustomerDNSFetch() {
        initDnsFetch = true;
    }

    @Override
    public void forceInvalidationCredential() {
        if(qCloudCredentialProvider instanceof BridgeCredentialProvider){
            BridgeCredentialProvider bridgeCredentialProvider = (BridgeCredentialProvider)qCloudCredentialProvider;
            bridgeCredentialProvider.forceInvalidationCredential();
        }
    }

    @Override
    public void setCloseBeacon(@NonNull Boolean isCloseBeacon) {
        CosXmlBaseService.IS_CLOSE_REPORT = isCloseBeacon;
    }

    @Override
    public void registerDefaultService(@NonNull Pigeon.CosXmlServiceConfig config, Pigeon.Result<String> result) {
        COMMAND_EXECUTOR.execute(new Runnable() {
            @Override
            public void run() {
                CosXmlService service = buildCosXmlService(context, config);
                runMainThread(new Runnable() {
                    @Override
                    public void run() {
                        cosServices.put(DEFAULT_KEY, service);
                        result.success(DEFAULT_KEY);
                    }
                });
            }
        });
    }

    @Override
    public void registerDefaultTransferManger(@NonNull Pigeon.CosXmlServiceConfig config, @Nullable Pigeon.TransferConfig transferConfig, Pigeon.Result<String> result) {
        COMMAND_EXECUTOR.execute(new Runnable() {
            @Override
            public void run() {
                TransferManager transferManager = buildTransferManager(context, config, transferConfig);
                runMainThread(new Runnable() {
                    @Override
                    public void run() {
                        transferManagers.put(DEFAULT_KEY, transferManager);
                        result.success(DEFAULT_KEY);
                    }
                });
            }
        });
    }

    @Override
    public void registerService(@NonNull String key, @NonNull Pigeon.CosXmlServiceConfig config, Pigeon.Result<String> result) {
        if (key.isEmpty()) {
            result.error(new IllegalArgumentException("register key cannot be empty"));
        }
        COMMAND_EXECUTOR.execute(new Runnable() {
            @Override
            public void run() {
                CosXmlService service = buildCosXmlService(context, config);
                runMainThread(new Runnable() {
                    @Override
                    public void run() {
                        cosServices.put(key, service);
                        result.success(key);
                    }
                });
            }
        });
    }

    @Override
    public void registerTransferManger(@NonNull String key, @NonNull Pigeon.CosXmlServiceConfig config, @Nullable Pigeon.TransferConfig transferConfig, Pigeon.Result<String> result) {
        if (key.isEmpty()) {
            result.error(new IllegalArgumentException("register key cannot be empty"));
        }
        COMMAND_EXECUTOR.execute(new Runnable() {
            @Override
            public void run() {
                TransferManager transferManager = buildTransferManager(context, config, transferConfig);
                runMainThread(new Runnable() {
                    @Override
                    public void run() {
                        transferManagers.put(key, transferManager);
                        result.success(key);
                    }
                });
            }
        });
    }

    @Override
    public void headObject(@NonNull String serviceKey, @NonNull String bucket, @Nullable String region, @NonNull String cosPath, @Nullable String versionId, Pigeon.Result<Map<String, String>> result) {
        CosXmlService service = getCosXmlService(serviceKey);
        HeadObjectRequest headObjectRequest = new HeadObjectRequest(
                bucket, cosPath);
        if (region != null) {
            headObjectRequest.setRegion(region);
        }
        if (versionId != null) {
            headObjectRequest.setVersionId(versionId);
        }
        service.headObjectAsync(headObjectRequest, new CosXmlResultListener() {
            @Override
            public void onSuccess(CosXmlRequest cosXmlRequest, CosXmlResult cosXmlResult) {
                try {
                    result.success(simplifyHeader(cosXmlResult.headers));
                } catch (Exception e) {
                    e.printStackTrace();
                    result.error(e);
                }
            }

            @Override
            public void onFail(CosXmlRequest cosXmlRequest, @Nullable CosXmlClientException e, @Nullable CosXmlServiceException e1) {
                if (e != null) {
                    e.printStackTrace();
                    result.error(e);
                } else {
                    e1.printStackTrace();
                    result.error(e1);
                }
            }
        });
    }

    @Override
    public void deleteObject(@NonNull String serviceKey, @NonNull String bucket, @Nullable String region, @NonNull String cosPath, @Nullable String versionId, Pigeon.Result<Void> result) {
        CosXmlService service = getCosXmlService(serviceKey);
        DeleteObjectRequest deleteObjectRequest = new DeleteObjectRequest(
                bucket, cosPath);
        if (region != null) {
            deleteObjectRequest.setRegion(region);
        }
        if (versionId != null) {
            deleteObjectRequest.setVersionId(versionId);
        }

        service.deleteObjectAsync(deleteObjectRequest, new CosXmlResultListener() {
            @Override
            public void onSuccess(CosXmlRequest cosXmlRequest, CosXmlResult cosXmlResult) {
                result.success(null);
            }

            @Override
            public void onFail(CosXmlRequest cosXmlRequest, @Nullable CosXmlClientException e, @Nullable CosXmlServiceException e1) {
                if (e != null) {
                    e.printStackTrace();
                    result.error(e);
                } else {
                    e1.printStackTrace();
                    result.error(e1);
                }
            }
        });
    }

    @NonNull
    @Override
    public String getObjectUrl(@NonNull String bucket, @NonNull String region, @NonNull String key, @NonNull String serviceKey) {
        CosXmlService service = getCosXmlService(serviceKey);
        return service.getObjectUrl(bucket, region, key);
    }

    @Override
    public void getPresignedUrl(@NonNull String serviceKey, @NonNull String bucket, @NonNull String cosPath, @Nullable Long signValidTime,
                                @Nullable Boolean signHost, @Nullable Map<String, String> parameters,
                                @Nullable String region, com.tencent.cos.flutter.plugin.Pigeon.Result<String> result) {
        CosXmlService service = getCosXmlService(serviceKey);
        PresignedUrlRequest presignedUrlRequest = new PresignedUrlRequest(bucket, cosPath);
        presignedUrlRequest.setRequestMethod("GET");
        if(signValidTime != null){
            presignedUrlRequest.setSignKeyTime(Math.toIntExact(signValidTime));
        }
        if(signHost != null && !signHost){
            presignedUrlRequest.addNoSignHeader("Host");
        }
        if(parameters != null){
            presignedUrlRequest.setQueryParameters(parameters);
        }
        if (region != null) {
            presignedUrlRequest.setRegion(region);
        }
        TaskExecutors.COMMAND_EXECUTOR.execute(() -> {
            try {
                String urlWithSign = service.getPresignedURL(presignedUrlRequest);
                result.success(urlWithSign);
            } catch (CosXmlClientException e) {
                e.printStackTrace();
                result.error(e);
            }
        });
    }

    @Override
    public void preBuildConnection(@NonNull String bucket, @NonNull String serviceKey, Pigeon.Result<Void> result) {
        CosXmlService service = getCosXmlService(serviceKey);
        service.preBuildConnectionAsync(bucket, new CosXmlResultSimpleListener() {
            @Override
            public void onSuccess() {
                result.success(null);
            }

            @Override
            public void onFail(CosXmlClientException e, CosXmlServiceException e1) {
                if (e != null) {
                    e.printStackTrace();
                    result.error(e);
                } else {
                    e1.printStackTrace();
                    result.error(e1);
                }
            }
        });
    }

    @Override
    public void getService(@NonNull String serviceKey, Pigeon.Result<Pigeon.ListAllMyBuckets> result) {
        CosXmlService service = getCosXmlService(serviceKey);
        GetServiceRequest request = new GetServiceRequest();
        service.getServiceAsync(request, new CosXmlResultListener() {
            @Override
            public void onSuccess(CosXmlRequest cosXmlRequest, CosXmlResult cosXmlResult) {
                try {
                    ListAllMyBuckets listAllMyBuckets = ((GetServiceResult) cosXmlResult).listAllMyBuckets;
                    List<Pigeon.Bucket> bucketList = new ArrayList<>();
                    if (listAllMyBuckets.buckets != null) {
                        for (ListAllMyBuckets.Bucket bucket : listAllMyBuckets.buckets) {
                            bucketList.add(
                                    new Pigeon.Bucket.Builder()
                                            .setName(bucket.name)
                                            .setType(bucket.type)
                                            .setCreateDate(bucket.createDate)
                                            .setLocation(bucket.location)
                                            .build()
                            );
                        }
                    }
                    Pigeon.ListAllMyBuckets pListAllMyBuckets =
                            new Pigeon.ListAllMyBuckets.Builder()
                                    .setOwner(
                                            new Pigeon.Owner.Builder().
                                                    setId(listAllMyBuckets.owner.id).
                                                    setDisPlayName(listAllMyBuckets.owner.disPlayName)
                                                    .build()
                                    )
                                    .setBuckets(bucketList)
                                    .build();
                    result.success(pListAllMyBuckets);
                } catch (Exception e) {
                    e.printStackTrace();
                    result.error(e);
                }
            }

            @Override
            public void onFail(CosXmlRequest cosXmlRequest, @Nullable CosXmlClientException e, @Nullable CosXmlServiceException e1) {
                if (e != null) {
                    e.printStackTrace();
                    result.error(e);
                } else {
                    e1.printStackTrace();
                    result.error(e1);
                }
            }
        });
    }

    @Override
    public void getBucket(@NonNull String serviceKey, @NonNull String bucket, @Nullable String region, @Nullable String prefix, @Nullable String delimiter, @Nullable String encodingType, @Nullable String marker, @Nullable Long maxKeys, Pigeon.Result<Pigeon.BucketContents> result) {
        CosXmlService service = getCosXmlService(serviceKey);
        GetBucketRequest request = new GetBucketRequest(bucket);
        if (region != null) {
            request.setRegion(region);
        }
        if (prefix != null) {
            request.setPrefix(prefix);
        }
        if (delimiter != null) {
            request.setDelimiter(delimiter);
        }
        if (encodingType != null) {
            request.setEncodingType(encodingType);
        }
        if (marker != null) {
            request.setMarker(marker);
        }
        if (maxKeys != null) {
            request.setMaxKeys(maxKeys);
        }
        service.getBucketAsync(request, new CosXmlResultListener() {
            @Override
            public void onSuccess(CosXmlRequest cosXmlRequest, CosXmlResult cosXmlResult) {
                try {
                    ListBucket listBucket = ((GetBucketResult) cosXmlResult).listBucket;
                    List<Pigeon.Content> contents = new ArrayList<>();
                    if (listBucket.contentsList != null) {
                        for (ListBucket.Contents content : listBucket.contentsList) {
                            Pigeon.Content.Builder builder = new Pigeon.Content.Builder()
                                    .setKey(content.key)
                                    .setLastModified(content.lastModified)
                                    .setETag(content.eTag)
                                    .setSize(content.size)
                                    .setStorageClass(content.storageClass);
                            if (content.owner != null) {
                                builder.setOwner(
                                        new Pigeon.Owner.Builder()
                                                .setId(content.owner.id)
                                                .build()
                                );
                            }
                            contents.add(builder.build());
                        }
                    }
                    List<Pigeon.CommonPrefixes> commonPrefixes = new ArrayList<>();
                    if (listBucket.commonPrefixesList != null) {
                        for (ListBucket.CommonPrefixes commonPrefix : listBucket.commonPrefixesList) {
                            commonPrefixes.add(
                                    new Pigeon.CommonPrefixes.Builder()
                                            .setPrefix(commonPrefix.prefix)
                                            .build()
                            );
                        }
                    }
                    Pigeon.BucketContents bucketContents = new Pigeon.BucketContents.Builder()
                            .setName(listBucket.name)
                            .setEncodingType(listBucket.encodingType)
                            .setPrefix(listBucket.prefix)
                            .setMarker(listBucket.marker)
                            .setMaxKeys((long) listBucket.maxKeys)
                            .setIsTruncated(listBucket.isTruncated)
                            .setNextMarker(listBucket.nextMarker)
                            .setDelimiter(listBucket.delimiter)
                            .setContentsList(contents)
                            .setCommonPrefixesList(commonPrefixes)
                            .build();
                    result.success(bucketContents);
                } catch (Exception e) {
                    e.printStackTrace();
                    result.error(e);
                }
            }

            @Override
            public void onFail(CosXmlRequest cosXmlRequest, @Nullable CosXmlClientException e, @Nullable CosXmlServiceException e1) {
                if (e != null) {
                    e.printStackTrace();
                    result.error(e);
                } else {
                    e1.printStackTrace();
                    result.error(e1);
                }
            }
        });

    }

    @Override
    public void putBucket(@NonNull String serviceKey, @NonNull String bucket, @Nullable String region, @Nullable Boolean enableMAZ, @Nullable String cosacl, @Nullable String readAccount, @Nullable String writeAccount, @Nullable String readWriteAccount, Pigeon.Result<Void> result) {
        CosXmlService service = getCosXmlService(serviceKey);
        PutBucketRequest request = new PutBucketRequest(bucket);
        if (region != null) {
            request.setRegion(region);
        }
        if (enableMAZ != null) {
            request.enableMAZ(enableMAZ);
        }
        if (cosacl != null) {
            request.setXCOSACL(cosacl);
        }
        if (readAccount != null) {
            request.setXCOSGrantRead(readAccount);
        }
        if (writeAccount != null) {
            request.setXCOSGrantWrite(writeAccount);
        }
        if (readWriteAccount != null) {
            request.setXCOSReadWrite(readWriteAccount);
        }
        service.putBucketAsync(request, new CosXmlResultListener() {
            @Override
            public void onSuccess(CosXmlRequest cosXmlRequest, CosXmlResult cosXmlResult) {
                result.success(null);
            }

            @Override
            public void onFail(CosXmlRequest cosXmlRequest, @Nullable CosXmlClientException e, @Nullable CosXmlServiceException e1) {
                if (e != null) {
                    e.printStackTrace();
                    result.error(e);
                } else {
                    e1.printStackTrace();
                    result.error(e1);
                }
            }
        });
    }

    @Override
    public void headBucket(@NonNull String serviceKey, @NonNull String bucket, @Nullable String region, Pigeon.Result<Map<String, String>> result) {
        CosXmlService service = getCosXmlService(serviceKey);
        HeadBucketRequest request = new HeadBucketRequest(bucket);
        if (region != null) {
            request.setRegion(region);
        }
        service.headBucketAsync(request, new CosXmlResultListener() {
            @Override
            public void onSuccess(CosXmlRequest cosXmlRequest, CosXmlResult cosXmlResult) {
                try {
                    result.success(simplifyHeader(cosXmlResult.headers));
                } catch (Exception e) {
                    e.printStackTrace();
                    result.error(e);
                }
            }

            @Override
            public void onFail(CosXmlRequest cosXmlRequest, @Nullable CosXmlClientException e, @Nullable CosXmlServiceException e1) {
                if (e != null) {
                    e.printStackTrace();
                    result.error(e);
                } else {
                    e1.printStackTrace();
                    result.error(e1);
                }
            }
        });
    }

    @Override
    public void deleteBucket(@NonNull String serviceKey, @NonNull String bucket, @Nullable String region, Pigeon.Result<Void> result) {
        CosXmlService service = getCosXmlService(serviceKey);
        DeleteBucketRequest request = new DeleteBucketRequest(bucket);
        if (region != null) {
            request.setRegion(region);
        }
        service.deleteBucketAsync(request, new CosXmlResultListener() {
            @Override
            public void onSuccess(CosXmlRequest cosXmlRequest, CosXmlResult cosXmlResult) {
                result.success(null);
            }

            @Override
            public void onFail(CosXmlRequest cosXmlRequest, @Nullable CosXmlClientException e, @Nullable CosXmlServiceException e1) {
                if (e != null) {
                    e.printStackTrace();
                    result.error(e);
                } else {
                    e1.printStackTrace();
                    result.error(e1);
                }
            }
        });
    }

    @Override
    public void getBucketAccelerate(@NonNull String serviceKey, @NonNull String bucket, @Nullable String region, Pigeon.Result<Boolean> result) {
        CosXmlService service = getCosXmlService(serviceKey);
        GetBucketAccelerateRequest request = new GetBucketAccelerateRequest(bucket);
        if (region != null) {
            request.setRegion(region);
        }
        service.getBucketAccelerateAsync(request, new CosXmlResultListener() {
            @Override
            public void onSuccess(CosXmlRequest cosXmlRequest, CosXmlResult cosXmlResult) {
                try {
                    AccelerateConfiguration accelerateConfiguration = ((GetBucketAccelerateResult) cosXmlResult).accelerateConfiguration;
                    if (accelerateConfiguration != null) {
                        result.success("Enabled".equals(accelerateConfiguration.status));
                    } else {
                        result.success(false);
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                    result.error(e);
                }
            }

            @Override
            public void onFail(CosXmlRequest cosXmlRequest, @Nullable CosXmlClientException e, @Nullable CosXmlServiceException e1) {
                if (e != null) {
                    e.printStackTrace();
                    result.error(e);
                } else {
                    e1.printStackTrace();
                    result.error(e1);
                }
            }
        });
    }

    @Override
    public void putBucketAccelerate(@NonNull String serviceKey, @NonNull String bucket, @Nullable String region, @NonNull Boolean enable, Pigeon.Result<Void> result) {
        CosXmlService service = getCosXmlService(serviceKey);
        PutBucketAccelerateRequest request = new PutBucketAccelerateRequest(bucket, enable);
        if (region != null) {
            request.setRegion(region);
        }
        service.putBucketAccelerateAsync(request, new CosXmlResultListener() {
            @Override
            public void onSuccess(CosXmlRequest cosXmlRequest, CosXmlResult cosXmlResult) {
                result.success(null);
            }

            @Override
            public void onFail(CosXmlRequest cosXmlRequest, @Nullable CosXmlClientException e, @Nullable CosXmlServiceException e1) {
                if (e != null) {
                    e.printStackTrace();
                    result.error(e);
                } else {
                    e1.printStackTrace();
                    result.error(e1);
                }
            }
        });
    }

    @Override
    public void getBucketLocation(@NonNull String serviceKey, @NonNull String bucket, @Nullable String region, Pigeon.Result<String> result) {
        CosXmlService service = getCosXmlService(serviceKey);
        GetBucketLocationRequest request = new GetBucketLocationRequest(bucket);
        if (region != null) {
            request.setRegion(region);
        }
        service.getBucketLocationAsync(request, new CosXmlResultListener() {
            @Override
            public void onSuccess(CosXmlRequest cosXmlRequest, CosXmlResult cosXmlResult) {
                try {
                    LocationConstraint locationConstraint = ((GetBucketLocationResult) cosXmlResult).locationConstraint;
                    result.success(locationConstraint.location);
                } catch (Exception e) {
                    e.printStackTrace();
                    result.error(e);
                }
            }

            @Override
            public void onFail(CosXmlRequest cosXmlRequest, @Nullable CosXmlClientException e, @Nullable CosXmlServiceException e1) {
                if (e != null) {
                    e.printStackTrace();
                    result.error(e);
                } else {
                    e1.printStackTrace();
                    result.error(e1);
                }
            }
        });
    }

    @Override
    public void getBucketVersioning(@NonNull String serviceKey, @NonNull String bucket, @Nullable String region, Pigeon.Result<Boolean> result) {
        CosXmlService service = getCosXmlService(serviceKey);
        GetBucketVersioningRequest request = new GetBucketVersioningRequest(bucket);
        if (region != null) {
            request.setRegion(region);
        }
        service.getBucketVersioningAsync(request, new CosXmlResultListener() {
            @Override
            public void onSuccess(CosXmlRequest cosXmlRequest, CosXmlResult cosXmlResult) {
                try {
                    VersioningConfiguration versioningConfiguration = ((GetBucketVersioningResult) cosXmlResult).versioningConfiguration;
                    if (versioningConfiguration != null) {
                        result.success("Enabled".equals(versioningConfiguration.status));
                    } else {
                        result.success(false);
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                    result.error(e);
                }
            }

            @Override
            public void onFail(CosXmlRequest cosXmlRequest, @Nullable CosXmlClientException e, @Nullable CosXmlServiceException e1) {
                if (e != null) {
                    e.printStackTrace();
                    result.error(e);
                } else {
                    e1.printStackTrace();
                    result.error(e1);
                }
            }
        });
    }

    @Override
    public void putBucketVersioning(@NonNull String serviceKey, @NonNull String bucket, @Nullable String region, @NonNull Boolean enable, Pigeon.Result<Void> result) {
        CosXmlService service = getCosXmlService(serviceKey);
        PutBucketVersioningRequest request = new PutBucketVersioningRequest(bucket);
        request.setEnableVersion(enable);
        if (region != null) {
            request.setRegion(region);
        }
        service.putBucketVersionAsync(request, new CosXmlResultListener() {
            @Override
            public void onSuccess(CosXmlRequest cosXmlRequest, CosXmlResult cosXmlResult) {
                result.success(null);
            }

            @Override
            public void onFail(CosXmlRequest cosXmlRequest, @Nullable CosXmlClientException e, @Nullable CosXmlServiceException e1) {
                if (e != null) {
                    e.printStackTrace();
                    result.error(e);
                } else {
                    e1.printStackTrace();
                    result.error(e1);
                }
            }
        });
    }

    @Override
    public void doesBucketExist(@NonNull String serviceKey, @NonNull String bucket, Pigeon.Result<Boolean> result) {
        CosXmlService service = getCosXmlService(serviceKey);
        service.doesBucketExistAsync(bucket, new CosXmlBooleanListener() {
            @Override
            public void onSuccess(boolean b) {
                result.success(b);
            }

            @Override
            public void onFail(@Nullable CosXmlClientException e, @Nullable CosXmlServiceException e1) {
                if (e != null) {
                    e.printStackTrace();
                    result.error(e);
                } else {
                    e1.printStackTrace();
                    result.error(e1);
                }
            }
        });
    }

    @Override
    public void doesObjectExist(@NonNull String serviceKey, @NonNull String bucket, @NonNull String cosPath, Pigeon.Result<Boolean> result) {
        CosXmlService service = getCosXmlService(serviceKey);
        service.doesObjectExistAsync(bucket, cosPath, new CosXmlBooleanListener() {
            @Override
            public void onSuccess(boolean b) {
                result.success(b);
            }

            @Override
            public void onFail(@Nullable CosXmlClientException e, @Nullable CosXmlServiceException e1) {
                if (e != null) {
                    e.printStackTrace();
                    result.error(e);
                } else {
                    e1.printStackTrace();
                    result.error(e1);
                }
            }
        });
    }

    @Override
    public void cancelAll(@NonNull String serviceKey) {
        CosXmlService service = getCosXmlService(serviceKey);
        service.cancelAll();
    }

    private CosXmlService getCosXmlService(String serviceKey) {
        if(cosServices.containsKey(serviceKey)) {
            return cosServices.get(serviceKey);
        } else {
            String key = DEFAULT_KEY.equals(serviceKey)?"default":serviceKey;
            throw new IllegalArgumentException(key + " CosService unregistered, Please register first");
        }
    }

    private CosXmlService buildCosXmlService(Context context, @NonNull Pigeon.CosXmlServiceConfig config) {
        CosXmlServiceConfig.Builder serviceConfigBuilder = new CosXmlServiceConfig.Builder();
        if (config.getRegion() != null) {
            serviceConfigBuilder.setRegion(config.getRegion());
        }
        if (config.getConnectionTimeout() != null) {
            serviceConfigBuilder.setConnectionTimeout(Math.toIntExact(config.getConnectionTimeout()));
        }
        if (config.getSocketTimeout() != null) {
            serviceConfigBuilder.setSocketTimeout(Math.toIntExact(config.getSocketTimeout()));
        }
        if (config.getIsHttps() != null) {
            serviceConfigBuilder.isHttps(config.getIsHttps());
        }
        if (config.getDomainSwitch() != null) {
            serviceConfigBuilder.setDomainSwitch(config.getDomainSwitch());
        }
        if (config.getHost() != null) {
            serviceConfigBuilder.setHost(config.getHost());
        }
        if (config.getHostFormat() != null) {
            serviceConfigBuilder.setHostFormat(config.getHostFormat());
        }
        if (config.getPort() != null) {
            serviceConfigBuilder.setPort(Math.toIntExact(config.getPort()));
        }
        if (config.getIsDebuggable() != null) {
            serviceConfigBuilder.setDebuggable(config.getIsDebuggable());
        }
        if (config.getSignInUrl() != null) {
            serviceConfigBuilder.setSignInUrl(config.getSignInUrl());
        }
        if (config.getDnsCache() != null) {
            serviceConfigBuilder.dnsCache(config.getDnsCache());
        }
        if (config.getAccelerate() != null) {
            serviceConfigBuilder.setAccelerate(config.getAccelerate());
        }
        if (!TextUtils.isEmpty(config.getUserAgent())) {
            serviceConfigBuilder.setUserAgentExtended(config.getUserAgent());
        } else {
            serviceConfigBuilder.setUserAgentExtended("FlutterPlugin");
        }

        synchronized (credentialProviderLock) {
            if (qCloudCredentialProvider == null) {
                try {
                    credentialProviderLock.wait(15000);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
        }

        if (qCloudCredentialProvider == null) {
            throw new IllegalArgumentException("Please call method initWithPlainSecret or initWithSessionCredentialCallback first");
        } else {
            CosXmlService cosXmlService = new CosXmlService(context, serviceConfigBuilder.builder(), qCloudCredentialProvider);
            if(dnsMap != null) {
                try {
                    for (String domain: dnsMap.keySet()) {
                        if(dnsMap.get(domain) != null && dnsMap.get(domain).size() > 0){
                            cosXmlService.addCustomerDNS(domain, dnsMap.get(domain).toArray(new String[0]));
                        }
                    }
                } catch (CosXmlClientException e) {
                    e.printStackTrace();
                }
            }
            if(initDnsFetch){
                cosXmlService.addCustomerDNSFetch(domain -> {
                    CompletableFuture<List<String>> future = new CompletableFuture<>();
                    //此处调用有可能不是在主线程中 需要切换到主线程 因为调用flutter只能在主线程
                    runMainThread(() ->
                            flutterCosApi.fetchDns(domain, future::complete)
                    );
                    List<InetAddress> inetAddresses = new ArrayList<>();
                    try {
                        List<String> ipList = future.get(60, TimeUnit.SECONDS);
                        if(ipList != null && ipList.size() > 0){
                            for (String ip : ipList) {
                                inetAddresses.add(InetAddress.getByName(ip));
                            }
                        }
                        return inetAddresses;
                    } catch (InterruptedException | ExecutionException | TimeoutException e) {
                        e.printStackTrace();
                        return null;
                    }
                });
            }
            return cosXmlService;
        }
    }

    private TransferManager getTransferManager(String transferKey) {
        if(transferManagers.containsKey(transferKey)) {
            return transferManagers.get(transferKey);
        } else {
            String key = DEFAULT_KEY.equals(transferKey)?"default":transferKey;
            throw new IllegalArgumentException(key + " TransferManager unregistered, Please register first");
        }
    }

    private TransferManager buildTransferManager(Context context, @NonNull Pigeon.CosXmlServiceConfig config, @Nullable Pigeon.TransferConfig transferConfig) {
        TransferConfig.Builder builder = new TransferConfig.Builder();
        if(transferConfig != null) {
            if (transferConfig.getForceSimpleUpload() != null) {
                builder.setForceSimpleUpload(transferConfig.getForceSimpleUpload());
            }
            if (transferConfig.getEnableVerification() != null) {
                builder.setVerifyCRC64(transferConfig.getEnableVerification());
            }
            if (transferConfig.getDivisionForUpload() != null) {
                builder.setDivisionForUpload(transferConfig.getDivisionForUpload());
            }
            if (transferConfig.getSliceSizeForUpload() != null) {
                builder.setSliceSizeForUpload(transferConfig.getSliceSizeForUpload());
            }
        }
        CosXmlService cosXmlService = buildCosXmlService(context, config);
        return new TransferManager(cosXmlService, builder.build());
    }

    @NonNull
    @Override
    public String upload(
            @NonNull String transferKey,
            @NonNull String bucket,
            @NonNull String cosPath,
            @Nullable String region,
            @Nullable String filePath,
            @Nullable byte[] byteArr,
            @Nullable String uploadId,
            @Nullable String stroageClass,
            @Nullable Long trafficLimit,
            @Nullable String callbackParam,
            @Nullable Long resultCallbackKey,
            @Nullable Long stateCallbackKey,
            @Nullable Long progressCallbackKey,
            @Nullable Long InitMultipleUploadCallbackKey
    ) {
        TransferManager transferManager = getTransferManager(transferKey);
        PutObjectRequest request;
        if (filePath != null) {
            request = new PutObjectRequest(bucket, cosPath, filePath);
        } else {
            request = new PutObjectRequest(bucket, cosPath, byteArr);
        }
        if (region != null) {
            request.setRegion(region);
        }
        if (stroageClass != null) {
            request.setStroageClass(COSStorageClass.fromString(stroageClass));
        }
        if (trafficLimit != null) {
            request.setTrafficLimit(trafficLimit);
        }
        if (callbackParam != null) {
            try {
                String callbackBase64 = DigestUtils.getBase64(callbackParam);
                // 配置回调参数
                request.setRequestHeaders("x-cos-callback", callbackBase64, false);
            } catch (Exception ignored){}
        }
        COSXMLUploadTask task = transferManager.upload(request, uploadId);
        setTaskListener(task, transferKey, resultCallbackKey, stateCallbackKey, progressCallbackKey, InitMultipleUploadCallbackKey);
        String taskKey = String.valueOf(task.hashCode());
        taskMap.put(taskKey, task);
        return taskKey;
    }

    @NonNull
    @Override
    public String download(
            @NonNull String transferKey,
            @NonNull String bucket,
            @NonNull String cosPath,
            @Nullable String region,
            @NonNull String savePath,
            @Nullable String versionId,
            @Nullable Long trafficLimit,
            @Nullable Long resultCallbackKey,
            @Nullable Long stateCallbackKey,
            @Nullable Long progressCallbackKey
    ) {
        TransferManager transferManager = getTransferManager(transferKey);
        int separator = savePath.lastIndexOf("/");
        GetObjectRequest request = new GetObjectRequest(bucket, cosPath,
                savePath.substring(0, separator + 1),
                savePath.substring(separator + 1));
        if (region != null) {
            request.setRegion(region);
        }
        if (versionId != null) {
            request.setVersionId(versionId);
        }
        if (trafficLimit != null) {
            request.setTrafficLimit(trafficLimit);
        }
        COSXMLDownloadTask task = transferManager.download(context, request);
        setTaskListener(task, transferKey, resultCallbackKey, stateCallbackKey, progressCallbackKey, null);
        String taskKey = String.valueOf(task.hashCode());
        taskMap.put(taskKey, task);
        return taskKey;
    }

    @Override
    public void pause(@NonNull String taskId, @NonNull String transferKey) {
        COSXMLTask task = taskMap.get(taskId);
        if (task != null) {
            task.pause();
        } else {
            throw new IllegalArgumentException();
        }
    }

    @Override
    public void resume(@NonNull String taskId, @NonNull String transferKey) {
        COSXMLTask task = taskMap.get(taskId);
        if (task != null) {
            task.resume();
        } else {
            throw new IllegalArgumentException();
        }
    }

    @Override
    public void cancel(@NonNull String taskId, @NonNull String transferKey) {
        COSXMLTask task = taskMap.get(taskId);
        if (task != null) {
            task.cancel();
        } else {
            throw new IllegalArgumentException();
        }
    }

    private Pigeon.CosXmlClientException toPigeonCosXmlClientException(CosXmlClientException e) {
        if (e != null) {
            return new Pigeon.CosXmlClientException.Builder().setErrorCode((long) (e.errorCode)).setMessage(e.getMessage()).build();
        } else {
            return null;
        }
    }

    private Pigeon.CosXmlServiceException toPigeonCosXmlServiceException(CosXmlServiceException e) {
        if (e != null) {
            return new Pigeon.CosXmlServiceException.Builder()
                    .setStatusCode((long) e.getStatusCode())
                    .setHttpMsg(e.getHttpMessage())
                    .setRequestId(e.getRequestId())
                    .setServiceName(e.getServiceName())
                    .setErrorCode(e.getErrorCode())
                    .setErrorMessage(e.getErrorMessage())
                    .build();
        } else {
            return null;
        }
    }

    private void setTaskListener(
            @NonNull COSXMLTask task,
            @NonNull String transferKey,
            @Nullable Long resultCallbackKey,
            @Nullable Long stateCallbackKey,
            @Nullable Long progressCallbackKey,
            @Nullable Long initMultipleUploadCallbackKey) {
        task.setCosXmlResultListener(new CosXmlResultListener() {
            @Override
            public void onSuccess(CosXmlRequest cosXmlRequest, CosXmlResult cosXmlResult) {
                if (resultCallbackKey != null) {
                    runMainThread(() ->{
                                Map<String, String> header = simplifyHeader(cosXmlResult.headers);
                                if(task instanceof COSXMLUploadTask){
                                    Map<String, String> uploadResultMap = new HashMap<>();
                                    COSXMLUploadTask.COSXMLUploadTaskResult uploadResult =
                                            (COSXMLUploadTask.COSXMLUploadTaskResult) cosXmlResult;
                                    uploadResultMap.put("accessUrl", cosXmlResult.accessUrl);
                                    uploadResultMap.put("eTag", uploadResult.eTag);
                                    if(header.containsKey("x-cos-hash-crc64ecma")){
                                        uploadResultMap.put("crc64ecma", header.get("x-cos-hash-crc64ecma"));
                                    }
                                    Pigeon.CosXmlResult.Builder resultBuilder = new Pigeon.CosXmlResult.Builder();
                                    resultBuilder.setETag(uploadResult.eTag);
                                    resultBuilder.setAccessUrl(cosXmlResult.accessUrl);
                                    if(uploadResult.callbackResult != null){
                                        Pigeon.CallbackResult.Builder callbackResultBuilder = new Pigeon.CallbackResult.Builder();
                                        callbackResultBuilder.setStatus(Long.valueOf(uploadResult.callbackResult.status));
                                        callbackResultBuilder.setCallbackBody(uploadResult.callbackResult.getCallbackBody());
                                        if(uploadResult.callbackResult.error != null){
                                            Pigeon.CallbackResultError.Builder callbackResultError = new Pigeon.CallbackResultError.Builder();
                                            callbackResultError.setCode(uploadResult.callbackResult.error.code);
                                            callbackResultError.setMessage(uploadResult.callbackResult.error.message);
                                            callbackResultBuilder.setError(callbackResultError.build());
                                        }
                                        resultBuilder.setCallbackResult(callbackResultBuilder.build());
                                    }
                                    flutterCosApi.resultSuccessCallback(transferKey, resultCallbackKey, uploadResultMap, resultBuilder.build(), getVoidReply());
                                } else {
                                    flutterCosApi.resultSuccessCallback(transferKey, resultCallbackKey, header, null, getVoidReply());
                                }
                            }
                    );
                }
                String taskKey = String.valueOf(task.hashCode());
                taskMap.remove(taskKey);
            }

            @Override
            public void onFail(CosXmlRequest cosXmlRequest, @Nullable CosXmlClientException e, @Nullable CosXmlServiceException e1) {
                if (resultCallbackKey != null) {
                    runMainThread(() ->
                                    flutterCosApi.resultFailCallback(
                                            transferKey,
                                            resultCallbackKey,
                                            toPigeonCosXmlClientException(e),
                                            toPigeonCosXmlServiceException(e1),
                                            getVoidReply()
                                    )
                            );
                }
                String taskKey = String.valueOf(task.hashCode());
                taskMap.remove(taskKey);
            }
        });
        task.setCosXmlProgressListener((l, l1) -> {
            if (progressCallbackKey != null) {
                runMainThread(() -> flutterCosApi.progressCallback(transferKey, progressCallbackKey, l, l1, getVoidReply()));
            }
        });
        task.setTransferStateListener(transferState -> {
            if (stateCallbackKey != null) {
                runMainThread(() -> flutterCosApi.stateCallback(transferKey, stateCallbackKey, transferState.toString(), getVoidReply()));
            }
        });
        //上传注册 分块上传初始化完成的回调
        if(task instanceof COSXMLUploadTask){
            task.setInitMultipleUploadListener(new InitMultipleUploadListener() {
                @Override
                public void onSuccess(InitiateMultipartUpload initiateMultipartUpload) {
                    if (initMultipleUploadCallbackKey != null) {
                        runMainThread(() -> flutterCosApi.initMultipleUploadCallback(
                                transferKey,
                                initMultipleUploadCallbackKey,
                                initiateMultipartUpload.bucket,
                                initiateMultipartUpload.key,
                                initiateMultipartUpload.uploadId,
                                getVoidReply()));
                    }
                }
            });
        }
    }

    private Map<String, String> simplifyHeader(Map<String, List<String>> headers) {
        if (headers == null) return null;

        HashMap<String, String> map = new HashMap<>();
        for (String key : headers.keySet()) {
            List<String> values = headers.get(key);
            if (values != null && !values.isEmpty()) {
                map.put(key, values.get(0));
            }
        }
        return map;
    }

    private void runMainThread(Runnable runnable){
        Handler mainHandler = new Handler(Looper.getMainLooper());
        mainHandler.post(runnable);
    }

    private Pigeon.FlutterCosApi.Reply<Void> getVoidReply() {
        return reply -> {
        };
    }
}
