/// Parses Supabase `timestamptz` values into UTC [DateTime].
DateTime parseTimestamp(dynamic value) {
  if (value == null) {
    return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }
  if (value is DateTime) {
    return value.toUtc();
  }
  return DateTime.parse(value.toString()).toUtc();
}

/// Reads a snake_case or camelCase key from a JSON map.
T? readJson<T>(Map<String, dynamic> json, String snake, String camel) {
  if (json.containsKey(camel)) {
    return json[camel] as T?;
  }
  return json[snake] as T?;
}

String requireString(Map<String, dynamic> json, String snake, String camel) {
  final value = readJson<dynamic>(json, snake, camel);
  if (value == null) {
    throw FormatException('Missing required field: $snake / $camel');
  }
  return value.toString();
}

int? readInt(Map<String, dynamic> json, String snake, String camel) {
  final value = readJson<dynamic>(json, snake, camel);
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value.toString());
}

double? readDouble(Map<String, dynamic> json, String snake, String camel) {
  final value = readJson<dynamic>(json, snake, camel);
  if (value == null) {
    return null;
  }
  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value.toString());
}

Map<String, dynamic> toSnakeCase(Map<String, dynamic> json) {
  return json.map((key, value) {
    final snake = key.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => '_${match.group(0)!.toLowerCase()}',
    );
    return MapEntry(snake, value);
  });
}
