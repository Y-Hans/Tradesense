/// Represents the network connectivity status of the device.
///
/// This domain model abstracts connectivity details from underlying packages.
enum ConnectivityStatus {
  unknown,
  online,
  offline;

  /// Returns true if the status is online.
  bool get isOnline => this == ConnectivityStatus.online;

  /// Returns true if the status is offline.
  bool get isOffline => this == ConnectivityStatus.offline;

  /// Returns true if the status is unknown (initial state before check completes).
  bool get isUnknown => this == ConnectivityStatus.unknown;
}
