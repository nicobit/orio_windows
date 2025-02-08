class Utilities {
  // A static method to simulate a network request with a Future
  static Future<String> fetchDataFromNetwork() async {
    // Simulate network delay
    await Future.delayed(Duration(seconds: 2));
    // Return fetched data
    return 'Fetched data';
  }
}
