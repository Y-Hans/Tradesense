// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'journal_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$Trade {
  String get id => throw _privateConstructorUsedError;
  String get symbol => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError; // e.g. Long, Short
  double get pnl => throw _privateConstructorUsedError;
  DateTime get date => throw _privateConstructorUsedError;
  List<String> get tags => throw _privateConstructorUsedError;
  bool get aiReviewed => throw _privateConstructorUsedError;

  /// Create a copy of Trade
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TradeCopyWith<Trade> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TradeCopyWith<$Res> {
  factory $TradeCopyWith(Trade value, $Res Function(Trade) then) =
      _$TradeCopyWithImpl<$Res, Trade>;
  @useResult
  $Res call(
      {String id,
      String symbol,
      String type,
      double pnl,
      DateTime date,
      List<String> tags,
      bool aiReviewed});
}

/// @nodoc
class _$TradeCopyWithImpl<$Res, $Val extends Trade>
    implements $TradeCopyWith<$Res> {
  _$TradeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Trade
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? symbol = null,
    Object? type = null,
    Object? pnl = null,
    Object? date = null,
    Object? tags = null,
    Object? aiReviewed = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      symbol: null == symbol
          ? _value.symbol
          : symbol // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      pnl: null == pnl
          ? _value.pnl
          : pnl // ignore: cast_nullable_to_non_nullable
              as double,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      tags: null == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      aiReviewed: null == aiReviewed
          ? _value.aiReviewed
          : aiReviewed // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TradeImplCopyWith<$Res> implements $TradeCopyWith<$Res> {
  factory _$$TradeImplCopyWith(
          _$TradeImpl value, $Res Function(_$TradeImpl) then) =
      __$$TradeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String symbol,
      String type,
      double pnl,
      DateTime date,
      List<String> tags,
      bool aiReviewed});
}

/// @nodoc
class __$$TradeImplCopyWithImpl<$Res>
    extends _$TradeCopyWithImpl<$Res, _$TradeImpl>
    implements _$$TradeImplCopyWith<$Res> {
  __$$TradeImplCopyWithImpl(
      _$TradeImpl _value, $Res Function(_$TradeImpl) _then)
      : super(_value, _then);

  /// Create a copy of Trade
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? symbol = null,
    Object? type = null,
    Object? pnl = null,
    Object? date = null,
    Object? tags = null,
    Object? aiReviewed = null,
  }) {
    return _then(_$TradeImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      symbol: null == symbol
          ? _value.symbol
          : symbol // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      pnl: null == pnl
          ? _value.pnl
          : pnl // ignore: cast_nullable_to_non_nullable
              as double,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      tags: null == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      aiReviewed: null == aiReviewed
          ? _value.aiReviewed
          : aiReviewed // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$TradeImpl implements _Trade {
  const _$TradeImpl(
      {required this.id,
      required this.symbol,
      required this.type,
      required this.pnl,
      required this.date,
      required final List<String> tags,
      this.aiReviewed = false})
      : _tags = tags;

  @override
  final String id;
  @override
  final String symbol;
  @override
  final String type;
// e.g. Long, Short
  @override
  final double pnl;
  @override
  final DateTime date;
  final List<String> _tags;
  @override
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  @override
  @JsonKey()
  final bool aiReviewed;

  @override
  String toString() {
    return 'Trade(id: $id, symbol: $symbol, type: $type, pnl: $pnl, date: $date, tags: $tags, aiReviewed: $aiReviewed)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TradeImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.symbol, symbol) || other.symbol == symbol) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.pnl, pnl) || other.pnl == pnl) &&
            (identical(other.date, date) || other.date == date) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.aiReviewed, aiReviewed) ||
                other.aiReviewed == aiReviewed));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, symbol, type, pnl, date,
      const DeepCollectionEquality().hash(_tags), aiReviewed);

  /// Create a copy of Trade
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TradeImplCopyWith<_$TradeImpl> get copyWith =>
      __$$TradeImplCopyWithImpl<_$TradeImpl>(this, _$identity);
}

abstract class _Trade implements Trade {
  const factory _Trade(
      {required final String id,
      required final String symbol,
      required final String type,
      required final double pnl,
      required final DateTime date,
      required final List<String> tags,
      final bool aiReviewed}) = _$TradeImpl;

  @override
  String get id;
  @override
  String get symbol;
  @override
  String get type; // e.g. Long, Short
  @override
  double get pnl;
  @override
  DateTime get date;
  @override
  List<String> get tags;
  @override
  bool get aiReviewed;

  /// Create a copy of Trade
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TradeImplCopyWith<_$TradeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$JournalState {
  bool get isLoading => throw _privateConstructorUsedError;
  bool get isOffline => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;
  List<Trade> get trades => throw _privateConstructorUsedError;

  /// Create a copy of JournalState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $JournalStateCopyWith<JournalState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $JournalStateCopyWith<$Res> {
  factory $JournalStateCopyWith(
          JournalState value, $Res Function(JournalState) then) =
      _$JournalStateCopyWithImpl<$Res, JournalState>;
  @useResult
  $Res call(
      {bool isLoading, bool isOffline, String? error, List<Trade> trades});
}

/// @nodoc
class _$JournalStateCopyWithImpl<$Res, $Val extends JournalState>
    implements $JournalStateCopyWith<$Res> {
  _$JournalStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of JournalState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? isOffline = null,
    Object? error = freezed,
    Object? trades = null,
  }) {
    return _then(_value.copyWith(
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isOffline: null == isOffline
          ? _value.isOffline
          : isOffline // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      trades: null == trades
          ? _value.trades
          : trades // ignore: cast_nullable_to_non_nullable
              as List<Trade>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$JournalStateImplCopyWith<$Res>
    implements $JournalStateCopyWith<$Res> {
  factory _$$JournalStateImplCopyWith(
          _$JournalStateImpl value, $Res Function(_$JournalStateImpl) then) =
      __$$JournalStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool isLoading, bool isOffline, String? error, List<Trade> trades});
}

/// @nodoc
class __$$JournalStateImplCopyWithImpl<$Res>
    extends _$JournalStateCopyWithImpl<$Res, _$JournalStateImpl>
    implements _$$JournalStateImplCopyWith<$Res> {
  __$$JournalStateImplCopyWithImpl(
      _$JournalStateImpl _value, $Res Function(_$JournalStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of JournalState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? isOffline = null,
    Object? error = freezed,
    Object? trades = null,
  }) {
    return _then(_$JournalStateImpl(
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isOffline: null == isOffline
          ? _value.isOffline
          : isOffline // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      trades: null == trades
          ? _value._trades
          : trades // ignore: cast_nullable_to_non_nullable
              as List<Trade>,
    ));
  }
}

/// @nodoc

class _$JournalStateImpl implements _JournalState {
  const _$JournalStateImpl(
      {this.isLoading = true,
      this.isOffline = false,
      this.error,
      final List<Trade> trades = const []})
      : _trades = trades;

  @override
  @JsonKey()
  final bool isLoading;
  @override
  @JsonKey()
  final bool isOffline;
  @override
  final String? error;
  final List<Trade> _trades;
  @override
  @JsonKey()
  List<Trade> get trades {
    if (_trades is EqualUnmodifiableListView) return _trades;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_trades);
  }

  @override
  String toString() {
    return 'JournalState(isLoading: $isLoading, isOffline: $isOffline, error: $error, trades: $trades)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$JournalStateImpl &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.isOffline, isOffline) ||
                other.isOffline == isOffline) &&
            (identical(other.error, error) || other.error == error) &&
            const DeepCollectionEquality().equals(other._trades, _trades));
  }

  @override
  int get hashCode => Object.hash(runtimeType, isLoading, isOffline, error,
      const DeepCollectionEquality().hash(_trades));

  /// Create a copy of JournalState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$JournalStateImplCopyWith<_$JournalStateImpl> get copyWith =>
      __$$JournalStateImplCopyWithImpl<_$JournalStateImpl>(this, _$identity);
}

abstract class _JournalState implements JournalState {
  const factory _JournalState(
      {final bool isLoading,
      final bool isOffline,
      final String? error,
      final List<Trade> trades}) = _$JournalStateImpl;

  @override
  bool get isLoading;
  @override
  bool get isOffline;
  @override
  String? get error;
  @override
  List<Trade> get trades;

  /// Create a copy of JournalState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$JournalStateImplCopyWith<_$JournalStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
