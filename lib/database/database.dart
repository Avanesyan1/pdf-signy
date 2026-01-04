import 'dart:io';
import 'dart:typed_data';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

class Signatures extends Table {
  IntColumn get id => integer().autoIncrement()();
  BlobColumn get imageBytes => blob()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get name => text().nullable()();
}

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Stamps extends Table {
  IntColumn get id => integer().autoIncrement()();
  BlobColumn get imageBytes => blob()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get name => text().nullable()();
}

class Documents extends Table {
  IntColumn get id => integer().autoIncrement()();
  BlobColumn get pdfBytes => blob()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get signedAt => dateTime().nullable()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  IntColumn get categoryId => integer().nullable().references(Categories, #id)();
}

@DriftDatabase(tables: [Signatures, Documents, Categories, Stamps])
class AppDatabase extends _$AppDatabase {
  AppDatabase._internal() : super(_openConnection());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          // Add signedAt column
          await m.addColumn(documents, documents.signedAt);
        }
        if (from < 3) {
          // Add isFavorite column
          await m.addColumn(documents, documents.isFavorite);
        }
        if (from < 4) {
          // Add Categories table and categoryId column
          await m.createTable(categories);
          await m.addColumn(documents, documents.categoryId);
        }
        if (from < 5) {
          // Add Stamps table
          await m.createTable(stamps);
        }
      },
    );
  }

  static AppDatabase? _instance;

  static AppDatabase get instance {
    _instance ??= AppDatabase._internal();
    return _instance!;
  }

  // Stream to watch all signatures
  Stream<List<Signature>> watchSignatures() {
    return (select(signatures)..orderBy([(s) => OrderingTerm.desc(s.createdAt)])).watch();
  }

  // Get all signatures
  Future<List<Signature>> getSignatures() async {
    return await (select(signatures)..orderBy([(s) => OrderingTerm.desc(s.createdAt)])).get();
  }

  // Insert signature
  Future<int> insertSignature(SignaturesCompanion signature) async {
    return await into(signatures).insert(signature);
  }

  // Delete signature
  Future<bool> deleteSignature(int id) async {
    return await (delete(signatures)..where((s) => s.id.equals(id))).go() > 0;
  }

  // Stream to watch all documents
  Stream<List<Document>> watchDocuments() {
    return (select(documents)..orderBy([(d) => OrderingTerm.desc(d.createdAt)])).watch();
  }

  // Get all documents
  Future<List<Document>> getDocuments() async {
    return await (select(documents)..orderBy([(d) => OrderingTerm.desc(d.createdAt)])).get();
  }

  // Insert document (internal method)
  Future<int> _insertDocument(DocumentsCompanion document) async {
    try {
      final id = await into(documents).insert(document);
      return id;
    } catch (e) {
      rethrow;
    }
  }

  // Add document from bytes (universal method for all sources)
  Future<int> addDocument({
    required Uint8List pdfBytes,
    required String fileName,
    bool isFavorite = false,
    int? categoryId,
  }) async {
    try {
      final companion = DocumentsCompanion.insert(
        pdfBytes: pdfBytes,
        name: fileName,
      ).copyWith(
        isFavorite: Value(isFavorite),
        categoryId: categoryId != null ? Value(categoryId) : const Value.absent(),
      );
      
      return await _insertDocument(companion);
    } catch (e) {
      rethrow;
    }
  }

  // Legacy method for backward compatibility
  @Deprecated('Use addDocument instead')
  Future<int> insertDocument(DocumentsCompanion document) async {
    return await _insertDocument(document);
  }

  // Update document
  Future<void> updateDocument(Document document) async {
    await update(documents).replace(document);
  }

  // Update document by companion
  Future<bool> updateDocumentById(int id, DocumentsCompanion document) async {
    return await (update(documents)..where((d) => d.id.equals(id))).write(document) > 0;
  }

  // Search documents by name with filters
  Stream<List<Document>> watchDocumentsWithFilter({
    String? searchQuery,
    bool? isSigned,
    bool? isFavorite,
    int? categoryId,
    String? sortBy, // 'date', 'name', 'size'
    bool ascending = false,
  }) {
    var query = select(documents);

    // Search filter
    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query..where((d) => d.name.like('%$searchQuery%'));
    }

    // Signed/Unsigned filter
    if (isSigned != null) {
      if (isSigned) {
        query = query..where((d) => d.signedAt.isNotNull());
      } else {
        query = query..where((d) => d.signedAt.isNull());
      }
    }

    // Favorite filter
    if (isFavorite != null) {
      query = query..where((d) => d.isFavorite.equals(isFavorite));
    }

    // Category filter
    if (categoryId != null) {
      query = query..where((d) => d.categoryId.equals(categoryId));
    }

    // Sorting
    if (sortBy == 'name') {
      query = query
        ..orderBy([(d) => ascending ? OrderingTerm.asc(d.name) : OrderingTerm.desc(d.name)]);
    } else if (sortBy == 'size') {
      // Note: We can't sort by size directly, so we'll sort by creation date for now
      query = query
        ..orderBy([
          (d) => ascending ? OrderingTerm.asc(d.createdAt) : OrderingTerm.desc(d.createdAt),
        ]);
    } else {
      // Default: sort by date
      query = query
        ..orderBy([
          (d) => ascending ? OrderingTerm.asc(d.createdAt) : OrderingTerm.desc(d.createdAt),
        ]);
    }

    return query.watch();
  }

  // Get documents with sorting
  Future<List<Document>> getDocumentsSorted({
    String sortBy = 'date', // 'date', 'name', 'size'
    bool ascending = false,
  }) async {
    var query = select(documents);

    if (sortBy == 'name') {
      query = query
        ..orderBy([(d) => ascending ? OrderingTerm.asc(d.name) : OrderingTerm.desc(d.name)]);
    } else if (sortBy == 'size') {
      // Note: We can't sort by size directly, so we'll sort by creation date for now
      // In a real app, you'd need to add a size column
      query = query
        ..orderBy([
          (d) => ascending ? OrderingTerm.asc(d.createdAt) : OrderingTerm.desc(d.createdAt),
        ]);
    } else {
      query = query
        ..orderBy([
          (d) => ascending ? OrderingTerm.asc(d.createdAt) : OrderingTerm.desc(d.createdAt),
        ]);
    }

    return await query.get();
  }

  // Toggle favorite status
  Future<void> toggleFavorite(int id, bool isFavorite) async {
    await (update(
      documents,
    )..where((d) => d.id.equals(id))).write(DocumentsCompanion(isFavorite: Value(isFavorite)));
  }

  // Search signatures by name
  Stream<List<Signature>> watchSignaturesWithFilter(String? searchQuery) {
    var query = select(signatures);

    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query..where((s) => s.name.like('%$searchQuery%'));
    }

    return (query..orderBy([(s) => OrderingTerm.desc(s.createdAt)])).watch();
  }

  // Delete document
  Future<bool> deleteDocument(int id) async {
    return await (delete(documents)..where((d) => d.id.equals(id))).go() > 0;
  }

  // Get document by id
  Future<Document?> getDocumentById(int id) async {
    return await (select(documents)..where((d) => d.id.equals(id))).getSingleOrNull();
  }

  // Categories methods
  Stream<List<Category>> watchCategories() {
    return (select(categories)..orderBy([(c) => OrderingTerm.asc(c.name)])).watch();
  }

  Future<List<Category>> getCategories() async {
    return await (select(categories)..orderBy([(c) => OrderingTerm.asc(c.name)])).get();
  }

  Future<int> insertCategory(CategoriesCompanion category) async {
    return await into(categories).insert(category);
  }

  Future<bool> deleteCategory(int id) async {
    // First, remove category from all documents
    await (update(documents)..where((d) => d.categoryId.equals(id))).write(
      DocumentsCompanion(categoryId: const Value.absent()),
    );
    // Then delete category
    return await (delete(categories)..where((c) => c.id.equals(id))).go() > 0;
  }

  Future<void> updateCategory(Category category) async {
    await update(categories).replace(category);
  }

  // Stamps methods
  Stream<List<Stamp>> watchStamps() {
    return (select(stamps)..orderBy([(s) => OrderingTerm.desc(s.createdAt)])).watch();
  }

  Future<List<Stamp>> getStamps() async {
    return await (select(stamps)..orderBy([(s) => OrderingTerm.desc(s.createdAt)])).get();
  }

  Future<int> insertStamp(StampsCompanion stamp) async {
    return await into(stamps).insert(stamp);
  }

  Future<bool> deleteStamp(int id) async {
    return await (delete(stamps)..where((s) => s.id.equals(id))).go() > 0;
  }

  Stream<List<Stamp>> watchStampsWithFilter(String? searchQuery) {
    var query = select(stamps);

    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query..where((s) => s.name.like('%$searchQuery%'));
    }

    return (query..orderBy([(s) => OrderingTerm.desc(s.createdAt)])).watch();
  }

  // Statistics
  Future<Map<String, int>> getStatistics() async {
    final allDocuments = await getDocuments();
    final allSignatures = await getSignatures();
    final allStamps = await getStamps();
    final signedCount = allDocuments.where((d) => d.signedAt != null).length;
    final favoriteCount = allDocuments.where((d) => d.isFavorite).length;
    final categoriesCount = await (select(categories)).get().then((list) => list.length);

    return {
      'totalDocuments': allDocuments.length,
      'totalSignatures': allSignatures.length,
      'totalStamps': allStamps.length,
      'signedDocuments': signedCount,
      'unsignedDocuments': allDocuments.length - signedCount,
      'favoriteDocuments': favoriteCount,
      'categories': categoriesCount,
    };
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'signatures.db'));
    return NativeDatabase(file);
  });
}
