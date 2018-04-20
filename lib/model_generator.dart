import './helpers.dart';
import './syntax.dart';

class ModelGenerator {
  final String _rootClassName;
  List<ClassDefinition> allClasses = new List<ClassDefinition>();
  
  ModelGenerator(this._rootClassName);
  
  _generateClassDefinition(String className, Map<String, dynamic> jsonRawData) {
    if (jsonRawData is List) {
      // if first element is an array, start in the first element.
      _generateClassDefinition(className, jsonRawData[0]);
    } else {
      final keys = jsonRawData.keys;
      ClassDefinition classDefinition = new ClassDefinition(className);
      keys.forEach((key) {
        final typeDef = new TypeDefinition.fromDynamic(jsonRawData[key]);
        if (typeDef.name.contains('Class')) {
          typeDef.name = camelCase(key);
        }
        if (typeDef.subtype != null && typeDef.subtype.contains('Class')) {
          typeDef.subtype = camelCase(key);
        }
        classDefinition.addField(key, typeDef);
      });
      if (allClasses.firstWhere((cd) => cd == classDefinition, orElse: () => null) == null) {
        allClasses.add(classDefinition);
      }
      final dependencies = classDefinition.dependencies;
      dependencies.forEach((dependency) {
        if (dependency.typeDef.name == 'List') {
          _generateClassDefinition(dependency.className, jsonRawData[dependency.name][0]);
        } else {
          _generateClassDefinition(dependency.className, jsonRawData[dependency.name]);
        }
      });
    }
  }

  /// generateDartClasses will generate all classes and append one after another
  /// in a single string. The [rawJson] param is assumed to be a properly
  /// formatted JSON string.
  String generateDartClasses(String rawJson) {
    final Map<String, dynamic> jsonRawData = decodeJSON(rawJson);
    _generateClassDefinition(_rootClassName, jsonRawData);
    return allClasses.map((c) => c.toString()).join('\n');
  }
}