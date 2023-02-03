import 'pigeon.dart';

class TransferTask {
  late final String _taskId;
  late final String _transferKey;
  late final CosTransferApi _transferApi;

  TransferTask(this._transferKey, this._taskId, this._transferApi);

  Future<void> pause() {
    return _transferApi.pause(_taskId, _transferKey);
  }

  Future<void> resume() {
    return _transferApi.resume(_taskId, _transferKey);
  }

  Future<void> cancel() {
    return _transferApi.cancel(_taskId, _transferKey);
  }
}