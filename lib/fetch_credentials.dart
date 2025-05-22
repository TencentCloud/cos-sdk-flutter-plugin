import 'pigeon.dart';

abstract class IFetchCredentials{
  Future<SessionQCloudCredentials> fetchSessionCredentials();
}

abstract class IFetchScopeLimitCredentials{
  Future<SessionQCloudCredentials> fetchScopeLimitCredentials(List<STSCredentialScope?> stsCredentialScopes);
}

abstract class IFetchCLsChannelCredentials{
  Future<SessionQCloudCredentials> fetchCLsChannelSessionCredentials();
}