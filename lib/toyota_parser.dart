// lib/toyota_parser.dart
class ToyotaDataParser {
  final void Function(String id, double value) onValueParsed;

  ToyotaDataParser({required this.onValueParsed});

  void parse(String line) {
    if (line.isEmpty) return;

    final parts = line.replaceAll(RegExp(r'[\[\];"]'), '').split(',');
    if (parts.length < 2) return;

    final id = parts.last.trim(); // last part is the 9-digit ID
    final value = double.tryParse(parts[1].trim()) ?? 0;

    onValueParsed(id, value);
  }
}