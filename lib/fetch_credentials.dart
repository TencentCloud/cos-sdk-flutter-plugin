import 'pigeon.dart';

abstract class IFetchCredentials{
  Future<SessionQCloudCredentials> fetchSessionCredentials();
}