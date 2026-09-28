import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:flutter/foundation.dart';

/// Résultat d'une opération : soit un succès ([Ok]), soit un échec ([Err]).
///
/// Utilisé par tous les repositories à la place des exceptions :
/// l'appelant est obligé de traiter le cas d'échec.
///
/// ```dart
/// switch (result) {
///   case Ok(:final value):
///     // succès
///   case Err(:final failure):
///     // échec
/// }
/// ```
@immutable
sealed class Result<T> {
  const new();

  bool get isOk => this is Ok<T>;
  bool get isErr => this is Err<T>;

  /// Réduit le résultat à une seule valeur, en traitant les deux cas.
  R fold<R>({
    required R Function(T value) onOk,
    required R Function(Failure failure) onErr,
  }) {
    return switch (this) {
      Ok<T>(:final value) => onOk(value),
      Err<T>(:final failure) => onErr(failure),
    };
  }

  /// Transforme la valeur en cas de succès ; conserve l'échec sinon.
  Result<U> map<U>(U Function(T value) transform) {
    return switch (this) {
      Ok<T>(:final value) => Ok<U>(transform(value)),
      Err<T>(:final failure) => Err<U>(failure),
    };
  }
}

/// Succès, avec sa valeur.
final class Ok<T> extends Result<T> {
  const new(this.value);

  final T value;
}

/// Échec, avec sa [Failure].
final class Err<T> extends Result<T> {
  const new(this.failure);

  final Failure failure;
}
