import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/features/favorites/data/datasources/favorites_remote_datasource.dart';
import 'package:afrimarket_mobile/features/favorites/data/repositories/favorites_repository_impl.dart';
import 'package:afrimarket_mobile/features/favorites/domain/usecases/set_favorite_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_http_server.dart';

void main() {
  late FakeHttpServer server;
  late FavoritesRepositoryImpl repository;

  setUp(() {
    server = FakeHttpServer();
    repository = FavoritesRepositoryImpl(
      FavoritesRemoteDataSource(server.client()),
    );
  });

  test('statut : GET /api/favorites/check/:id', () async {
    server.respond([
      (200, {'isFavorite': true}),
    ]);

    final result = await repository.isFavorite('l1');

    expect(server.requests.single.path, '/api/favorites/check/l1');
    expect((result as Ok<bool>).value, isTrue);
  });

  test('enregistrer : POST /api/favorites', () async {
    server.respond([
      (201, {'message': 'ok'}),
    ]);

    final result = await SetFavoriteUseCase(repository)('l1', saved: true);

    final request = server.requests.single;
    expect(request.method, 'POST');
    expect(request.path, '/api/favorites');
    expect(request.data, {'listingId': 'l1'});
    expect(result.isOk, isTrue);
  });

  test('déjà enregistrée (400) : réussi', () async {
    server.respond([
      (400, {'error': 'Déjà dans vos favoris'}),
    ]);

    expect((await repository.add('l1')).isOk, isTrue);
  });

  test('retirer : DELETE ; déjà retirée (404) : réussi', () async {
    server.respond([
      (404, {'error': 'Favori non trouvé'}),
    ]);

    final result = await SetFavoriteUseCase(repository)('l1', saved: false);

    expect(server.requests.single.method, 'DELETE');
    expect(server.requests.single.path, '/api/favorites/l1');
    expect(result.isOk, isTrue);
  });

  test('hors ligne côté serveur (500) : ServerFailure', () async {
    server.respond([
      (500, {'error': 'Internal'}),
    ]);

    final result = await repository.add('l1');

    expect((result as Err).failure, isA<ServerFailure>());
  });
}
