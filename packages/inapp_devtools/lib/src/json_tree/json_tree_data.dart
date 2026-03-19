import 'dart:convert';

import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

/// Regular expression matching JSON escape sequences.
///
/// Matches:
/// - Single-char escapes: \", \\, \/, \b, \f, \n, \r, \t
/// - Unicode escapes: \uXXXX (exactly 4 hex digits)
const _jsonEscapeSequencePattern = r'\\["\\/bfnrt]|\\u[0-9a-fA-F]{4}';

/// Base class representing a node in the JSON tree structure.
///
/// This is a sealed class with different implementations for various JSON types:
/// - [ListTreeData]: JSON arrays `[...]`
/// - [MapTreeData]: JSON objects `{...}`
/// - [PrimitiveTreeData]: JSON primitives (string, number, boolean, null)
/// - [StringPrimitiveTreeData]: JSON strings with special character highlighting
/// - [BracketTreeData]: Closing brackets for arrays and objects
///
/// Each node contains:
/// - [lineNumber]: The line number in the visual tree representation
/// - [key]: The JSON key (for object properties), array index (for arrays), or null
sealed class JsonTreeData {
  const JsonTreeData({required this.lineNumber, this.key});

  /// The line number where this node appears in the tree view.
  final int lineNumber;

  /// The key associated with this node.
  ///
  /// For object properties: the property name (e.g., `"name"`)
  /// For array items: the array index (e.g., `"[0]"`)
  /// For root nodes: `null`
  final String? key;

  /// Builds a tree view node structure from any JSON-compatible data.
  ///
  /// Converts the given [json] data into a hierarchical tree structure
  /// suitable for display in a TreeView widget.
  ///
  /// Returns a record containing:
  /// - The root [TreeViewNode] of the constructed tree
  /// - The next available line number after building the tree
  ///
  /// Example:
  /// ```dart
  /// final json = {"name": "Alice", "age": 30};
  /// final (rootNode, _) = JsonTreeData.buildTreeViewNode(json);
  /// ```
  static (TreeViewNode<JsonTreeData>, int) buildTreeViewNode(dynamic json) {
    return _buildTreeViewNode(json);
  }
}

/// Represents a JSON array node in the tree structure.
///
/// Contains metadata about the array for display purposes:
/// - [collapsedValue]: A preview of the array contents when collapsed
/// - [itemCount]: The number of items in the array
///
/// Example: For `[1, 2, 3]`, this would store `collapsedValue: "1, 2, 3"`
/// and `itemCount: 3`.
class ListTreeData extends JsonTreeData {
  const ListTreeData({
    required super.lineNumber,
    required this.collapsedValue,
    required this.itemCount,
    super.key,
  });

  /// A preview string of the array contents (without surrounding brackets).
  ///
  /// Used when the array is collapsed to show a glimpse of its contents.
  final String collapsedValue;

  /// The total number of items in the array.
  final int itemCount;

  @override
  String toString() => "$key: $collapsedValue // $itemCount items";
}

/// Represents a JSON object node in the tree structure.
///
/// Contains metadata about the object for display purposes:
/// - [collapsedValue]: A preview of the object contents when collapsed
/// - [itemCount]: The number of properties in the object
///
/// Example: For `{"name": "Alice", "age": 30}`, this would store
/// `collapsedValue: "name: Alice, age: 30"` and `itemCount: 2`.
class MapTreeData extends JsonTreeData {
  const MapTreeData({
    required super.lineNumber,
    required this.collapsedValue,
    required this.itemCount,
    super.key,
  });

  /// A preview string of the object contents (without surrounding braces).
  ///
  /// Used when the object is collapsed to show a glimpse of its contents.
  final String collapsedValue;

  /// The total number of properties in the object.
  final int itemCount;

  @override
  String toString() => "$key: $collapsedValue // $itemCount items";
}

/// Enum representing the different primitive types in JSON.
///
/// - [string]: JSON string values (e.g., `"hello"`)
/// - [number]: JSON numeric values (e.g., `42`, `3.14`)
/// - [boolean]: JSON boolean values (`true` or `false`)
/// - [nullValue]: JSON null value (`null`)
enum PrimitiveType { string, number, boolean, nullValue }

/// Represents a JSON primitive value node (string, number, boolean, or null).
///
/// This class stores:
/// - [primitiveType]: The type of primitive value
/// - [value]: The string representation of the value
///
/// Examples:
/// - String: `"hello"` → `value: "\"hello\""`
/// - Number: `42` → `value: "42"`
/// - Boolean: `true` → `value: "true"`
/// - Null: `null` → `value: "null"`
class PrimitiveTreeData extends JsonTreeData {
  const PrimitiveTreeData({
    required super.lineNumber,
    required this.primitiveType,
    required super.key,
    required this.value,
  });

  /// The type of this primitive value.
  final PrimitiveType primitiveType;

  /// The string representation of this value.
  ///
  /// For strings, this includes the surrounding quotes.
  /// For other types, this is the result of calling `toString()`.
  final String value;

  @override
  String toString() => "$key : $value";
}

/// Represents a JSON string value with special character formatting.
///
/// This is a specialized version of [PrimitiveTreeData] that breaks down
/// a string into segments of plain text and special escape sequences
/// (like `\n`, `\t`, `\"`, etc.) for syntax highlighting purposes.
///
/// The [formattedValue] list contains tuples of:
/// - The substring content
/// - The character type ([StringCharType.plain] or [StringCharType.special])
///
/// Example: For the string `"hello\nworld"`, the [formattedValue] would be:
/// ```dart
/// [
///   ("hello", StringCharType.plain),
///   ("\n", StringCharType.special),
///   ("world", StringCharType.plain)
/// ]
/// ```
class StringPrimitiveTreeData extends PrimitiveTreeData {
  const StringPrimitiveTreeData({
    required super.lineNumber,
    required super.primitiveType,
    required super.key,
    required super.value,
    required this.formattedValue,
  });

  /// A list of string segments with their character types.
  ///
  /// Each tuple contains:
  /// - The substring content
  /// - Whether it's plain text or a special escape sequence
  final List<(String, StringCharType)> formattedValue;

  @override
  String toString() => "$key : $formattedValue";
}

/// Enum representing the type of character in a JSON string.
///
/// - [plain]: Regular text characters
/// - [special]: Escape sequences like `\n`, `\t`, `\"`, `\\`, etc.
enum StringCharType { plain, special }

/// Represents a closing bracket node in the tree structure.
///
/// These nodes are used to display the closing brackets (`]` or `}`)
/// for arrays and objects in the tree view. They appear as the last
/// child of their parent container node.
///
/// The [value] field contains either `"]"` for arrays or `"}"` for objects.
class BracketTreeData extends JsonTreeData {
  const BracketTreeData({required super.lineNumber, required this.value});

  /// The bracket character: either `"]"` or `"}"`.
  final String value;

  @override
  String toString() => value;
}

/// Exception thrown when the JSON tree builder encounters unsupported data types.
///
/// This exception is thrown when attempting to build a tree from data
/// that is not a valid JSON type (String, num, bool, null, List, or Map).
class JsonTreeException implements Exception {
  /// Creates a new JSON tree exception with the given [message].
  JsonTreeException(this.message);

  /// A descriptive message explaining what went wrong.
  final String message;

  @override
  String toString() => 'JsonTreeException: $message';
}

/// Builds a tree view node from any JSON-compatible data.
///
/// This is the main entry point for converting JSON data into a tree structure.
/// It dispatches to specialized builders based on the data type.
///
/// Parameters:
/// - [data]: The JSON data to convert (List, Map, String, num, bool, or null)
/// - [key]: Optional key for this node (property name or array index)
/// - [lineNumber]: The starting line number for this node (defaults to 1)
///
/// Returns a record containing:
/// - The constructed [TreeViewNode]
/// - The next available line number after this node and all its children
///
/// Throws [JsonTreeException] if the data type is not supported.
(TreeViewNode<JsonTreeData>, int) _buildTreeViewNode(
  dynamic data, {
  String? key,
  int lineNumber = 1,
}) {
  return switch (data) {
    List() => _buildListNode(data, key: key, lineNumber: lineNumber),
    Map() => _buildMapNode(data, key: key, lineNumber: lineNumber),
    _ => _buildPrimitiveNode(data, key: key, lineNumber: lineNumber),
  };
}

/// Safely extracts content between matching brackets from a string.
///
/// Removes surrounding `[...]` or `{...}` brackets if present.
/// Returns the original string if brackets are missing or mismatched.
///
/// Examples:
/// ```dart
/// _getCollapsedValue("[1, 2, 3]")  // → "1, 2, 3"
/// _getCollapsedValue("{a: b}")     // → "a: b"
/// _getCollapsedValue("[]")         // → ""
/// _getCollapsedValue("invalid")    // → "invalid"
/// ```
String _getCollapsedValue(String str) {
  // Handle empty or very short strings
  if (str.length < 2) return str;

  // Check for matching brackets
  final hasMatchingBrackets =
      (str.startsWith('[') && str.endsWith(']')) ||
      (str.startsWith('{') && str.endsWith('}'));

  if (hasMatchingBrackets) {
    return str.substring(1, str.length - 1);
  }

  // Fallback: return as-is if no matching brackets
  return str;
}

/// Builds a tree node for a JSON array.
///
/// Creates a [ListTreeData] node with child nodes for each array element.
/// Array indices are used as keys in the format `"[0]"`, `"[1]"`, etc.
///
/// If the array is not empty, a closing bracket node `"]"` is added as
/// the last child.
///
/// Parameters:
/// - [data]: The List to convert
/// - [key]: Optional key for this array node
/// - [lineNumber]: The line number for this array's opening bracket
///
/// Returns a record with the node and next available line number.
(TreeViewNode<JsonTreeData>, int) _buildListNode(
  List data, {
  String? key,
  required int lineNumber,
}) {
  final (children, nextLineNumber) = _buildChildrenNodes(
    data.asMap().entries,
    startLineNumber: lineNumber + 1,
    keyBuilder: (index, _) => "[$index]",
  );

  if (children.isNotEmpty) {
    children.add(_createClosingBracketNode(nextLineNumber, "]"));
  }

  final collapsedValue = _getCollapsedValue(data.toString());
  return (
    TreeViewNode(
      ListTreeData(
        lineNumber: lineNumber,
        collapsedValue: collapsedValue,
        itemCount: data.length,
        key: key,
      ),
      children: children,
    ),
    nextLineNumber + 1,
  );
}

/// Builds a tree node for a JSON object.
///
/// Creates a [MapTreeData] node with child nodes for each object property.
/// Property names are JSON-encoded to ensure proper escaping.
///
/// If the object is not empty, a closing bracket node `"}"` is added as
/// the last child.
///
/// Parameters:
/// - [data]: The Map to convert
/// - [key]: Optional key for this object node
/// - [lineNumber]: The line number for this object's opening bracket
///
/// Returns a record with the node and next available line number.
(TreeViewNode<JsonTreeData>, int) _buildMapNode(
  Map data, {
  String? key,
  required int lineNumber,
}) {
  final (children, nextLineNumber) = _buildChildrenNodes(
    data.entries.toList().asMap().entries,
    startLineNumber: lineNumber + 1,
    keyBuilder: (_, entry) => jsonEncode(entry.key),
  );

  if (children.isNotEmpty) {
    children.add(_createClosingBracketNode(nextLineNumber, "}"));
  }

  final collapsedValue = _getCollapsedValue(data.toString());
  return (
    TreeViewNode(
      MapTreeData(
        lineNumber: lineNumber,
        collapsedValue: collapsedValue,
        itemCount: data.length,
        key: key,
      ),
      children: children,
    ),
    nextLineNumber + 1,
  );
}

/// Recursively builds child nodes for a collection (array or object).
///
/// This is a generic helper that processes a collection's entries and
/// converts each value into a tree node. It tracks line numbers across
/// all children to ensure proper sequential numbering.
///
/// The [keyBuilder] function is used to generate appropriate keys for
/// each child based on whether it's an array index or object property.
///
/// Parameters:
/// - [entries]: The collection entries to process
/// - [startLineNumber]: The line number to start from
/// - [keyBuilder]: Function to generate a key for each entry
///
/// Returns a record with:
/// - List of child [TreeViewNode]s
/// - The next available line number after all children
(List<TreeViewNode<JsonTreeData>>, int) _buildChildrenNodes<T>(
  Iterable<MapEntry<int, T>> entries, {
  required int startLineNumber,
  required String Function(int index, T entry) keyBuilder,
}) {
  final children = <TreeViewNode<JsonTreeData>>[];
  int currentLineNumber = startLineNumber;

  for (final entry in entries) {
    final value = entry.value is MapEntry
        ? (entry.value as MapEntry).value
        : entry.value;
    final key = keyBuilder(entry.key, entry.value);

    final (node, nextLine) = _buildTreeViewNode(
      value,
      key: key,
      lineNumber: currentLineNumber,
    );
    children.add(node);
    currentLineNumber = nextLine;
  }

  return (children, currentLineNumber);
}

/// Builds a tree node for a JSON primitive value.
///
/// Creates either a [PrimitiveTreeData] or [StringPrimitiveTreeData] node
/// depending on the value type. String values receive special formatting
/// to highlight escape sequences.
///
/// Supported types:
/// - String → Creates [StringPrimitiveTreeData] with special char highlighting
/// - num (int, double) → Creates [PrimitiveTreeData] with type [PrimitiveType.number]
/// - bool → Creates [PrimitiveTreeData] with type [PrimitiveType.boolean]
/// - null → Creates [PrimitiveTreeData] with type [PrimitiveType.nullValue]
///
/// Parameters:
/// - [data]: The primitive value to convert
/// - [key]: The key for this value (property name or array index)
/// - [lineNumber]: The line number for this value
///
/// Returns a record with the node and next available line number.
///
/// Throws [JsonTreeException] if the data type is not supported.
(TreeViewNode<JsonTreeData>, int) _buildPrimitiveNode(
  dynamic data, {
  required String? key,
  required int lineNumber,
}) {
  final (primitiveType, primitiveValue) = _parsePrimitiveValue(data);

  TreeViewNode<JsonTreeData> primitiveTreeNode;

  if (primitiveType == PrimitiveType.string) {
    primitiveTreeNode = _buildFormattedStringNode(
      primitiveValue,
      key: key,
      lineNumber: lineNumber,
    );
  } else {
    primitiveTreeNode = TreeViewNode(
      PrimitiveTreeData(
        lineNumber: lineNumber,
        primitiveType: primitiveType,
        key: key,
        value: primitiveValue,
      ),
    );
  }

  return (primitiveTreeNode, lineNumber + 1);
}

/// Builds a formatted string node with special character highlighting.
///
/// This function parses a JSON-encoded string and identifies escape sequences
/// (like `\n`, `\t`, `\"`, `\\`, `\uXXXX`, etc.) to enable syntax highlighting
/// in the UI. The string is broken down into segments of plain text and
/// special escape sequences.
///
/// Recognized escape sequences:
/// - `\"` - Quote
/// - `\\` - Backslash
/// - `\/` - Forward slash
/// - `\b` - Backspace
/// - `\f` - Form feed
/// - `\n` - Newline
/// - `\r` - Carriage return
/// - `\t` - Tab
/// - `\uXXXX` - Unicode escape (4 hex digits)
///
/// Parameters:
/// - [data]: The JSON-encoded string (including surrounding quotes)
/// - [key]: The key for this string value
/// - [lineNumber]: The line number for this value
///
/// Returns a [TreeViewNode] with [StringPrimitiveTreeData].
TreeViewNode<JsonTreeData> _buildFormattedStringNode(
  String data, {
  required String? key,
  required int lineNumber,
}) {
  List<(String, StringCharType)> children = [];
  final matches = _jsonEscapeSequencePattern.allMatches(data);

  if (matches.isEmpty) {
    children.add((data, StringCharType.plain));
  } else {
    int cur = 0;
    for (final match in matches) {
      if (cur != match.start) {
        children.add((data.substring(cur, match.start), StringCharType.plain));
      }
      children.add((
        data.substring(match.start, match.end),
        StringCharType.special,
      ));
      cur = match.end;
    }

    // Add remaining text after last match
    if (cur < data.length) {
      children.add((data.substring(cur), StringCharType.plain));
    }
  }

  return TreeViewNode(
    StringPrimitiveTreeData(
      lineNumber: lineNumber,
      primitiveType: PrimitiveType.string,
      key: key,
      value: data,
      formattedValue: children,
    ),
  );
}

/// Parses a primitive value and returns its type and string representation.
///
/// This function identifies the type of a JSON primitive and converts it
/// to a string representation suitable for display.
///
/// Type conversions:
/// - String → JSON-encoded with quotes (via `jsonEncode`)
/// - num (int, double) → String representation (via `toString()`)
/// - bool → `"true"` or `"false"`
/// - null → `"null"`
///
/// Parameters:
/// - [data]: The primitive value to parse
///
/// Returns a record containing:
/// - The [PrimitiveType] enum value
/// - The string representation of the value
///
/// Throws [JsonTreeException] if the data type is not a supported primitive.
///
/// Example:
/// ```dart
/// _parsePrimitiveValue("hello") // → (PrimitiveType.string, '"hello"')
/// _parsePrimitiveValue(42)      // → (PrimitiveType.number, '42')
/// _parsePrimitiveValue(true)    // → (PrimitiveType.boolean, 'true')
/// _parsePrimitiveValue(null)    // → (PrimitiveType.nullValue, 'null')
/// ```
(PrimitiveType, String) _parsePrimitiveValue(dynamic data) {
  return switch (data) {
    String() => (PrimitiveType.string, jsonEncode(data)),
    bool() => (PrimitiveType.boolean, data.toString()),
    num() => (PrimitiveType.number, data.toString()),
    null => (PrimitiveType.nullValue, "null"),
    _ => throw JsonTreeException(
      'Unsupported data type: ${data.runtimeType}. '
      'Only String, num, bool, null, List, and Map are supported.',
    ),
  };
}

/// Creates a closing bracket node for arrays or objects.
///
/// This is a helper function that creates a [BracketTreeData] node
/// representing a closing bracket (`]` for arrays or `}` for objects).
///
/// These nodes are added as the last child of their parent container
/// to display the proper JSON syntax in the tree view.
///
/// Parameters:
/// - [lineNumber]: The line number where the bracket appears
/// - [bracket]: The bracket character (`"]"` or `"}"`)
///
/// Returns a [TreeViewNode] with [BracketTreeData].
TreeViewNode<JsonTreeData> _createClosingBracketNode(
  int lineNumber,
  String bracket,
) {
  return TreeViewNode(BracketTreeData(lineNumber: lineNumber, value: bracket));
}
