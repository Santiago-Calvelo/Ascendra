import 'dart:io';

void main() {
  final file = File('build/flutter_assets/AssetManifest.bin');
  if (!file.existsSync()) {
    print('AssetManifest.bin not found');
    return;
  }

  // AssetManifest.bin is a standard message codec encoded map
  // But we can just try to read it as strings for a quick check
  final bytes = file.readAsBytesSync();
  print('Manifest bytes length: ${bytes.length}');
  
  // Try to find the strings in the binary file
  final content = String.fromCharCodes(bytes);
  print('Strings in manifest:');
  final regex = RegExp(r'assets/[^ \x00-\x1F]+');
  final matches = regex.allMatches(content);
  for (final match in matches) {
    print(match.group(0));
  }
}
