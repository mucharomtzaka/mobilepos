import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/database/product_dao.dart';
import '../../../core/models/category.dart';
import '../../../core/models/product.dart';
import '../../../core/models/product_variant.dart';

// Events
abstract class ProductEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class ProductLoad extends ProductEvent {
  final int? categoryId;
  final String? search;
  ProductLoad({this.categoryId, this.search});
  @override
  List<Object?> get props => [categoryId, search];
}

class ProductLoadMore extends ProductEvent {
  final int? categoryId;
  final String? search;
  ProductLoadMore({this.categoryId, this.search});
  @override
  List<Object?> get props => [categoryId, search];
}

class ProductAdd extends ProductEvent {
  final Product product;
  final List<ProductVariant> variants;
  ProductAdd(this.product, {this.variants = const []});
}

class ProductUpdate extends ProductEvent {
  final Product product;
  final List<ProductVariant> variants;
  ProductUpdate(this.product, {this.variants = const []});
}

class ProductDelete extends ProductEvent {
  final int id;
  ProductDelete(this.id);
}

// States
abstract class ProductState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ProductInitial extends ProductState {}
class ProductLoading extends ProductState {}
class ProductLoaded extends ProductState {
  final List<Product> products;
  final List<Category> categories;
  final bool hasMore;
  final int offset;
  final int? categoryId;
  final String? search;
  ProductLoaded(this.products, this.categories,
      {this.hasMore = true, this.offset = 0, this.categoryId, this.search});
  @override
  List<Object?> get props => [products, categories, hasMore, offset, categoryId, search];
}
class ProductError extends ProductState {
  final String message;
  ProductError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductDao _productDao;
  final CategoryDao _categoryDao;
  static const int _pageSize = 20;

  ProductBloc(this._productDao, this._categoryDao) : super(ProductInitial()) {
    on<ProductLoad>(_onLoad);
    on<ProductLoadMore>(_onLoadMore);
    on<ProductAdd>(_onAdd);
    on<ProductUpdate>(_onUpdate);
    on<ProductDelete>(_onDelete);
  }

  Future<void> _onLoad(ProductLoad e, Emitter<ProductState> emit) async {
    emit(ProductLoading());
    final products = await _productDao.getAllPaginated(
        categoryId: e.categoryId, search: e.search, limit: _pageSize, offset: 0);
    final categories = await _categoryDao.getAll();
    final uniqueProducts = {...products}.toList();
    final uniqueCategories = {...categories}.toList();
    emit(ProductLoaded(
      uniqueProducts,
      uniqueCategories,
      hasMore: products.length == _pageSize,
      offset: 0,
      categoryId: e.categoryId,
      search: e.search,
    ));
  }

  Future<void> _onLoadMore(ProductLoadMore e, Emitter<ProductState> emit) async {
    if (state is! ProductLoaded) return;
    final current = state as ProductLoaded;
    if (!current.hasMore) return;
    final newOffset = current.offset + _pageSize;
    final moreProducts = await _productDao.getAllPaginated(
      categoryId: e.categoryId ?? current.categoryId,
      search: e.search ?? current.search,
      limit: _pageSize,
      offset: newOffset,
    );
    final uniqueProducts = {...current.products, ...moreProducts}.toList();
    emit(ProductLoaded(
      uniqueProducts,
      current.categories,
      hasMore: moreProducts.length == _pageSize,
      offset: newOffset,
      categoryId: e.categoryId ?? current.categoryId,
      search: e.search ?? current.search,
    ));
  }

  Future<void> _onAdd(ProductAdd e, Emitter<ProductState> emit) async {
    final productId = await _productDao.insert(e.product);
    for (final v in e.variants) {
      await _productDao.insertVariant(v.copyWith(id: null, productId: productId));
    }
    add(ProductLoad());
  }

  Future<void> _onUpdate(ProductUpdate e, Emitter<ProductState> emit) async {
    await _productDao.update(e.product);
    if (e.product.id != null) {
      await _productDao.deleteVariantsByProduct(e.product.id!);
      for (final v in e.variants) {
        await _productDao.insertVariant(v.copyWith(id: null));
      }
    }
    add(ProductLoad());
  }

  Future<void> _onDelete(ProductDelete e, Emitter<ProductState> emit) async {
    await _productDao.delete(e.id);
    add(ProductLoad());
  }
}
