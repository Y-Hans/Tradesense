// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'progress_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$MistakePattern {
  String get name => throw _privateConstructorUsedError;
  int get frequency => throw _privateConstructorUsedError;
  double get impactCost => throw _privateConstructorUsedError;

  /// Create a copy of MistakePattern
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MistakePatternCopyWith<MistakePattern> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MistakePatternCopyWith<$Res> {
  factory $MistakePatternCopyWith(
          MistakePattern value, $Res Function(MistakePattern) then) =
      _$MistakePatternCopyWithImpl<$Res, MistakePattern>;
  @useResult
  $Res call({String name, int frequency, double impactCost});
}

/// @nodoc
class _$MistakePatternCopyWithImpl<$Res, $Val extends MistakePattern>
    implements $MistakePatternCopyWith<$Res> {
  _$MistakePatternCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MistakePattern
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? frequency = null,
    Object? impactCost = null,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      frequency: null == frequency
          ? _value.frequency
          : frequency // ignore: cast_nullable_to_non_nullable
              as int,
      impactCost: null == impactCost
          ? _value.impactCost
          : impactCost // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MistakePatternImplCopyWith<$Res>
    implements $MistakePatternCopyWith<$Res> {
  factory _$$MistakePatternImplCopyWith(_$MistakePatternImpl value,
          $Res Function(_$MistakePatternImpl) then) =
      __$$MistakePatternImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String name, int frequency, double impactCost});
}

/// @nodoc
class __$$MistakePatternImplCopyWithImpl<$Res>
    extends _$MistakePatternCopyWithImpl<$Res, _$MistakePatternImpl>
    implements _$$MistakePatternImplCopyWith<$Res> {
  __$$MistakePatternImplCopyWithImpl(
      _$MistakePatternImpl _value, $Res Function(_$MistakePatternImpl) _then)
      : super(_value, _then);

  /// Create a copy of MistakePattern
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? frequency = null,
    Object? impactCost = null,
  }) {
    return _then(_$MistakePatternImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      frequency: null == frequency
          ? _value.frequency
          : frequency // ignore: cast_nullable_to_non_nullable
              as int,
      impactCost: null == impactCost
          ? _value.impactCost
          : impactCost // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc

class _$MistakePatternImpl implements _MistakePattern {
  const _$MistakePatternImpl(
      {required this.name, required this.frequency, required this.impactCost});

  @override
  final String name;
  @override
  final int frequency;
  @override
  final double impactCost;

  @override
  String toString() {
    return 'MistakePattern(name: $name, frequency: $frequency, impactCost: $impactCost)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MistakePatternImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.frequency, frequency) ||
                other.frequency == frequency) &&
            (identical(other.impactCost, impactCost) ||
                other.impactCost == impactCost));
  }

  @override
  int get hashCode => Object.hash(runtimeType, name, frequency, impactCost);

  /// Create a copy of MistakePattern
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MistakePatternImplCopyWith<_$MistakePatternImpl> get copyWith =>
      __$$MistakePatternImplCopyWithImpl<_$MistakePatternImpl>(
          this, _$identity);
}

abstract class _MistakePattern implements MistakePattern {
  const factory _MistakePattern(
      {required final String name,
      required final int frequency,
      required final double impactCost}) = _$MistakePatternImpl;

  @override
  String get name;
  @override
  int get frequency;
  @override
  double get impactCost;

  /// Create a copy of MistakePattern
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MistakePatternImplCopyWith<_$MistakePatternImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$ProgressState {
  bool get isLoading => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;
  int get overallDisciplineScore => throw _privateConstructorUsedError;
  int get winRatePercentage => throw _privateConstructorUsedError;
  double get profitFactor => throw _privateConstructorUsedError;
  List<MistakePattern> get topMistakes => throw _privateConstructorUsedError;

  /// Create a copy of ProgressState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProgressStateCopyWith<ProgressState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProgressStateCopyWith<$Res> {
  factory $ProgressStateCopyWith(
          ProgressState value, $Res Function(ProgressState) then) =
      _$ProgressStateCopyWithImpl<$Res, ProgressState>;
  @useResult
  $Res call(
      {bool isLoading,
      String? error,
      int overallDisciplineScore,
      int winRatePercentage,
      double profitFactor,
      List<MistakePattern> topMistakes});
}

/// @nodoc
class _$ProgressStateCopyWithImpl<$Res, $Val extends ProgressState>
    implements $ProgressStateCopyWith<$Res> {
  _$ProgressStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProgressState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? error = freezed,
    Object? overallDisciplineScore = null,
    Object? winRatePercentage = null,
    Object? profitFactor = null,
    Object? topMistakes = null,
  }) {
    return _then(_value.copyWith(
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      overallDisciplineScore: null == overallDisciplineScore
          ? _value.overallDisciplineScore
          : overallDisciplineScore // ignore: cast_nullable_to_non_nullable
              as int,
      winRatePercentage: null == winRatePercentage
          ? _value.winRatePercentage
          : winRatePercentage // ignore: cast_nullable_to_non_nullable
              as int,
      profitFactor: null == profitFactor
          ? _value.profitFactor
          : profitFactor // ignore: cast_nullable_to_non_nullable
              as double,
      topMistakes: null == topMistakes
          ? _value.topMistakes
          : topMistakes // ignore: cast_nullable_to_non_nullable
              as List<MistakePattern>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProgressStateImplCopyWith<$Res>
    implements $ProgressStateCopyWith<$Res> {
  factory _$$ProgressStateImplCopyWith(
          _$ProgressStateImpl value, $Res Function(_$ProgressStateImpl) then) =
      __$$ProgressStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool isLoading,
      String? error,
      int overallDisciplineScore,
      int winRatePercentage,
      double profitFactor,
      List<MistakePattern> topMistakes});
}

/// @nodoc
class __$$ProgressStateImplCopyWithImpl<$Res>
    extends _$ProgressStateCopyWithImpl<$Res, _$ProgressStateImpl>
    implements _$$ProgressStateImplCopyWith<$Res> {
  __$$ProgressStateImplCopyWithImpl(
      _$ProgressStateImpl _value, $Res Function(_$ProgressStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProgressState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? error = freezed,
    Object? overallDisciplineScore = null,
    Object? winRatePercentage = null,
    Object? profitFactor = null,
    Object? topMistakes = null,
  }) {
    return _then(_$ProgressStateImpl(
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      overallDisciplineScore: null == overallDisciplineScore
          ? _value.overallDisciplineScore
          : overallDisciplineScore // ignore: cast_nullable_to_non_nullable
              as int,
      winRatePercentage: null == winRatePercentage
          ? _value.winRatePercentage
          : winRatePercentage // ignore: cast_nullable_to_non_nullable
              as int,
      profitFactor: null == profitFactor
          ? _value.profitFactor
          : profitFactor // ignore: cast_nullable_to_non_nullable
              as double,
      topMistakes: null == topMistakes
          ? _value._topMistakes
          : topMistakes // ignore: cast_nullable_to_non_nullable
              as List<MistakePattern>,
    ));
  }
}

/// @nodoc

class _$ProgressStateImpl implements _ProgressState {
  const _$ProgressStateImpl(
      {this.isLoading = true,
      this.error,
      this.overallDisciplineScore = 0,
      this.winRatePercentage = 0,
      this.profitFactor = 0.0,
      final List<MistakePattern> topMistakes = const []})
      : _topMistakes = topMistakes;

  @override
  @JsonKey()
  final bool isLoading;
  @override
  final String? error;
  @override
  @JsonKey()
  final int overallDisciplineScore;
  @override
  @JsonKey()
  final int winRatePercentage;
  @override
  @JsonKey()
  final double profitFactor;
  final List<MistakePattern> _topMistakes;
  @override
  @JsonKey()
  List<MistakePattern> get topMistakes {
    if (_topMistakes is EqualUnmodifiableListView) return _topMistakes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_topMistakes);
  }

  @override
  String toString() {
    return 'ProgressState(isLoading: $isLoading, error: $error, overallDisciplineScore: $overallDisciplineScore, winRatePercentage: $winRatePercentage, profitFactor: $profitFactor, topMistakes: $topMistakes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProgressStateImpl &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.overallDisciplineScore, overallDisciplineScore) ||
                other.overallDisciplineScore == overallDisciplineScore) &&
            (identical(other.winRatePercentage, winRatePercentage) ||
                other.winRatePercentage == winRatePercentage) &&
            (identical(other.profitFactor, profitFactor) ||
                other.profitFactor == profitFactor) &&
            const DeepCollectionEquality()
                .equals(other._topMistakes, _topMistakes));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      isLoading,
      error,
      overallDisciplineScore,
      winRatePercentage,
      profitFactor,
      const DeepCollectionEquality().hash(_topMistakes));

  /// Create a copy of ProgressState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProgressStateImplCopyWith<_$ProgressStateImpl> get copyWith =>
      __$$ProgressStateImplCopyWithImpl<_$ProgressStateImpl>(this, _$identity);
}

abstract class _ProgressState implements ProgressState {
  const factory _ProgressState(
      {final bool isLoading,
      final String? error,
      final int overallDisciplineScore,
      final int winRatePercentage,
      final double profitFactor,
      final List<MistakePattern> topMistakes}) = _$ProgressStateImpl;

  @override
  bool get isLoading;
  @override
  String? get error;
  @override
  int get overallDisciplineScore;
  @override
  int get winRatePercentage;
  @override
  double get profitFactor;
  @override
  List<MistakePattern> get topMistakes;

  /// Create a copy of ProgressState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProgressStateImplCopyWith<_$ProgressStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
