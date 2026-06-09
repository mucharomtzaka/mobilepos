import '../database/database_helper.dart';
import '../models/order.dart';

class OrderDao {
  final _db = DatabaseHelper.instance;

  Future<int> insertOrder(Order order) async {
    final db = await _db.db;
    return db.insert('orders', order.toMap());
  }

  Future<void> insertItems(List<OrderItem> items) async {
    final db = await _db.db;
    final batch = db.batch();
    for (final item in items) {
      batch.insert('order_items', item.toMap());
    }
    await batch.commit();
  }

  Future<void> insertPayments(int orderId, List<PaymentEntry> payments) async {
    final db = await _db.db;
    final batch = db.batch();
    for (final p in payments) {
      batch.insert('payments', {
        'order_id': orderId,
        'method': p.method.value,
        'amount': p.amount,
        'reference': p.reference,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
    await batch.commit();
  }

  Future<int> insertDraftOrder(Order order, List<OrderItem> items) async {
    final db = await _db.db;
    final orderMap = order.toMap();
    orderMap['status'] = 'draft';
    final orderId = await db.insert('orders', orderMap);
    for (final item in items) {
      final itemMap = item.toMap();
      itemMap['order_id'] = orderId;
      await db.insert('order_items', itemMap);
    }
    return orderId;
  }

  Future<void> updateDraftOrder(int orderId, Order order, List<OrderItem> items) async {
    final db = await _db.db;
    final orderMap = order.toMap();
    orderMap['status'] = 'draft';
    await db.update(
      'orders',
      orderMap,
      where: 'id = ?',
      whereArgs: [orderId],
    );
    // Delete old items and insert new
    await db.delete('order_items', where: 'order_id = ?', whereArgs: [orderId]);
    for (final item in items) {
      final itemMap = item.toMap();
      itemMap['order_id'] = orderId;
      await db.insert('order_items', itemMap);
    }
  }

  Future<List<Order>> getDraftOrders() async {
    final db = await _db.db;
    final rows = await db.query('orders',
        where: "status = 'draft'", orderBy: 'created_at DESC');
    return rows.map(Order.fromMap).toList();
  }

  Future<void> deleteDraftOrder(int orderId) async {
    final db = await _db.db;
    await db.delete('order_items', where: 'order_id = ?', whereArgs: [orderId]);
    await db.delete('orders', where: 'id = ?', whereArgs: [orderId]);
  }

  Future<void> updateStatus(int orderId, String status) async {
    final db = await _db.db;
    await db.update(
      'orders',
      {'status': status},
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }

  Future<List<Order>> getOrders({
    String? startDate,
    String? endDate,
    int? shiftId,
    int? limit,
    int? offset,
  }) async {
    final db = await _db.db;
    final wheres = <String>[];
    final args = <dynamic>[];
    if (startDate != null) {
      wheres.add("date(created_at) >= date(?)");
      args.add(startDate);
    }
    if (endDate != null) {
      wheres.add("date(created_at) <= date(?)");
      args.add(endDate);
    }
    if (shiftId != null) {
      wheres.add('shift_id = ?');
      args.add(shiftId);
    }
    final where = wheres.isEmpty ? '' : 'WHERE ${wheres.join(' AND ')}';
    var sql = 'SELECT * FROM orders $where ORDER BY created_at DESC';
    if (limit != null) {
      sql += ' LIMIT $limit';
      if (offset != null) sql += ' OFFSET $offset';
    }
    final rows = await db.rawQuery(sql, args);
    return rows.map(Order.fromMap).toList();
  }

  Future<List<OrderItem>> getItemsByOrderId(int orderId) async {
    final db = await _db.db;
    final rows = await db.query('order_items',
        where: 'order_id = ?', whereArgs: [orderId]);
    return rows.map(OrderItem.fromMap).toList();
  }

  Future<List<PaymentEntry>> getPaymentsByOrderId(int orderId) async {
    final db = await _db.db;
    final rows = await db.query('payments',
        where: 'order_id = ?', whereArgs: [orderId]);
    return rows.map((m) => PaymentEntry(
      method: PaymentMethodExt.fromString(m['method'] as String),
      amount: (m['amount'] as num).toDouble(),
      reference: m['reference'] as String?,
    )).toList();
  }

  Future<int> getOrdersCount({
    String? startDate,
    String? endDate,
  }) async {
    final db = await _db.db;
    final wheres = <String>[];
    final args = <dynamic>[];
    wheres.add("status = 'completed'");
    if (startDate != null) {
      wheres.add("date(created_at) >= date(?)");
      args.add(startDate);
    }
    if (endDate != null) {
      wheres.add("date(created_at) <= date(?)");
      args.add(endDate);
    }
    final result = await db.rawQuery(
        'SELECT COUNT(*) as cnt FROM orders WHERE ${wheres.join(' AND ')}', args);
    return (result.first['cnt'] as int);
  }

  Future<int> getItemSalesCount({
    required String startDate,
    required String endDate,
  }) async {
    final db = await _db.db;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as cnt
      FROM order_items oi
      JOIN orders o ON oi.order_id = o.id
      WHERE date(o.created_at) BETWEEN date(?) AND date(?)
        AND o.status = 'completed'
    ''', [startDate, endDate]);
    return (result.first['cnt'] as int);
  }

  Future<Map<String, dynamic>> getSummary({
    required String startDate,
    required String endDate,
  }) async {
    final db = await _db.db;
    final result = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_orders,
        SUM(total) as total_revenue,
        SUM(discount_amount) as total_discount
      FROM orders
      WHERE date(created_at) BETWEEN date(?) AND date(?)
        AND status = 'completed'
    ''', [startDate, endDate]);
    return result.first;
  }

  Future<List<Map<String, dynamic>>> getTopProducts({
    required String startDate,
    required String endDate,
    int limit = 10,
  }) async {
    final db = await _db.db;
    return db.rawQuery('''
      SELECT oi.product_name, SUM(oi.qty) as total_qty, SUM(oi.subtotal) as total_revenue
      FROM order_items oi
      JOIN orders o ON oi.order_id = o.id
      WHERE date(o.created_at) BETWEEN date(?) AND date(?)
        AND o.status = 'completed'
      GROUP BY oi.product_name
      ORDER BY total_qty DESC
      LIMIT ?
    ''', [startDate, endDate, limit]);
  }

  Future<List<Map<String, dynamic>>> getItemSales({
    required String startDate,
    required String endDate,
    int? limit,
    int? offset,
  }) async {
    final db = await _db.db;
    var sql = '''
      SELECT oi.product_name, oi.variant_name, oi.price, oi.qty, oi.subtotal,
             o.created_at, o.order_number
      FROM order_items oi
      JOIN orders o ON oi.order_id = o.id
      WHERE date(o.created_at) BETWEEN date(?) AND date(?)
        AND o.status = 'completed'
      ORDER BY o.created_at DESC, oi.id ASC
    ''';
    if (limit != null) {
      sql += ' LIMIT $limit';
      if (offset != null) sql += ' OFFSET $offset';
    }
    return db.rawQuery(sql, [startDate, endDate]);
  }

  Future<List<Map<String, dynamic>>> getPaymentSummary({
    required String startDate,
    required String endDate,
  }) async {
    final db = await _db.db;
    return db.rawQuery('''
      SELECT p.method, SUM(p.amount) as total
      FROM payments p
      JOIN orders o ON p.order_id = o.id
      WHERE date(o.created_at) BETWEEN date(?) AND date(?)
        AND o.status = 'completed'
      GROUP BY p.method
    ''', [startDate, endDate]);
  }

  // Analytics - Daily sales for chart
  Future<List<Map<String, dynamic>>> getDailySales({
    required String startDate,
    required String endDate,
  }) async {
    final db = await _db.db;
    return db.rawQuery('''
      SELECT date(created_at) as date, COUNT(*) as orders, SUM(total) as revenue
      FROM orders
      WHERE date(created_at) BETWEEN date(?) AND date(?)
        AND status = 'completed'
      GROUP BY date(created_at)
      ORDER BY date ASC
    ''', [startDate, endDate]);
  }

  // Analytics - Hourly sales
  Future<List<Map<String, dynamic>>> getHourlySales({
    required String startDate,
    required String endDate,
  }) async {
    final db = await _db.db;
    return db.rawQuery('''
      SELECT strftime('%H', created_at) as hour, COUNT(*) as orders, SUM(total) as revenue
      FROM orders
      WHERE date(created_at) BETWEEN date(?) AND date(?)
        AND status = 'completed'
      GROUP BY hour
      ORDER BY hour ASC
    ''', [startDate, endDate]);
  }

  // Analytics - Compare with previous period
  Future<Map<String, dynamic>> getComparison({
    required String startDate,
    required String endDate,
  }) async {
    final db = await _db.db;
    // Current period
    final current = await db.rawQuery('''
      SELECT COUNT(*) as orders, COALESCE(SUM(total), 0) as revenue
      FROM orders
      WHERE date(created_at) BETWEEN date(?) AND date(?)
        AND status = 'completed'
    ''', [startDate, endDate]);

    // Calculate previous period dates
    final start = DateTime.parse(startDate);
    final end = DateTime.parse(endDate);
    final diff = end.difference(start).inDays;
    final prevStart = start.subtract(Duration(days: diff + 1));
    final prevEnd = start.subtract(const Duration(days: 1));

    final previous = await db.rawQuery('''
      SELECT COUNT(*) as orders, COALESCE(SUM(total), 0) as revenue
      FROM orders
      WHERE date(created_at) BETWEEN date(?) AND date(?)
        AND status = 'completed'
    ''', [prevStart.toIso8601String().split('T')[0], prevEnd.toIso8601String().split('T')[0]]);

    final currOrders = (current.first['orders'] as int?) ?? 0;
    final currRevenue = (current.first['revenue'] as num?)?.toDouble() ?? 0;
    final prevOrders = (previous.first['orders'] as int?) ?? 0;
    final prevRevenue = (previous.first['revenue'] as num?)?.toDouble() ?? 0;

    // Calculate growth percentage
    final ordersGrowth = prevOrders > 0 ? ((currOrders - prevOrders) / prevOrders * 100) : (currOrders > 0 ? 100 : 0);
    final revenueGrowth = prevRevenue > 0 ? ((currRevenue - prevRevenue) / prevRevenue * 100) : (currRevenue > 0 ? 100 : 0);

    return {
      'currentOrders': currOrders,
      'currentRevenue': currRevenue,
      'previousOrders': prevOrders,
      'previousRevenue': prevRevenue,
      'ordersGrowth': ordersGrowth,
      'revenueGrowth': revenueGrowth,
    };
  }
}
