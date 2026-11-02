/// System notification once downloads end, for a user who looked away.
abstract interface class RunNotifier {
  void finished({required String title, required String body});
}
