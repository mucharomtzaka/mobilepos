import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/database/product_dao.dart';
import '../../../core/database/stock_dao.dart';
import '../../../core/models/product.dart';
import '../../../core/models/stock_movement.dart';

// Events
abstract class StockEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class StockLoad extends StockEvent {}
class StockAdjust extends StockEvent {
  final int productId;
  final String type; // in | out | adjustment
  final int qty;
  final String? note;
  StockAdjust({
    required this.productId,
    required this.type,
    required this.qty,
    this.note,
  });
  @override
  List<Object?> get props => [productId, type, qty];
}

class StockLoadMovements extends StockEvent {
  final int productId;
  StockLoadMovements(this.productId);
}

// States
abstract class StockState extends Equatable {
  @override
  List<Object?> get props => [];
}

class StockInitial extends StockState {}
class StockLoading extends StockState {}
class StockLoaded extends StockState {
  final List<Product> products;
  final List<Product> lowStockProducts;
  StockLoaded(this.products, this.lowStockProducts);
  @override
  List<Object?> get props => [products, lowStockProducts];
}
class StockMovementsLoaded extends StockState {
  final List<StockMovement> movements;
  StockMovementsLoaded(this.movements);
  @override
  List<Object?> get props => [movements];
}

// BLoC
class StockBloc extends Bloc<StockEvent, StockState> {
  final ProductDao _productDao;
  final StockDao _stockDao;

  StockBloc(this._productDao, this._stockDao) : super(StockInitial()) {
    on<StockLoad>(_onLoad);
    on<StockAdjust>(_onAdjust);
    on<StockLoadMovements>(_onLoadMovements);
  }

  Future<void> _onLoad(StockLoad e, Emitter<StockState> emit) async {
    emit(StockLoading());
    final products = await _productDao.getAll();
    final lowStock = products.where((p) => p.stock <= 5).toList();
    emit(StockLoaded(products, lowStock));
  }

  Future<void> _onAdjust(StockAdjust e, Emitter<StockState> emit) async {
    await _stockDao.addMovement(StockMovement(
      productId: e.productId,
      type: e.type,
      qty: e.qty,
      note: e.note,
      createdAt: DateTime.now().toIso8601String(),
    ));
    add(StockLoad());
  }

  Future<void> _onLoadMovements(
      StockLoadMovements e, Emitter<StockState> emit) async {
    final movements = await _stockDao.getByProduct(e.productId);
    emit(StockMovementsLoaded(movements));
  }
}
