import 'network_tool.dart';

class NetworkTransaction {
  final NetworkRequest request;
  NetworkResponse? response;

  NetworkTransaction({required this.request, this.response});

  String get id => request.id;
  bool get hasResponse => response != null;
  bool get isPending => response == null;
  bool get isSuccessful => response?.isSuccessful ?? false;
  bool get hasFailed => response?.hasError ?? false;

  Duration? get duration => response?.duration;

  @override
  String toString() {
    return 'NetworkTransaction(id: $id, request: ${request.method} ${request.uri}, hasResponse: $hasResponse, statusCode: ${response?.statusCode})';
  }
}

class NetworkToolMemoryImpl implements NetworkTool {
  final List<NetworkTransaction> _transactions = [];
  final int maxLogSize;

  NetworkToolMemoryImpl({this.maxLogSize = 500});

  @override
  void logRequest(NetworkRequest request) {
    _transactions.add(NetworkTransaction(request: request));
    if (_transactions.length > maxLogSize) {
      _transactions.removeAt(0);
    }
  }

  @override
  void logResponse(NetworkResponse response) {
    final transaction = _transactions.cast<NetworkTransaction?>().firstWhere(
      (t) => t?.request.id == response.requestId,
      orElse: () => null,
    );

    if (transaction != null) {
      transaction.response = response;
    }
  }

  List<NetworkTransaction> get transactions => List.unmodifiable(_transactions);

  List<NetworkTransaction> getTransactionsByMethod(String method) {
    return _transactions.where((t) => t.request.method == method).toList();
  }

  List<NetworkTransaction> getTransactionsByStatus(int statusCode) {
    return _transactions
        .where((t) => t.response?.statusCode == statusCode)
        .toList();
  }

  List<NetworkTransaction> getPendingTransactions() {
    return _transactions.where((t) => t.isPending).toList();
  }

  List<NetworkTransaction> getCompletedTransactions() {
    return _transactions.where((t) => t.hasResponse).toList();
  }

  List<NetworkTransaction> getFailedTransactions() {
    return _transactions
        .where((t) => t.hasFailed || (t.hasResponse && !t.isSuccessful))
        .toList();
  }

  List<NetworkTransaction> getSuccessfulTransactions() {
    return _transactions.where((t) => t.isSuccessful).toList();
  }

  NetworkTransaction? getTransactionById(String id) {
    try {
      return _transactions.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  List<NetworkRequest> get requests =>
      _transactions.map((t) => t.request).toList();

  List<NetworkResponse> get responses => _transactions
      .where((t) => t.response != null)
      .map((t) => t.response!)
      .toList();

  void clearAll() {
    _transactions.clear();
  }

  int get transactionCount => _transactions.length;
  int get pendingCount => getPendingTransactions().length;
  int get completedCount => getCompletedTransactions().length;
  int get failedCount => getFailedTransactions().length;
}
