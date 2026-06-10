import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/database/bundle_dao.dart';
import '../../../core/models/bundle.dart';
import '../../../core/models/bundle_item.dart';

// Events
abstract class BundleEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class BundleLoad extends BundleEvent {
  final String? search;
  BundleLoad({this.search});
  @override
  List<Object?> get props => [search];
}

class BundleLoadMore extends BundleEvent {
  final String? search;
  BundleLoadMore({this.search});
  @override
  List<Object?> get props => [search];
}

class BundleAdd extends BundleEvent {
  final Bundle bundle;
  final List<BundleItem> items;
  BundleAdd(this.bundle, this.items);
}

class BundleUpdate extends BundleEvent {
  final Bundle bundle;
  final List<BundleItem> items;
  BundleUpdate(this.bundle, this.items);
}

class BundleDelete extends BundleEvent {
  final int id;
  BundleDelete(this.id);
}

// States
abstract class BundleState extends Equatable {
  @override
  List<Object?> get props => [];
}

class BundleInitial extends BundleState {}
class BundleLoading extends BundleState {}
class BundleLoaded extends BundleState {
  final List<Bundle> bundles;
  final bool hasMore;
  final int offset;
  final String? search;
  BundleLoaded(this.bundles, {this.hasMore = true, this.offset = 0, this.search});
  @override
  List<Object?> get props => [bundles, hasMore, offset, search];
}
class BundleError extends BundleState {
  final String message;
  BundleError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class BundleBloc extends Bloc<BundleEvent, BundleState> {
  final BundleDao _dao;
  static const int _pageSize = 20;

  BundleBloc(this._dao) : super(BundleInitial()) {
    on<BundleLoad>(_onLoad);
    on<BundleLoadMore>(_onLoadMore);
    on<BundleAdd>(_onAdd);
    on<BundleUpdate>(_onUpdate);
    on<BundleDelete>(_onDelete);
  }

  Future<void> _onLoad(BundleLoad e, Emitter<BundleState> emit) async {
    emit(BundleLoading());
    final bundles = await _dao.getAllPaginated(
      search: e.search, limit: _pageSize, offset: 0);
    emit(BundleLoaded(bundles,
        hasMore: bundles.length == _pageSize, offset: 0, search: e.search));
  }

  Future<void> _onLoadMore(BundleLoadMore e, Emitter<BundleState> emit) async {
    if (state is! BundleLoaded) return;
    final current = state as BundleLoaded;
    if (!current.hasMore) return;
    final newOffset = current.offset + _pageSize;
    final moreBundles = await _dao.getAllPaginated(
      search: e.search ?? current.search, limit: _pageSize, offset: newOffset);
    emit(BundleLoaded([...current.bundles, ...moreBundles],
        hasMore: moreBundles.length == _pageSize,
        offset: newOffset,
        search: e.search ?? current.search));
  }

  Future<void> _onAdd(BundleAdd e, Emitter<BundleState> emit) async {
    final bundleId = await _dao.insert(e.bundle);
    for (final item in e.items) {
      await _dao.insertItem(item.copyWith(id: null, bundleId: bundleId));
    }
    add(BundleLoad());
  }

  Future<void> _onUpdate(BundleUpdate e, Emitter<BundleState> emit) async {
    await _dao.update(e.bundle);
    if (e.bundle.id != null) {
      await _dao.deleteItemsByBundle(e.bundle.id!);
      for (final item in e.items) {
        await _dao.insertItem(item.copyWith(id: null));
      }
    }
    add(BundleLoad());
  }

  Future<void> _onDelete(BundleDelete e, Emitter<BundleState> emit) async {
    await _dao.delete(e.id);
    add(BundleLoad());
  }
}
