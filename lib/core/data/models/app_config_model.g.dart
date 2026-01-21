// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_config_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetAppConfigModelCollection on Isar {
  IsarCollection<AppConfigModel> get appConfigModels => this.collection();
}

const AppConfigModelSchema = CollectionSchema(
  name: r'AppConfigModel',
  id: 2740606792074487479,
  properties: {
    r'aiModelPath': PropertySchema(
      id: 0,
      name: r'aiModelPath',
      type: IsarType.string,
    ),
    r'highPerformanceMode': PropertySchema(
      id: 1,
      name: r'highPerformanceMode',
      type: IsarType.bool,
    )
  },
  estimateSize: _appConfigModelEstimateSize,
  serialize: _appConfigModelSerialize,
  deserialize: _appConfigModelDeserialize,
  deserializeProp: _appConfigModelDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _appConfigModelGetId,
  getLinks: _appConfigModelGetLinks,
  attach: _appConfigModelAttach,
  version: '3.1.0+1',
);

int _appConfigModelEstimateSize(
  AppConfigModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.aiModelPath;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _appConfigModelSerialize(
  AppConfigModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.aiModelPath);
  writer.writeBool(offsets[1], object.highPerformanceMode);
}

AppConfigModel _appConfigModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = AppConfigModel();
  object.aiModelPath = reader.readStringOrNull(offsets[0]);
  object.highPerformanceMode = reader.readBool(offsets[1]);
  object.id = id;
  return object;
}

P _appConfigModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readBool(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _appConfigModelGetId(AppConfigModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _appConfigModelGetLinks(AppConfigModel object) {
  return [];
}

void _appConfigModelAttach(
    IsarCollection<dynamic> col, Id id, AppConfigModel object) {
  object.id = id;
}

extension AppConfigModelQueryWhereSort
    on QueryBuilder<AppConfigModel, AppConfigModel, QWhere> {
  QueryBuilder<AppConfigModel, AppConfigModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension AppConfigModelQueryWhere
    on QueryBuilder<AppConfigModel, AppConfigModel, QWhereClause> {
  QueryBuilder<AppConfigModel, AppConfigModel, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<AppConfigModel, AppConfigModel, QAfterWhereClause> idNotEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<AppConfigModel, AppConfigModel, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<AppConfigModel, AppConfigModel, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<AppConfigModel, AppConfigModel, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension AppConfigModelQueryFilter
    on QueryBuilder<AppConfigModel, AppConfigModel, QFilterCondition> {
  QueryBuilder<AppConfigModel, AppConfigModel, QAfterFilterCondition>
      aiModelPathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'aiModelPath',
      ));
    });
  }

  QueryBuilder<AppConfigModel, AppConfigModel, QAfterFilterCondition>
      aiModelPathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'aiModelPath',
      ));
    });
  }

  QueryBuilder<AppConfigModel, AppConfigModel, QAfterFilterCondition>
      aiModelPathEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'aiModelPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppConfigModel, AppConfigModel, QAfterFilterCondition>
      aiModelPathGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'aiModelPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppConfigModel, AppConfigModel, QAfterFilterCondition>
      aiModelPathLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'aiModelPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppConfigModel, AppConfigModel, QAfterFilterCondition>
      aiModelPathBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'aiModelPath',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppConfigModel, AppConfigModel, QAfterFilterCondition>
      aiModelPathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'aiModelPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppConfigModel, AppConfigModel, QAfterFilterCondition>
      aiModelPathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'aiModelPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppConfigModel, AppConfigModel, QAfterFilterCondition>
      aiModelPathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'aiModelPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppConfigModel, AppConfigModel, QAfterFilterCondition>
      aiModelPathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'aiModelPath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppConfigModel, AppConfigModel, QAfterFilterCondition>
      aiModelPathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'aiModelPath',
        value: '',
      ));
    });
  }

  QueryBuilder<AppConfigModel, AppConfigModel, QAfterFilterCondition>
      aiModelPathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'aiModelPath',
        value: '',
      ));
    });
  }

  QueryBuilder<AppConfigModel, AppConfigModel, QAfterFilterCondition>
      highPerformanceModeEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'highPerformanceMode',
        value: value,
      ));
    });
  }

  QueryBuilder<AppConfigModel, AppConfigModel, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<AppConfigModel, AppConfigModel, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<AppConfigModel, AppConfigModel, QAfterFilterCondition>
      idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<AppConfigModel, AppConfigModel, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension AppConfigModelQueryObject
    on QueryBuilder<AppConfigModel, AppConfigModel, QFilterCondition> {}

extension AppConfigModelQueryLinks
    on QueryBuilder<AppConfigModel, AppConfigModel, QFilterCondition> {}

extension AppConfigModelQuerySortBy
    on QueryBuilder<AppConfigModel, AppConfigModel, QSortBy> {
  QueryBuilder<AppConfigModel, AppConfigModel, QAfterSortBy>
      sortByAiModelPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aiModelPath', Sort.asc);
    });
  }

  QueryBuilder<AppConfigModel, AppConfigModel, QAfterSortBy>
      sortByAiModelPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aiModelPath', Sort.desc);
    });
  }

  QueryBuilder<AppConfigModel, AppConfigModel, QAfterSortBy>
      sortByHighPerformanceMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'highPerformanceMode', Sort.asc);
    });
  }

  QueryBuilder<AppConfigModel, AppConfigModel, QAfterSortBy>
      sortByHighPerformanceModeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'highPerformanceMode', Sort.desc);
    });
  }
}

extension AppConfigModelQuerySortThenBy
    on QueryBuilder<AppConfigModel, AppConfigModel, QSortThenBy> {
  QueryBuilder<AppConfigModel, AppConfigModel, QAfterSortBy>
      thenByAiModelPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aiModelPath', Sort.asc);
    });
  }

  QueryBuilder<AppConfigModel, AppConfigModel, QAfterSortBy>
      thenByAiModelPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aiModelPath', Sort.desc);
    });
  }

  QueryBuilder<AppConfigModel, AppConfigModel, QAfterSortBy>
      thenByHighPerformanceMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'highPerformanceMode', Sort.asc);
    });
  }

  QueryBuilder<AppConfigModel, AppConfigModel, QAfterSortBy>
      thenByHighPerformanceModeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'highPerformanceMode', Sort.desc);
    });
  }

  QueryBuilder<AppConfigModel, AppConfigModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<AppConfigModel, AppConfigModel, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }
}

extension AppConfigModelQueryWhereDistinct
    on QueryBuilder<AppConfigModel, AppConfigModel, QDistinct> {
  QueryBuilder<AppConfigModel, AppConfigModel, QDistinct> distinctByAiModelPath(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'aiModelPath', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AppConfigModel, AppConfigModel, QDistinct>
      distinctByHighPerformanceMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'highPerformanceMode');
    });
  }
}

extension AppConfigModelQueryProperty
    on QueryBuilder<AppConfigModel, AppConfigModel, QQueryProperty> {
  QueryBuilder<AppConfigModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<AppConfigModel, String?, QQueryOperations>
      aiModelPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'aiModelPath');
    });
  }

  QueryBuilder<AppConfigModel, bool, QQueryOperations>
      highPerformanceModeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'highPerformanceMode');
    });
  }
}
