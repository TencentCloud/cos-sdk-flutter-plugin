enum TransferState {
  CONSTRAINED,

  /// This state represents a transfer that has been queued, but has not yet
  /// started
  /// <br>
  WAITING,

  /// This state represents a transfer that is currently uploading or
  /// downloading data
  IN_PROGRESS,

  /// This state represents a transfer that is paused manual
  PAUSED,

  /// This state represents a transfer that has been resumed and queued for
  /// execution, but has not started to actively transfer data.
  /// <br>
  RESUMED_WAITING,

  /// This state represents a transfer that is completed
  COMPLETED,

  /// This state represents a transfer that is canceled
  CANCELED,

  /// This state represents a transfer that has failed
  FAILED,
  /// This is an internal value used to detect if the current transfer is in an
  /// unknown state
  UNKNOWN
}
