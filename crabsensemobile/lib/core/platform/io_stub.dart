/// Minimal dart:io stand-in so CrabSenseApp can compile for Flutter web.
/// File/camera flows are no-ops in the browser.
library;

class FileMode {
  const FileMode._(this._v);
  final int _v;
  static const read = FileMode._(0);
  static const write = FileMode._(1);
  static const append = FileMode._(2);
  static const writeOnly = FileMode._(3);
  static const writeOnlyAppend = FileMode._(4);
}

class Platform {
  static bool get isAndroid => false;
  static bool get isIOS => false;
  static bool get isWindows => false;
  static bool get isLinux => false;
  static bool get isMacOS => false;
  static bool get isFuchsia => false;
  static String get operatingSystem => 'web';
  static String get operatingSystemVersion => '';
  static Map<String, String> get environment => const {};
}

class File implements FileSystemEntity {
  File(this.path);
  @override
  final String path;

  Future<bool> exists() async => false;
  bool existsSync() => false;
  Future<int> length() async => 0;
  int lengthSync() => 0;
  Future<List<int>> readAsBytes() async => <int>[];
  Future<String> readAsString({encoding}) async => '';
  Future<File> writeAsBytes(List<int> bytes, {FileMode mode = FileMode.write, bool flush = false}) async => this;
  Future<File> writeAsString(String contents, {FileMode mode = FileMode.write, bool flush = false, encoding}) async => this;
  Future<File> copy(String newPath) async => File(newPath);
  Future<FileSystemEntity> delete({bool recursive = false}) async => this;
  void deleteSync({bool recursive = false}) {}
  Stream<List<int>> openRead([int? start, int? end]) => const Stream.empty();
Uri get uri => Uri.parse(path.contains('://') ? path : 'file://$path');
  Future<DateTime> lastModified() async => DateTime.fromMillisecondsSinceEpoch(0);
}

class Directory implements FileSystemEntity {
  Directory(this.path);
  @override
  final String path;
  Future<bool> exists() async => false;
  bool existsSync() => false;
  Future<Directory> create({bool recursive = false}) async => this;
  void createSync({bool recursive = false}) {}
  Stream<FileSystemEntity> list({bool recursive = false, bool followLinks = true}) => const Stream.empty();
  List<FileSystemEntity> listSync({bool recursive = false, bool followLinks = true}) => const [];
  Future<FileSystemEntity> delete({bool recursive = false}) async => this;
}

abstract class FileSystemEntity {
  String get path;
}

class IOException implements Exception {
  IOException([this.message = '']);
  final String message;
  @override
  String toString() => 'IOException: $message';
}

class FileSystemException extends IOException {
  FileSystemException([super.message = 'File system unavailable on web', this.path, this.osError]);
  final String? path;
  final Object? osError;
}

class SocketException extends IOException {
  SocketException([super.message = 'Socket unavailable on web']);
}

class HttpException extends IOException {
  HttpException([super.message = 'HTTP exception']);
}

class HandshakeException extends IOException {
  HandshakeException([super.message = 'TLS handshake failed']);
}

class stdout {
  static void writeln([Object? o]) {}
}
