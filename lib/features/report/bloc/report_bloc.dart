import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/database/order_dao.dart';
import '../../../core/models/order.dart';

const _pageSize = 20;

// Events
abstract class ReportEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class ReportLoad extends ReportEvent {
  final String startDate;
  final String endDate;
  ReportLoad({required this.startDate, required this.endDate});
  @override
  List<Object?> get props => [startDate, endDate];
}

class ReportLoadMoreOrders extends ReportEvent {}

class ReportLoadMoreItems extends ReportEvent {}

// States
abstract class ReportState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ReportInitial extends ReportState {}
class ReportLoading extends ReportState {}

class ReportLoaded extends ReportState {
  final String startDate;
  final String endDate;
  final int totalOrders;
  final double totalRevenue;
  final double totalDiscount;
  final List<Order> orders;
  final int ordersPage;
  final int ordersTotal;
  final List<Map<String, dynamic>> topProducts;
  final List<Map<String, dynamic>> paymentSummary;
  final List<Map<String, dynamic>> itemSales;
  final int itemSalesPage;
  final int itemSalesTotal;
  // Analytics
  final List<Map<String, dynamic>> dailySales;
  final List<Map<String, dynamic>> hourlySales;
  final Map<String, dynamic> comparison;

  ReportLoaded({
    required this.startDate,
    required this.endDate,
    required this.totalOrders,
    required this.totalRevenue,
    required this.totalDiscount,
    required this.orders,
    required this.ordersPage,
    required this.ordersTotal,
    required this.topProducts,
    required this.paymentSummary,
    required this.itemSales,
    required this.itemSalesPage,
    required this.itemSalesTotal,
    this.dailySales = const [],
    this.hourlySales = const [],
    this.comparison = const {},
  });

  bool get hasMoreOrders => orders.length < ordersTotal;
  bool get hasMoreItems => itemSales.length < itemSalesTotal;

  @override
  List<Object?> get props => [startDate, endDate, totalOrders];
}

class ReportError extends ReportState {
  final String message;
  ReportError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class ReportBloc extends Bloc<ReportEvent, ReportState> {
  final OrderDao _dao;

  ReportBloc(this._dao) : super(ReportInitial()) {
    on<ReportLoad>(_onLoad);
    on<ReportLoadMoreOrders>(_onLoadMoreOrders);
    on<ReportLoadMoreItems>(_onLoadMoreItems);
  }

  Future<void> _onLoad(ReportLoad e, Emitter<ReportState> emit) async {
    emit(ReportLoading());
    try {
      final summary =
          await _dao.getSummary(startDate: e.startDate, endDate: e.endDate);
      final orders = await _dao.getOrders(
          startDate: e.startDate, endDate: e.endDate, limit: _pageSize);
      final ordersTotal = await _dao.getOrdersCount(
          startDate: e.startDate, endDate: e.endDate);
      final topProducts = await _dao.getTopProducts(
          startDate: e.startDate, endDate: e.endDate);
      final paymentSummary = await _dao.getPaymentSummary(
          startDate: e.startDate, endDate: e.endDate);
      final itemSales = await _dao.getItemSales(
          startDate: e.startDate, endDate: e.endDate, limit: _pageSize);
      final itemSalesTotal = await _dao.getItemSalesCount(
          startDate: e.startDate, endDate: e.endDate);

      // Analytics data
      final dailySales = await _dao.getDailySales(
          startDate: e.startDate, endDate: e.endDate);
      final hourlySales = await _dao.getHourlySales(
          startDate: e.startDate, endDate: e.endDate);
      final comparison = await _dao.getComparison(
          startDate: e.startDate, endDate: e.endDate);

      emit(ReportLoaded(
        startDate: e.startDate,
        endDate: e.endDate,
        totalOrders: (summary['total_orders'] as int?) ?? 0,
        totalRevenue: (summary['total_revenue'] as num?)?.toDouble() ?? 0,
        totalDiscount: (summary['total_discount'] as num?)?.toDouble() ?? 0,
        orders: orders,
        ordersPage: 1,
        ordersTotal: ordersTotal,
        topProducts: topProducts,
        paymentSummary: paymentSummary,
        itemSales: itemSales,
        itemSalesPage: 1,
        itemSalesTotal: itemSalesTotal,
        dailySales: dailySales,
        hourlySales: hourlySales,
        comparison: comparison,
      ));
    } catch (e) {
      emit(ReportError(e.toString()));
    }
  }

  Future<void> _onLoadMoreOrders(
      ReportLoadMoreOrders e, Emitter<ReportState> emit) async {
    final current = state;
    if (current is! ReportLoaded || !current.hasMoreOrders) return;
    final nextPage = current.ordersPage + 1;
    try {
      final more = await _dao.getOrders(
        startDate: current.startDate,
        endDate: current.endDate,
        limit: _pageSize,
        offset: (nextPage - 1) * _pageSize,
      );
      emit(ReportLoaded(
        startDate: current.startDate,
        endDate: current.endDate,
        totalOrders: current.totalOrders,
        totalRevenue: current.totalRevenue,
        totalDiscount: current.totalDiscount,
        orders: [...current.orders, ...more],
        ordersPage: nextPage,
        ordersTotal: current.ordersTotal,
        topProducts: current.topProducts,
        paymentSummary: current.paymentSummary,
        itemSales: current.itemSales,
        itemSalesPage: current.itemSalesPage,
        itemSalesTotal: current.itemSalesTotal,
        dailySales: current.dailySales,
        hourlySales: current.hourlySales,
        comparison: current.comparison,
      ));
    } catch (e) {
      emit(ReportError(e.toString()));
    }
  }

  Future<void> _onLoadMoreItems(
      ReportLoadMoreItems e, Emitter<ReportState> emit) async {
    final current = state;
    if (current is! ReportLoaded || !current.hasMoreItems) return;
    final nextPage = current.itemSalesPage + 1;
    try {
      final more = await _dao.getItemSales(
        startDate: current.startDate,
        endDate: current.endDate,
        limit: _pageSize,
        offset: (nextPage - 1) * _pageSize,
      );
      emit(ReportLoaded(
        startDate: current.startDate,
        endDate: current.endDate,
        totalOrders: current.totalOrders,
        totalRevenue: current.totalRevenue,
        totalDiscount: current.totalDiscount,
        orders: current.orders,
        ordersPage: current.ordersPage,
        ordersTotal: current.ordersTotal,
        topProducts: current.topProducts,
        paymentSummary: current.paymentSummary,
        itemSales: [...current.itemSales, ...more],
        itemSalesPage: nextPage,
        itemSalesTotal: current.itemSalesTotal,
        dailySales: current.dailySales,
        hourlySales: current.hourlySales,
        comparison: current.comparison,
      ));
    } catch (e) {
      emit(ReportError(e.toString()));
    }
  }
}
