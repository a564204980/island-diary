// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'furniture_item.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetFurnitureItemCollection on Isar {
  IsarCollection<FurnitureItem> get furnitureItems => this.collection();
}

const FurnitureItemSchema = CollectionSchema(
  name: r'FurnitureItem',
  id: -8690404940351508416,
  properties: {
    r'canBeDyed': PropertySchema(
      id: 0,
      name: r'canBeDyed',
      type: IsarType.bool,
    ),
    r'category': PropertySchema(
      id: 1,
      name: r'category',
      type: IsarType.string,
    ),
    r'colorVariants': PropertySchema(
      id: 2,
      name: r'colorVariants',
      type: IsarType.objectList,
      target: r'FurnitureColorVariant',
    ),
    r'flippedVisualRotationX': PropertySchema(
      id: 3,
      name: r'flippedVisualRotationX',
      type: IsarType.double,
    ),
    r'flippedVisualRotationY': PropertySchema(
      id: 4,
      name: r'flippedVisualRotationY',
      type: IsarType.double,
    ),
    r'flippedVisualRotationZ': PropertySchema(
      id: 5,
      name: r'flippedVisualRotationZ',
      type: IsarType.double,
    ),
    r'flippedVisualScale': PropertySchema(
      id: 6,
      name: r'flippedVisualScale',
      type: IsarType.double,
    ),
    r'fvOffsetX': PropertySchema(
      id: 7,
      name: r'fvOffsetX',
      type: IsarType.double,
    ),
    r'fvOffsetY': PropertySchema(
      id: 8,
      name: r'fvOffsetY',
      type: IsarType.double,
    ),
    r'fvPivotX': PropertySchema(
      id: 9,
      name: r'fvPivotX',
      type: IsarType.double,
    ),
    r'fvPivotY': PropertySchema(
      id: 10,
      name: r'fvPivotY',
      type: IsarType.double,
    ),
    r'gridH': PropertySchema(
      id: 11,
      name: r'gridH',
      type: IsarType.long,
    ),
    r'gridW': PropertySchema(
      id: 12,
      name: r'gridW',
      type: IsarType.long,
    ),
    r'id': PropertySchema(
      id: 13,
      name: r'id',
      type: IsarType.string,
    ),
    r'imagePath': PropertySchema(
      id: 14,
      name: r'imagePath',
      type: IsarType.string,
    ),
    r'intrinsicHeight': PropertySchema(
      id: 15,
      name: r'intrinsicHeight',
      type: IsarType.double,
    ),
    r'intrinsicWidth': PropertySchema(
      id: 16,
      name: r'intrinsicWidth',
      type: IsarType.double,
    ),
    r'name': PropertySchema(
      id: 17,
      name: r'name',
      type: IsarType.string,
    ),
    r'quantity': PropertySchema(
      id: 18,
      name: r'quantity',
      type: IsarType.long,
    ),
    r'rectHeight': PropertySchema(
      id: 19,
      name: r'rectHeight',
      type: IsarType.double,
    ),
    r'rectLeft': PropertySchema(
      id: 20,
      name: r'rectLeft',
      type: IsarType.double,
    ),
    r'rectTop': PropertySchema(
      id: 21,
      name: r'rectTop',
      type: IsarType.double,
    ),
    r'rectWidth': PropertySchema(
      id: 22,
      name: r'rectWidth',
      type: IsarType.double,
    ),
    r'subCategory': PropertySchema(
      id: 23,
      name: r'subCategory',
      type: IsarType.string,
    ),
    r'tbOffsetX': PropertySchema(
      id: 24,
      name: r'tbOffsetX',
      type: IsarType.double,
    ),
    r'tbOffsetY': PropertySchema(
      id: 25,
      name: r'tbOffsetY',
      type: IsarType.double,
    ),
    r'vOffsetX': PropertySchema(
      id: 26,
      name: r'vOffsetX',
      type: IsarType.double,
    ),
    r'vOffsetY': PropertySchema(
      id: 27,
      name: r'vOffsetY',
      type: IsarType.double,
    ),
    r'vPivotX': PropertySchema(
      id: 28,
      name: r'vPivotX',
      type: IsarType.double,
    ),
    r'vPivotY': PropertySchema(
      id: 29,
      name: r'vPivotY',
      type: IsarType.double,
    ),
    r'visualRotationX': PropertySchema(
      id: 30,
      name: r'visualRotationX',
      type: IsarType.double,
    ),
    r'visualRotationY': PropertySchema(
      id: 31,
      name: r'visualRotationY',
      type: IsarType.double,
    ),
    r'visualRotationZ': PropertySchema(
      id: 32,
      name: r'visualRotationZ',
      type: IsarType.double,
    ),
    r'visualScale': PropertySchema(
      id: 33,
      name: r'visualScale',
      type: IsarType.double,
    )
  },
  estimateSize: _furnitureItemEstimateSize,
  serialize: _furnitureItemSerialize,
  deserialize: _furnitureItemDeserialize,
  deserializeProp: _furnitureItemDeserializeProp,
  idName: r'isarId',
  indexes: {
    r'id': IndexSchema(
      id: -3268401673993471357,
      name: r'id',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'id',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {r'FurnitureColorVariant': FurnitureColorVariantSchema},
  getId: _furnitureItemGetId,
  getLinks: _furnitureItemGetLinks,
  attach: _furnitureItemAttach,
  version: '3.1.0+1',
);

int _furnitureItemEstimateSize(
  FurnitureItem object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.category.length * 3;
  bytesCount += 3 + object.colorVariants.length * 3;
  {
    final offsets = allOffsets[FurnitureColorVariant]!;
    for (var i = 0; i < object.colorVariants.length; i++) {
      final value = object.colorVariants[i];
      bytesCount +=
          FurnitureColorVariantSchema.estimateSize(value, offsets, allOffsets);
    }
  }
  bytesCount += 3 + object.id.length * 3;
  bytesCount += 3 + object.imagePath.length * 3;
  bytesCount += 3 + object.name.length * 3;
  bytesCount += 3 + object.subCategory.length * 3;
  return bytesCount;
}

void _furnitureItemSerialize(
  FurnitureItem object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.canBeDyed);
  writer.writeString(offsets[1], object.category);
  writer.writeObjectList<FurnitureColorVariant>(
    offsets[2],
    allOffsets,
    FurnitureColorVariantSchema.serialize,
    object.colorVariants,
  );
  writer.writeDouble(offsets[3], object.flippedVisualRotationX);
  writer.writeDouble(offsets[4], object.flippedVisualRotationY);
  writer.writeDouble(offsets[5], object.flippedVisualRotationZ);
  writer.writeDouble(offsets[6], object.flippedVisualScale);
  writer.writeDouble(offsets[7], object.fvOffsetX);
  writer.writeDouble(offsets[8], object.fvOffsetY);
  writer.writeDouble(offsets[9], object.fvPivotX);
  writer.writeDouble(offsets[10], object.fvPivotY);
  writer.writeLong(offsets[11], object.gridH);
  writer.writeLong(offsets[12], object.gridW);
  writer.writeString(offsets[13], object.id);
  writer.writeString(offsets[14], object.imagePath);
  writer.writeDouble(offsets[15], object.intrinsicHeight);
  writer.writeDouble(offsets[16], object.intrinsicWidth);
  writer.writeString(offsets[17], object.name);
  writer.writeLong(offsets[18], object.quantity);
  writer.writeDouble(offsets[19], object.rectHeight);
  writer.writeDouble(offsets[20], object.rectLeft);
  writer.writeDouble(offsets[21], object.rectTop);
  writer.writeDouble(offsets[22], object.rectWidth);
  writer.writeString(offsets[23], object.subCategory);
  writer.writeDouble(offsets[24], object.tbOffsetX);
  writer.writeDouble(offsets[25], object.tbOffsetY);
  writer.writeDouble(offsets[26], object.vOffsetX);
  writer.writeDouble(offsets[27], object.vOffsetY);
  writer.writeDouble(offsets[28], object.vPivotX);
  writer.writeDouble(offsets[29], object.vPivotY);
  writer.writeDouble(offsets[30], object.visualRotationX);
  writer.writeDouble(offsets[31], object.visualRotationY);
  writer.writeDouble(offsets[32], object.visualRotationZ);
  writer.writeDouble(offsets[33], object.visualScale);
}

FurnitureItem _furnitureItemDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = FurnitureItem(
    canBeDyed: reader.readBoolOrNull(offsets[0]) ?? false,
    category: reader.readStringOrNull(offsets[1]) ?? '',
    colorVariants: reader.readObjectList<FurnitureColorVariant>(
          offsets[2],
          FurnitureColorVariantSchema.deserialize,
          allOffsets,
          FurnitureColorVariant(),
        ) ??
        const [],
    flippedVisualRotationX: reader.readDoubleOrNull(offsets[3]),
    flippedVisualRotationY: reader.readDoubleOrNull(offsets[4]),
    flippedVisualRotationZ: reader.readDoubleOrNull(offsets[5]),
    flippedVisualScale: reader.readDoubleOrNull(offsets[6]),
    fvOffsetX: reader.readDoubleOrNull(offsets[7]),
    fvOffsetY: reader.readDoubleOrNull(offsets[8]),
    fvPivotX: reader.readDoubleOrNull(offsets[9]),
    fvPivotY: reader.readDoubleOrNull(offsets[10]),
    gridH: reader.readLongOrNull(offsets[11]) ?? 1,
    gridW: reader.readLongOrNull(offsets[12]) ?? 1,
    id: reader.readStringOrNull(offsets[13]) ?? '',
    imagePath: reader.readStringOrNull(offsets[14]) ?? '',
    intrinsicHeight: reader.readDoubleOrNull(offsets[15]) ?? 1,
    intrinsicWidth: reader.readDoubleOrNull(offsets[16]) ?? 1,
    name: reader.readStringOrNull(offsets[17]) ?? '',
    quantity: reader.readLongOrNull(offsets[18]) ?? 3,
    rectHeight: reader.readDoubleOrNull(offsets[19]) ?? 1,
    rectLeft: reader.readDoubleOrNull(offsets[20]) ?? 0,
    rectTop: reader.readDoubleOrNull(offsets[21]) ?? 0,
    rectWidth: reader.readDoubleOrNull(offsets[22]) ?? 1,
    subCategory: reader.readStringOrNull(offsets[23]) ?? '',
    tbOffsetX: reader.readDoubleOrNull(offsets[24]) ?? 0,
    tbOffsetY: reader.readDoubleOrNull(offsets[25]) ?? 0,
    vOffsetX: reader.readDoubleOrNull(offsets[26]) ?? 0,
    vOffsetY: reader.readDoubleOrNull(offsets[27]) ?? 0,
    vPivotX: reader.readDoubleOrNull(offsets[28]) ?? 0,
    vPivotY: reader.readDoubleOrNull(offsets[29]) ?? 0,
    visualRotationX: reader.readDoubleOrNull(offsets[30]) ?? 0,
    visualRotationY: reader.readDoubleOrNull(offsets[31]) ?? 0,
    visualRotationZ: reader.readDoubleOrNull(offsets[32]) ?? 0,
    visualScale: reader.readDoubleOrNull(offsets[33]) ?? 1.0,
  );
  object.isarId = id;
  return object;
}

P _furnitureItemDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 1:
      return (reader.readStringOrNull(offset) ?? '') as P;
    case 2:
      return (reader.readObjectList<FurnitureColorVariant>(
            offset,
            FurnitureColorVariantSchema.deserialize,
            allOffsets,
            FurnitureColorVariant(),
          ) ??
          const []) as P;
    case 3:
      return (reader.readDoubleOrNull(offset)) as P;
    case 4:
      return (reader.readDoubleOrNull(offset)) as P;
    case 5:
      return (reader.readDoubleOrNull(offset)) as P;
    case 6:
      return (reader.readDoubleOrNull(offset)) as P;
    case 7:
      return (reader.readDoubleOrNull(offset)) as P;
    case 8:
      return (reader.readDoubleOrNull(offset)) as P;
    case 9:
      return (reader.readDoubleOrNull(offset)) as P;
    case 10:
      return (reader.readDoubleOrNull(offset)) as P;
    case 11:
      return (reader.readLongOrNull(offset) ?? 1) as P;
    case 12:
      return (reader.readLongOrNull(offset) ?? 1) as P;
    case 13:
      return (reader.readStringOrNull(offset) ?? '') as P;
    case 14:
      return (reader.readStringOrNull(offset) ?? '') as P;
    case 15:
      return (reader.readDoubleOrNull(offset) ?? 1) as P;
    case 16:
      return (reader.readDoubleOrNull(offset) ?? 1) as P;
    case 17:
      return (reader.readStringOrNull(offset) ?? '') as P;
    case 18:
      return (reader.readLongOrNull(offset) ?? 3) as P;
    case 19:
      return (reader.readDoubleOrNull(offset) ?? 1) as P;
    case 20:
      return (reader.readDoubleOrNull(offset) ?? 0) as P;
    case 21:
      return (reader.readDoubleOrNull(offset) ?? 0) as P;
    case 22:
      return (reader.readDoubleOrNull(offset) ?? 1) as P;
    case 23:
      return (reader.readStringOrNull(offset) ?? '') as P;
    case 24:
      return (reader.readDoubleOrNull(offset) ?? 0) as P;
    case 25:
      return (reader.readDoubleOrNull(offset) ?? 0) as P;
    case 26:
      return (reader.readDoubleOrNull(offset) ?? 0) as P;
    case 27:
      return (reader.readDoubleOrNull(offset) ?? 0) as P;
    case 28:
      return (reader.readDoubleOrNull(offset) ?? 0) as P;
    case 29:
      return (reader.readDoubleOrNull(offset) ?? 0) as P;
    case 30:
      return (reader.readDoubleOrNull(offset) ?? 0) as P;
    case 31:
      return (reader.readDoubleOrNull(offset) ?? 0) as P;
    case 32:
      return (reader.readDoubleOrNull(offset) ?? 0) as P;
    case 33:
      return (reader.readDoubleOrNull(offset) ?? 1.0) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _furnitureItemGetId(FurnitureItem object) {
  return object.isarId;
}

List<IsarLinkBase<dynamic>> _furnitureItemGetLinks(FurnitureItem object) {
  return [];
}

void _furnitureItemAttach(
    IsarCollection<dynamic> col, Id id, FurnitureItem object) {
  object.isarId = id;
}

extension FurnitureItemByIndex on IsarCollection<FurnitureItem> {
  Future<FurnitureItem?> getById(String id) {
    return getByIndex(r'id', [id]);
  }

  FurnitureItem? getByIdSync(String id) {
    return getByIndexSync(r'id', [id]);
  }

  Future<bool> deleteById(String id) {
    return deleteByIndex(r'id', [id]);
  }

  bool deleteByIdSync(String id) {
    return deleteByIndexSync(r'id', [id]);
  }

  Future<List<FurnitureItem?>> getAllById(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return getAllByIndex(r'id', values);
  }

  List<FurnitureItem?> getAllByIdSync(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'id', values);
  }

  Future<int> deleteAllById(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'id', values);
  }

  int deleteAllByIdSync(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'id', values);
  }

  Future<Id> putById(FurnitureItem object) {
    return putByIndex(r'id', object);
  }

  Id putByIdSync(FurnitureItem object, {bool saveLinks = true}) {
    return putByIndexSync(r'id', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllById(List<FurnitureItem> objects) {
    return putAllByIndex(r'id', objects);
  }

  List<Id> putAllByIdSync(List<FurnitureItem> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'id', objects, saveLinks: saveLinks);
  }
}

extension FurnitureItemQueryWhereSort
    on QueryBuilder<FurnitureItem, FurnitureItem, QWhere> {
  QueryBuilder<FurnitureItem, FurnitureItem, QAfterWhere> anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension FurnitureItemQueryWhere
    on QueryBuilder<FurnitureItem, FurnitureItem, QWhereClause> {
  QueryBuilder<FurnitureItem, FurnitureItem, QAfterWhereClause> isarIdEqualTo(
      Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: isarId,
        upper: isarId,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterWhereClause>
      isarIdNotEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterWhereClause>
      isarIdGreaterThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterWhereClause> isarIdLessThan(
      Id isarId,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterWhereClause> isarIdBetween(
    Id lowerIsarId,
    Id upperIsarId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerIsarId,
        includeLower: includeLower,
        upper: upperIsarId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterWhereClause> idEqualTo(
      String id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'id',
        value: [id],
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterWhereClause> idNotEqualTo(
      String id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [],
              upper: [id],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [id],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [id],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [],
              upper: [id],
              includeUpper: false,
            ));
      }
    });
  }
}

extension FurnitureItemQueryFilter
    on QueryBuilder<FurnitureItem, FurnitureItem, QFilterCondition> {
  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      canBeDyedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'canBeDyed',
        value: value,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      categoryEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      categoryGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      categoryLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      categoryBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'category',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      categoryStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      categoryEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      categoryContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      categoryMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'category',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      categoryIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'category',
        value: '',
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      categoryIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'category',
        value: '',
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      colorVariantsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'colorVariants',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      colorVariantsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'colorVariants',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      colorVariantsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'colorVariants',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      colorVariantsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'colorVariants',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      colorVariantsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'colorVariants',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      colorVariantsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'colorVariants',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      flippedVisualRotationXIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'flippedVisualRotationX',
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      flippedVisualRotationXIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'flippedVisualRotationX',
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      flippedVisualRotationXEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'flippedVisualRotationX',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      flippedVisualRotationXGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'flippedVisualRotationX',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      flippedVisualRotationXLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'flippedVisualRotationX',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      flippedVisualRotationXBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'flippedVisualRotationX',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      flippedVisualRotationYIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'flippedVisualRotationY',
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      flippedVisualRotationYIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'flippedVisualRotationY',
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      flippedVisualRotationYEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'flippedVisualRotationY',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      flippedVisualRotationYGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'flippedVisualRotationY',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      flippedVisualRotationYLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'flippedVisualRotationY',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      flippedVisualRotationYBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'flippedVisualRotationY',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      flippedVisualRotationZIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'flippedVisualRotationZ',
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      flippedVisualRotationZIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'flippedVisualRotationZ',
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      flippedVisualRotationZEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'flippedVisualRotationZ',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      flippedVisualRotationZGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'flippedVisualRotationZ',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      flippedVisualRotationZLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'flippedVisualRotationZ',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      flippedVisualRotationZBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'flippedVisualRotationZ',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      flippedVisualScaleIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'flippedVisualScale',
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      flippedVisualScaleIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'flippedVisualScale',
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      flippedVisualScaleEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'flippedVisualScale',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      flippedVisualScaleGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'flippedVisualScale',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      flippedVisualScaleLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'flippedVisualScale',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      flippedVisualScaleBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'flippedVisualScale',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      fvOffsetXIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'fvOffsetX',
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      fvOffsetXIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'fvOffsetX',
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      fvOffsetXEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fvOffsetX',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      fvOffsetXGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fvOffsetX',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      fvOffsetXLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fvOffsetX',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      fvOffsetXBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fvOffsetX',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      fvOffsetYIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'fvOffsetY',
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      fvOffsetYIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'fvOffsetY',
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      fvOffsetYEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fvOffsetY',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      fvOffsetYGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fvOffsetY',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      fvOffsetYLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fvOffsetY',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      fvOffsetYBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fvOffsetY',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      fvPivotXIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'fvPivotX',
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      fvPivotXIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'fvPivotX',
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      fvPivotXEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fvPivotX',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      fvPivotXGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fvPivotX',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      fvPivotXLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fvPivotX',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      fvPivotXBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fvPivotX',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      fvPivotYIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'fvPivotY',
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      fvPivotYIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'fvPivotY',
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      fvPivotYEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fvPivotY',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      fvPivotYGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fvPivotY',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      fvPivotYLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fvPivotY',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      fvPivotYBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fvPivotY',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      gridHEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'gridH',
        value: value,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      gridHGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'gridH',
        value: value,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      gridHLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'gridH',
        value: value,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      gridHBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'gridH',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      gridWEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'gridW',
        value: value,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      gridWGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'gridW',
        value: value,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      gridWLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'gridW',
        value: value,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      gridWBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'gridW',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition> idEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      idGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition> idLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition> idBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      idStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition> idEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition> idContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition> idMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'id',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      idIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      idIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      imagePathEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'imagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      imagePathGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'imagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      imagePathLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'imagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      imagePathBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'imagePath',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      imagePathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'imagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      imagePathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'imagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      imagePathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'imagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      imagePathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'imagePath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      imagePathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'imagePath',
        value: '',
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      imagePathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'imagePath',
        value: '',
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      intrinsicHeightEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'intrinsicHeight',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      intrinsicHeightGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'intrinsicHeight',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      intrinsicHeightLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'intrinsicHeight',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      intrinsicHeightBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'intrinsicHeight',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      intrinsicWidthEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'intrinsicWidth',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      intrinsicWidthGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'intrinsicWidth',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      intrinsicWidthLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'intrinsicWidth',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      intrinsicWidthBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'intrinsicWidth',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      isarIdEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      isarIdGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      isarIdLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      isarIdBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'isarId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition> nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition> nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      nameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition> nameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      quantityEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'quantity',
        value: value,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      quantityGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'quantity',
        value: value,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      quantityLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'quantity',
        value: value,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      quantityBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'quantity',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      rectHeightEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rectHeight',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      rectHeightGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'rectHeight',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      rectHeightLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'rectHeight',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      rectHeightBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'rectHeight',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      rectLeftEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rectLeft',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      rectLeftGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'rectLeft',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      rectLeftLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'rectLeft',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      rectLeftBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'rectLeft',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      rectTopEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rectTop',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      rectTopGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'rectTop',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      rectTopLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'rectTop',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      rectTopBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'rectTop',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      rectWidthEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rectWidth',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      rectWidthGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'rectWidth',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      rectWidthLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'rectWidth',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      rectWidthBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'rectWidth',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      subCategoryEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'subCategory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      subCategoryGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'subCategory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      subCategoryLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'subCategory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      subCategoryBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'subCategory',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      subCategoryStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'subCategory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      subCategoryEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'subCategory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      subCategoryContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'subCategory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      subCategoryMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'subCategory',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      subCategoryIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'subCategory',
        value: '',
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      subCategoryIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'subCategory',
        value: '',
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      tbOffsetXEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tbOffsetX',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      tbOffsetXGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'tbOffsetX',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      tbOffsetXLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'tbOffsetX',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      tbOffsetXBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'tbOffsetX',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      tbOffsetYEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tbOffsetY',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      tbOffsetYGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'tbOffsetY',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      tbOffsetYLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'tbOffsetY',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      tbOffsetYBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'tbOffsetY',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      vOffsetXEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'vOffsetX',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      vOffsetXGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'vOffsetX',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      vOffsetXLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'vOffsetX',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      vOffsetXBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'vOffsetX',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      vOffsetYEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'vOffsetY',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      vOffsetYGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'vOffsetY',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      vOffsetYLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'vOffsetY',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      vOffsetYBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'vOffsetY',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      vPivotXEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'vPivotX',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      vPivotXGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'vPivotX',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      vPivotXLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'vPivotX',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      vPivotXBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'vPivotX',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      vPivotYEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'vPivotY',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      vPivotYGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'vPivotY',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      vPivotYLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'vPivotY',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      vPivotYBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'vPivotY',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      visualRotationXEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'visualRotationX',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      visualRotationXGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'visualRotationX',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      visualRotationXLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'visualRotationX',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      visualRotationXBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'visualRotationX',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      visualRotationYEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'visualRotationY',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      visualRotationYGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'visualRotationY',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      visualRotationYLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'visualRotationY',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      visualRotationYBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'visualRotationY',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      visualRotationZEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'visualRotationZ',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      visualRotationZGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'visualRotationZ',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      visualRotationZLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'visualRotationZ',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      visualRotationZBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'visualRotationZ',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      visualScaleEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'visualScale',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      visualScaleGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'visualScale',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      visualScaleLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'visualScale',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      visualScaleBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'visualScale',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }
}

extension FurnitureItemQueryObject
    on QueryBuilder<FurnitureItem, FurnitureItem, QFilterCondition> {
  QueryBuilder<FurnitureItem, FurnitureItem, QAfterFilterCondition>
      colorVariantsElement(FilterQuery<FurnitureColorVariant> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'colorVariants');
    });
  }
}

extension FurnitureItemQueryLinks
    on QueryBuilder<FurnitureItem, FurnitureItem, QFilterCondition> {}

extension FurnitureItemQuerySortBy
    on QueryBuilder<FurnitureItem, FurnitureItem, QSortBy> {
  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy> sortByCanBeDyed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'canBeDyed', Sort.asc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy>
      sortByCanBeDyedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'canBeDyed', Sort.desc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy> sortByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy>
      sortByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy>
      sortByFlippedVisualRotationX() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'flippedVisualRotationX', Sort.asc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy>
      sortByFlippedVisualRotationXDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'flippedVisualRotationX', Sort.desc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy>
      sortByFlippedVisualRotationY() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'flippedVisualRotationY', Sort.asc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy>
      sortByFlippedVisualRotationYDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'flippedVisualRotationY', Sort.desc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy>
      sortByFlippedVisualRotationZ() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'flippedVisualRotationZ', Sort.asc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy>
      sortByFlippedVisualRotationZDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'flippedVisualRotationZ', Sort.desc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy>
      sortByFlippedVisualScale() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'flippedVisualScale', Sort.asc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy>
      sortByFlippedVisualScaleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'flippedVisualScale', Sort.desc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy> sortByFvOffsetX() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fvOffsetX', Sort.asc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy>
      sortByFvOffsetXDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fvOffsetX', Sort.desc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy> sortByFvOffsetY() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fvOffsetY', Sort.asc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy>
      sortByFvOffsetYDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fvOffsetY', Sort.desc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy> sortByFvPivotX() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fvPivotX', Sort.asc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy>
      sortByFvPivotXDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fvPivotX', Sort.desc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy> sortByFvPivotY() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fvPivotY', Sort.asc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy>
      sortByFvPivotYDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fvPivotY', Sort.desc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy> sortByGridH() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gridH', Sort.asc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy> sortByGridHDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gridH', Sort.desc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy> sortByGridW() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gridW', Sort.asc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy> sortByGridWDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gridW', Sort.desc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy> sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy> sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy> sortByImagePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imagePath', Sort.asc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy>
      sortByImagePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imagePath', Sort.desc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy>
      sortByIntrinsicHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'intrinsicHeight', Sort.asc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy>
      sortByIntrinsicHeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'intrinsicHeight', Sort.desc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy>
      sortByIntrinsicWidth() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'intrinsicWidth', Sort.asc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy>
      sortByIntrinsicWidthDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'intrinsicWidth', Sort.desc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy> sortByQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantity', Sort.asc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy>
      sortByQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantity', Sort.desc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy> sortByRectHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rectHeight', Sort.asc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy>
      sortByRectHeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rectHeight', Sort.desc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy> sortByRectLeft() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rectLeft', Sort.asc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy>
      sortByRectLeftDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rectLeft', Sort.desc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy> sortByRectTop() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rectTop', Sort.asc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy> sortByRectTopDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rectTop', Sort.desc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy> sortByRectWidth() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rectWidth', Sort.asc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy>
      sortByRectWidthDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rectWidth', Sort.desc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy> sortBySubCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subCategory', Sort.asc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy>
      sortBySubCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subCategory', Sort.desc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy> sortByTbOffsetX() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tbOffsetX', Sort.asc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy>
      sortByTbOffsetXDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tbOffsetX', Sort.desc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy> sortByTbOffsetY() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tbOffsetY', Sort.asc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy>
      sortByTbOffsetYDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tbOffsetY', Sort.desc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy> sortByVOffsetX() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vOffsetX', Sort.asc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy>
      sortByVOffsetXDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vOffsetX', Sort.desc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy> sortByVOffsetY() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vOffsetY', Sort.asc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy>
      sortByVOffsetYDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vOffsetY', Sort.desc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy> sortByVPivotX() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vPivotX', Sort.asc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy> sortByVPivotXDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vPivotX', Sort.desc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy> sortByVPivotY() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vPivotY', Sort.asc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy> sortByVPivotYDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vPivotY', Sort.desc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy>
      sortByVisualRotationX() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'visualRotationX', Sort.asc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy>
      sortByVisualRotationXDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'visualRotationX', Sort.desc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy>
      sortByVisualRotationY() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'visualRotationY', Sort.asc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy>
      sortByVisualRotationYDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'visualRotationY', Sort.desc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy>
      sortByVisualRotationZ() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'visualRotationZ', Sort.asc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy>
      sortByVisualRotationZDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'visualRotationZ', Sort.desc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy> sortByVisualScale() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'visualScale', Sort.asc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy>
      sortByVisualScaleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'visualScale', Sort.desc);
    });
  }
}

extension FurnitureItemQuerySortThenBy
    on QueryBuilder<FurnitureItem, FurnitureItem, QSortThenBy> {
  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy> thenByCanBeDyed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'canBeDyed', Sort.asc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy>
      thenByCanBeDyedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'canBeDyed', Sort.desc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy> thenByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy>
      thenByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy>
      thenByFlippedVisualRotationX() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'flippedVisualRotationX', Sort.asc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy>
      thenByFlippedVisualRotationXDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'flippedVisualRotationX', Sort.desc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy>
      thenByFlippedVisualRotationY() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'flippedVisualRotationY', Sort.asc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy>
      thenByFlippedVisualRotationYDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'flippedVisualRotationY', Sort.desc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy>
      thenByFlippedVisualRotationZ() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'flippedVisualRotationZ', Sort.asc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy>
      thenByFlippedVisualRotationZDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'flippedVisualRotationZ', Sort.desc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy>
      thenByFlippedVisualScale() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'flippedVisualScale', Sort.asc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy>
      thenByFlippedVisualScaleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'flippedVisualScale', Sort.desc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy> thenByFvOffsetX() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fvOffsetX', Sort.asc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy>
      thenByFvOffsetXDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fvOffsetX', Sort.desc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy> thenByFvOffsetY() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fvOffsetY', Sort.asc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy>
      thenByFvOffsetYDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fvOffsetY', Sort.desc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy> thenByFvPivotX() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fvPivotX', Sort.asc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy>
      thenByFvPivotXDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fvPivotX', Sort.desc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy> thenByFvPivotY() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fvPivotY', Sort.asc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy>
      thenByFvPivotYDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fvPivotY', Sort.desc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy> thenByGridH() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gridH', Sort.asc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy> thenByGridHDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gridH', Sort.desc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy> thenByGridW() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gridW', Sort.asc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy> thenByGridWDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gridW', Sort.desc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy> thenByImagePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imagePath', Sort.asc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy>
      thenByImagePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imagePath', Sort.desc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy>
      thenByIntrinsicHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'intrinsicHeight', Sort.asc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy>
      thenByIntrinsicHeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'intrinsicHeight', Sort.desc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy>
      thenByIntrinsicWidth() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'intrinsicWidth', Sort.asc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy>
      thenByIntrinsicWidthDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'intrinsicWidth', Sort.desc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy> thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy> thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy> thenByQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantity', Sort.asc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy>
      thenByQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantity', Sort.desc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy> thenByRectHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rectHeight', Sort.asc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy>
      thenByRectHeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rectHeight', Sort.desc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy> thenByRectLeft() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rectLeft', Sort.asc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy>
      thenByRectLeftDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rectLeft', Sort.desc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy> thenByRectTop() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rectTop', Sort.asc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy> thenByRectTopDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rectTop', Sort.desc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy> thenByRectWidth() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rectWidth', Sort.asc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy>
      thenByRectWidthDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rectWidth', Sort.desc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy> thenBySubCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subCategory', Sort.asc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy>
      thenBySubCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subCategory', Sort.desc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy> thenByTbOffsetX() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tbOffsetX', Sort.asc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy>
      thenByTbOffsetXDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tbOffsetX', Sort.desc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy> thenByTbOffsetY() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tbOffsetY', Sort.asc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy>
      thenByTbOffsetYDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tbOffsetY', Sort.desc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy> thenByVOffsetX() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vOffsetX', Sort.asc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy>
      thenByVOffsetXDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vOffsetX', Sort.desc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy> thenByVOffsetY() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vOffsetY', Sort.asc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy>
      thenByVOffsetYDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vOffsetY', Sort.desc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy> thenByVPivotX() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vPivotX', Sort.asc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy> thenByVPivotXDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vPivotX', Sort.desc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy> thenByVPivotY() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vPivotY', Sort.asc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy> thenByVPivotYDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vPivotY', Sort.desc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy>
      thenByVisualRotationX() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'visualRotationX', Sort.asc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy>
      thenByVisualRotationXDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'visualRotationX', Sort.desc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy>
      thenByVisualRotationY() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'visualRotationY', Sort.asc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy>
      thenByVisualRotationYDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'visualRotationY', Sort.desc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy>
      thenByVisualRotationZ() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'visualRotationZ', Sort.asc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy>
      thenByVisualRotationZDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'visualRotationZ', Sort.desc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy> thenByVisualScale() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'visualScale', Sort.asc);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QAfterSortBy>
      thenByVisualScaleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'visualScale', Sort.desc);
    });
  }
}

extension FurnitureItemQueryWhereDistinct
    on QueryBuilder<FurnitureItem, FurnitureItem, QDistinct> {
  QueryBuilder<FurnitureItem, FurnitureItem, QDistinct> distinctByCanBeDyed() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'canBeDyed');
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QDistinct> distinctByCategory(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'category', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QDistinct>
      distinctByFlippedVisualRotationX() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'flippedVisualRotationX');
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QDistinct>
      distinctByFlippedVisualRotationY() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'flippedVisualRotationY');
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QDistinct>
      distinctByFlippedVisualRotationZ() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'flippedVisualRotationZ');
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QDistinct>
      distinctByFlippedVisualScale() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'flippedVisualScale');
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QDistinct> distinctByFvOffsetX() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fvOffsetX');
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QDistinct> distinctByFvOffsetY() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fvOffsetY');
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QDistinct> distinctByFvPivotX() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fvPivotX');
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QDistinct> distinctByFvPivotY() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fvPivotY');
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QDistinct> distinctByGridH() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'gridH');
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QDistinct> distinctByGridW() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'gridW');
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QDistinct> distinctById(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'id', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QDistinct> distinctByImagePath(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'imagePath', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QDistinct>
      distinctByIntrinsicHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'intrinsicHeight');
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QDistinct>
      distinctByIntrinsicWidth() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'intrinsicWidth');
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QDistinct> distinctByQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'quantity');
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QDistinct> distinctByRectHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'rectHeight');
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QDistinct> distinctByRectLeft() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'rectLeft');
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QDistinct> distinctByRectTop() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'rectTop');
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QDistinct> distinctByRectWidth() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'rectWidth');
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QDistinct> distinctBySubCategory(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'subCategory', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QDistinct> distinctByTbOffsetX() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tbOffsetX');
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QDistinct> distinctByTbOffsetY() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tbOffsetY');
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QDistinct> distinctByVOffsetX() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'vOffsetX');
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QDistinct> distinctByVOffsetY() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'vOffsetY');
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QDistinct> distinctByVPivotX() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'vPivotX');
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QDistinct> distinctByVPivotY() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'vPivotY');
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QDistinct>
      distinctByVisualRotationX() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'visualRotationX');
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QDistinct>
      distinctByVisualRotationY() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'visualRotationY');
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QDistinct>
      distinctByVisualRotationZ() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'visualRotationZ');
    });
  }

  QueryBuilder<FurnitureItem, FurnitureItem, QDistinct>
      distinctByVisualScale() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'visualScale');
    });
  }
}

extension FurnitureItemQueryProperty
    on QueryBuilder<FurnitureItem, FurnitureItem, QQueryProperty> {
  QueryBuilder<FurnitureItem, int, QQueryOperations> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<FurnitureItem, bool, QQueryOperations> canBeDyedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'canBeDyed');
    });
  }

  QueryBuilder<FurnitureItem, String, QQueryOperations> categoryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'category');
    });
  }

  QueryBuilder<FurnitureItem, List<FurnitureColorVariant>, QQueryOperations>
      colorVariantsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'colorVariants');
    });
  }

  QueryBuilder<FurnitureItem, double?, QQueryOperations>
      flippedVisualRotationXProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'flippedVisualRotationX');
    });
  }

  QueryBuilder<FurnitureItem, double?, QQueryOperations>
      flippedVisualRotationYProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'flippedVisualRotationY');
    });
  }

  QueryBuilder<FurnitureItem, double?, QQueryOperations>
      flippedVisualRotationZProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'flippedVisualRotationZ');
    });
  }

  QueryBuilder<FurnitureItem, double?, QQueryOperations>
      flippedVisualScaleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'flippedVisualScale');
    });
  }

  QueryBuilder<FurnitureItem, double?, QQueryOperations> fvOffsetXProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fvOffsetX');
    });
  }

  QueryBuilder<FurnitureItem, double?, QQueryOperations> fvOffsetYProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fvOffsetY');
    });
  }

  QueryBuilder<FurnitureItem, double?, QQueryOperations> fvPivotXProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fvPivotX');
    });
  }

  QueryBuilder<FurnitureItem, double?, QQueryOperations> fvPivotYProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fvPivotY');
    });
  }

  QueryBuilder<FurnitureItem, int, QQueryOperations> gridHProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'gridH');
    });
  }

  QueryBuilder<FurnitureItem, int, QQueryOperations> gridWProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'gridW');
    });
  }

  QueryBuilder<FurnitureItem, String, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<FurnitureItem, String, QQueryOperations> imagePathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'imagePath');
    });
  }

  QueryBuilder<FurnitureItem, double, QQueryOperations>
      intrinsicHeightProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'intrinsicHeight');
    });
  }

  QueryBuilder<FurnitureItem, double, QQueryOperations>
      intrinsicWidthProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'intrinsicWidth');
    });
  }

  QueryBuilder<FurnitureItem, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<FurnitureItem, int, QQueryOperations> quantityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'quantity');
    });
  }

  QueryBuilder<FurnitureItem, double, QQueryOperations> rectHeightProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rectHeight');
    });
  }

  QueryBuilder<FurnitureItem, double, QQueryOperations> rectLeftProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rectLeft');
    });
  }

  QueryBuilder<FurnitureItem, double, QQueryOperations> rectTopProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rectTop');
    });
  }

  QueryBuilder<FurnitureItem, double, QQueryOperations> rectWidthProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rectWidth');
    });
  }

  QueryBuilder<FurnitureItem, String, QQueryOperations> subCategoryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'subCategory');
    });
  }

  QueryBuilder<FurnitureItem, double, QQueryOperations> tbOffsetXProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tbOffsetX');
    });
  }

  QueryBuilder<FurnitureItem, double, QQueryOperations> tbOffsetYProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tbOffsetY');
    });
  }

  QueryBuilder<FurnitureItem, double, QQueryOperations> vOffsetXProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'vOffsetX');
    });
  }

  QueryBuilder<FurnitureItem, double, QQueryOperations> vOffsetYProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'vOffsetY');
    });
  }

  QueryBuilder<FurnitureItem, double, QQueryOperations> vPivotXProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'vPivotX');
    });
  }

  QueryBuilder<FurnitureItem, double, QQueryOperations> vPivotYProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'vPivotY');
    });
  }

  QueryBuilder<FurnitureItem, double, QQueryOperations>
      visualRotationXProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'visualRotationX');
    });
  }

  QueryBuilder<FurnitureItem, double, QQueryOperations>
      visualRotationYProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'visualRotationY');
    });
  }

  QueryBuilder<FurnitureItem, double, QQueryOperations>
      visualRotationZProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'visualRotationZ');
    });
  }

  QueryBuilder<FurnitureItem, double, QQueryOperations> visualScaleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'visualScale');
    });
  }
}

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const FurnitureColorVariantSchema = Schema(
  name: r'FurnitureColorVariant',
  id: 1899219684498971527,
  properties: {
    r'colorValue': PropertySchema(
      id: 0,
      name: r'colorValue',
      type: IsarType.long,
    ),
    r'dyeCost': PropertySchema(
      id: 1,
      name: r'dyeCost',
      type: IsarType.long,
    ),
    r'goldCost': PropertySchema(
      id: 2,
      name: r'goldCost',
      type: IsarType.long,
    ),
    r'id': PropertySchema(
      id: 3,
      name: r'id',
      type: IsarType.string,
    ),
    r'imagePath': PropertySchema(
      id: 4,
      name: r'imagePath',
      type: IsarType.string,
    ),
    r'name': PropertySchema(
      id: 5,
      name: r'name',
      type: IsarType.string,
    )
  },
  estimateSize: _furnitureColorVariantEstimateSize,
  serialize: _furnitureColorVariantSerialize,
  deserialize: _furnitureColorVariantDeserialize,
  deserializeProp: _furnitureColorVariantDeserializeProp,
);

int _furnitureColorVariantEstimateSize(
  FurnitureColorVariant object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.id.length * 3;
  bytesCount += 3 + object.imagePath.length * 3;
  bytesCount += 3 + object.name.length * 3;
  return bytesCount;
}

void _furnitureColorVariantSerialize(
  FurnitureColorVariant object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.colorValue);
  writer.writeLong(offsets[1], object.dyeCost);
  writer.writeLong(offsets[2], object.goldCost);
  writer.writeString(offsets[3], object.id);
  writer.writeString(offsets[4], object.imagePath);
  writer.writeString(offsets[5], object.name);
}

FurnitureColorVariant _furnitureColorVariantDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = FurnitureColorVariant(
    colorValue: reader.readLongOrNull(offsets[0]) ?? 0,
    dyeCost: reader.readLongOrNull(offsets[1]) ?? 1,
    goldCost: reader.readLongOrNull(offsets[2]) ?? 100,
    id: reader.readStringOrNull(offsets[3]) ?? '',
    imagePath: reader.readStringOrNull(offsets[4]) ?? '',
    name: reader.readStringOrNull(offsets[5]) ?? '',
  );
  return object;
}

P _furnitureColorVariantDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLongOrNull(offset) ?? 0) as P;
    case 1:
      return (reader.readLongOrNull(offset) ?? 1) as P;
    case 2:
      return (reader.readLongOrNull(offset) ?? 100) as P;
    case 3:
      return (reader.readStringOrNull(offset) ?? '') as P;
    case 4:
      return (reader.readStringOrNull(offset) ?? '') as P;
    case 5:
      return (reader.readStringOrNull(offset) ?? '') as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension FurnitureColorVariantQueryFilter on QueryBuilder<
    FurnitureColorVariant, FurnitureColorVariant, QFilterCondition> {
  QueryBuilder<FurnitureColorVariant, FurnitureColorVariant,
      QAfterFilterCondition> colorValueEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'colorValue',
        value: value,
      ));
    });
  }

  QueryBuilder<FurnitureColorVariant, FurnitureColorVariant,
      QAfterFilterCondition> colorValueGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'colorValue',
        value: value,
      ));
    });
  }

  QueryBuilder<FurnitureColorVariant, FurnitureColorVariant,
      QAfterFilterCondition> colorValueLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'colorValue',
        value: value,
      ));
    });
  }

  QueryBuilder<FurnitureColorVariant, FurnitureColorVariant,
      QAfterFilterCondition> colorValueBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'colorValue',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<FurnitureColorVariant, FurnitureColorVariant,
      QAfterFilterCondition> dyeCostEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dyeCost',
        value: value,
      ));
    });
  }

  QueryBuilder<FurnitureColorVariant, FurnitureColorVariant,
      QAfterFilterCondition> dyeCostGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dyeCost',
        value: value,
      ));
    });
  }

  QueryBuilder<FurnitureColorVariant, FurnitureColorVariant,
      QAfterFilterCondition> dyeCostLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dyeCost',
        value: value,
      ));
    });
  }

  QueryBuilder<FurnitureColorVariant, FurnitureColorVariant,
      QAfterFilterCondition> dyeCostBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dyeCost',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<FurnitureColorVariant, FurnitureColorVariant,
      QAfterFilterCondition> goldCostEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'goldCost',
        value: value,
      ));
    });
  }

  QueryBuilder<FurnitureColorVariant, FurnitureColorVariant,
      QAfterFilterCondition> goldCostGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'goldCost',
        value: value,
      ));
    });
  }

  QueryBuilder<FurnitureColorVariant, FurnitureColorVariant,
      QAfterFilterCondition> goldCostLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'goldCost',
        value: value,
      ));
    });
  }

  QueryBuilder<FurnitureColorVariant, FurnitureColorVariant,
      QAfterFilterCondition> goldCostBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'goldCost',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<FurnitureColorVariant, FurnitureColorVariant,
      QAfterFilterCondition> idEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureColorVariant, FurnitureColorVariant,
      QAfterFilterCondition> idGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureColorVariant, FurnitureColorVariant,
      QAfterFilterCondition> idLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureColorVariant, FurnitureColorVariant,
      QAfterFilterCondition> idBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureColorVariant, FurnitureColorVariant,
      QAfterFilterCondition> idStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureColorVariant, FurnitureColorVariant,
      QAfterFilterCondition> idEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureColorVariant, FurnitureColorVariant,
          QAfterFilterCondition>
      idContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureColorVariant, FurnitureColorVariant,
          QAfterFilterCondition>
      idMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'id',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureColorVariant, FurnitureColorVariant,
      QAfterFilterCondition> idIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<FurnitureColorVariant, FurnitureColorVariant,
      QAfterFilterCondition> idIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<FurnitureColorVariant, FurnitureColorVariant,
      QAfterFilterCondition> imagePathEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'imagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureColorVariant, FurnitureColorVariant,
      QAfterFilterCondition> imagePathGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'imagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureColorVariant, FurnitureColorVariant,
      QAfterFilterCondition> imagePathLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'imagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureColorVariant, FurnitureColorVariant,
      QAfterFilterCondition> imagePathBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'imagePath',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureColorVariant, FurnitureColorVariant,
      QAfterFilterCondition> imagePathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'imagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureColorVariant, FurnitureColorVariant,
      QAfterFilterCondition> imagePathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'imagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureColorVariant, FurnitureColorVariant,
          QAfterFilterCondition>
      imagePathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'imagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureColorVariant, FurnitureColorVariant,
          QAfterFilterCondition>
      imagePathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'imagePath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureColorVariant, FurnitureColorVariant,
      QAfterFilterCondition> imagePathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'imagePath',
        value: '',
      ));
    });
  }

  QueryBuilder<FurnitureColorVariant, FurnitureColorVariant,
      QAfterFilterCondition> imagePathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'imagePath',
        value: '',
      ));
    });
  }

  QueryBuilder<FurnitureColorVariant, FurnitureColorVariant,
      QAfterFilterCondition> nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureColorVariant, FurnitureColorVariant,
      QAfterFilterCondition> nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureColorVariant, FurnitureColorVariant,
      QAfterFilterCondition> nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureColorVariant, FurnitureColorVariant,
      QAfterFilterCondition> nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureColorVariant, FurnitureColorVariant,
      QAfterFilterCondition> nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureColorVariant, FurnitureColorVariant,
      QAfterFilterCondition> nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureColorVariant, FurnitureColorVariant,
          QAfterFilterCondition>
      nameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureColorVariant, FurnitureColorVariant,
          QAfterFilterCondition>
      nameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureColorVariant, FurnitureColorVariant,
      QAfterFilterCondition> nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<FurnitureColorVariant, FurnitureColorVariant,
      QAfterFilterCondition> nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }
}

extension FurnitureColorVariantQueryObject on QueryBuilder<
    FurnitureColorVariant, FurnitureColorVariant, QFilterCondition> {}
