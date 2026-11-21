import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class LocalDatabase {
  static final LocalDatabase _instance = LocalDatabase._internal();

  factory LocalDatabase() => _instance;

  LocalDatabase._internal();

  Database? _database;

  Future<LocalDatabase> init() async {
    if (_database != null) return this;

    final databasesPath = await getDatabasesPath();
    final databasePath = path.join(databasesPath, 'ejary_database.db');

    _database = await openDatabase(
      databasePath,
      version: 1,
      onCreate: _createDatabase,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );

    return this;
  }

  Database get database {
    final db = _database;
    if (db == null) {
      throw StateError(
        'LocalDatabase has not been initialized. Call init() first.',
      );
    }
    return db;
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE properties (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        property_type TEXT NOT NULL,
        address TEXT,
        description TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE departments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        property_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (property_id) REFERENCES properties(id)
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE units (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        property_id INTEGER NOT NULL,
        department_id INTEGER,
        unit_number TEXT NOT NULL,
        unit_type TEXT NOT NULL,
        floor_number INTEGER,
        area REAL,
        monthly_rent REAL NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'available',
        description TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY (property_id) REFERENCES properties(id)
          ON DELETE CASCADE,
        FOREIGN KEY (department_id) REFERENCES departments(id)
          ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE tenants (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        full_name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        national_id TEXT,
        address TEXT,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE contracts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        contract_number TEXT NOT NULL UNIQUE,
        tenant_id INTEGER NOT NULL,
        unit_id INTEGER NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        monthly_rent REAL NOT NULL,
        deposit_amount REAL NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'active',
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (tenant_id) REFERENCES tenants(id),
        FOREIGN KEY (unit_id) REFERENCES units(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE services (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        default_amount REAL NOT NULL DEFAULT 0,
        billing_period TEXT NOT NULL DEFAULT 'monthly',
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE contract_services (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        contract_id INTEGER NOT NULL,
        service_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        FOREIGN KEY (contract_id) REFERENCES contracts(id)
          ON DELETE CASCADE,
        FOREIGN KEY (service_id) REFERENCES services(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE dues (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        contract_id INTEGER NOT NULL,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        due_date TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'unpaid',
        created_at TEXT NOT NULL,
        FOREIGN KEY (contract_id) REFERENCES contracts(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tenant_id INTEGER NOT NULL,
        contract_id INTEGER,
        amount REAL NOT NULL,
        payment_date TEXT NOT NULL,
        payment_method TEXT,
        reference_number TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (tenant_id) REFERENCES tenants(id),
        FOREIGN KEY (contract_id) REFERENCES contracts(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE payment_allocations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        payment_id INTEGER NOT NULL,
        due_id INTEGER NOT NULL,
        allocated_amount REAL NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (payment_id) REFERENCES payments(id)
          ON DELETE CASCADE,
        FOREIGN KEY (due_id) REFERENCES dues(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE maintenance_requests (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        property_id INTEGER NOT NULL,
        unit_id INTEGER,
        title TEXT NOT NULL,
        description TEXT,
        priority TEXT NOT NULL DEFAULT 'normal',
        status TEXT NOT NULL DEFAULT 'pending',
        request_date TEXT NOT NULL,
        completion_date TEXT,
        cost REAL NOT NULL DEFAULT 0,
        FOREIGN KEY (property_id) REFERENCES properties(id),
        FOREIGN KEY (unit_id) REFERENCES units(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE attachments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        property_id INTEGER,
        unit_id INTEGER,
        tenant_id INTEGER,
        contract_id INTEGER,
        payment_id INTEGER,
        file_name TEXT NOT NULL,
        storage_path TEXT NOT NULL,
        file_type TEXT,
        file_size INTEGER,
        created_at TEXT NOT NULL,
        FOREIGN KEY (property_id) REFERENCES properties(id),
        FOREIGN KEY (unit_id) REFERENCES units(id),
        FOREIGN KEY (tenant_id) REFERENCES tenants(id),
        FOREIGN KEY (contract_id) REFERENCES contracts(id),
        FOREIGN KEY (payment_id) REFERENCES payments(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE audit_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        action TEXT NOT NULL,
        entity_type TEXT NOT NULL,
        entity_id INTEGER,
        description TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('CREATE INDEX idx_units_property ON units(property_id)');
    await db.execute(
      'CREATE INDEX idx_units_department ON units(department_id)',
    );
    await db.execute(
      'CREATE INDEX idx_contracts_tenant ON contracts(tenant_id)',
    );
    await db.execute('CREATE INDEX idx_contracts_unit ON contracts(unit_id)');
    await db.execute('CREATE INDEX idx_dues_contract ON dues(contract_id)');
    await db.execute('CREATE INDEX idx_payments_tenant ON payments(tenant_id)');
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
