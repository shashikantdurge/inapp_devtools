import 'dart:io';
import 'package:inapp_devtools/inapp_devtools.dart';

/// Example showing how to use InstrumentedHttpClient with NetworkToolMemoryImpl
/// to automatically log all HTTP requests and responses.
void main() async {
  // 1. Create the network tool to store logs
  final networkTool = NetworkToolMemoryImpl(maxLogSize: 100);

  // 2. Create the instrumented HTTP client
  final httpClient = HttpClient();

  // 3. Make HTTP requests as usual
  try {
    final request = await httpClient.getUrl(
      Uri.parse('https://api.github.com/users/dart-lang'),
    );
    final response = await request.close();

    print('Status: ${response.statusCode}');
    print('Total transactions logged: ${networkTool.transactionCount}');

    // 4. Query the logged data
    final transactions = networkTool.transactions;
    for (final transaction in transactions) {
      print(
        'Request: ${transaction.request.method} ${transaction.request.uri}',
      );
      if (transaction.hasResponse) {
        print(
          'Response: ${transaction.response!.statusCode} (${transaction.duration})',
        );
      } else {
        print('Response: Pending...');
      }
    }

    // Get only successful transactions
    final successful = networkTool.getSuccessfulTransactions();
    print('Successful requests: ${successful.length}');

    // Get failed transactions
    final failed = networkTool.getFailedTransactions();
    print('Failed requests: ${failed.length}');

    // Get pending transactions (no response yet)
    final pending = networkTool.getPendingTransactions();
    print('Pending requests: ${pending.length}');
  } finally {
    httpClient.close();
  }
}
