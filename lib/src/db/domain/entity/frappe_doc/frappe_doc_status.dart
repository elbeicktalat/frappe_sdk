/// Represents the status of a Frappe document.
enum FrappeDocStatus {
  /// The document is saved.
  saved(0),

  /// The document is submitted.
  submitted(1),

  /// The document is cancelled.
  cancelled(2);

  const FrappeDocStatus(this.value);

  /// The value of the [FrappeDocStatus].
  final int value;

  /// Parses the value to a [FrappeDocStatus].
  static FrappeDocStatus parse(int value) {
    switch (value) {
      case 0:
        return saved;
      case 1:
        return submitted;
      case 2:
        return cancelled;
    }
    throw Exception('Unknown value: $value');
  }
}
