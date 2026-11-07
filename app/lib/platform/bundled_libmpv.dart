/// Ka7's own player library, beside the app in a Linux package
/// (`<app>/lib/libmpv.so.2`, LGPL, tool/linux/build_libmpv.sh); null when
/// the app runs from source (`flutter run`: the system's is used).
String? bundledLibmpv(
  String executable, {
  required bool Function(String path) exists,
}) {
  final path =
      '${executable.substring(0, executable.lastIndexOf('/'))}/lib/libmpv.so.2';
  return exists(path) ? path : null;
}
