import 'dart:convert';
import 'dart:typed_data';

import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/features/listings/data/datasources/listings_remote_datasource.dart';
import 'package:afrimarket_mobile/features/listings/data/repositories/listings_repository_impl.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_category.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_detail.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_locations.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_page.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_summary.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/report_reason.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/seller_contact.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Faux backend : réponse configurable, mémorise la dernière requête.
class _FakeServer implements HttpClientAdapter {
  int status = 200;
  Object body = <String, dynamic>{};
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _FakeServer server;
  late ListingsRepositoryImpl repository;

  setUp(() {
    server = _FakeServer();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'))
      ..httpClientAdapter = server;
    repository = ListingsRepositoryImpl(ListingsRemoteDataSource(dio));
  });

  group('Fil', () {
    test('GET /api/listings avec page, taille et catégorie', () async {
      server.body = {
        'listings': [
          {
            'id': 'l1',
            'title': 'Lit',
            'price': 700,
            'createdAt': '2026-10-18T08:00:00Z',
            'images': [
              {'url': '/uploads/l1.jpg'},
            ],
          },
        ],
        'pagination': {'page': 2, 'pages': 3},
      };

      final result = await repository.fetchFeed(page: 2, categoryId: 'c1');

      final request = server.lastRequest!;
      expect(request.method, 'GET');
      expect(request.path, '/api/listings');
      expect(request.queryParameters, {
        'page': 2,
        'limit': ListingsRepositoryImpl.pageSize,
        'categoryId': 'c1',
      });
      final page = (result as Ok<ListingPage>).value;
      expect(page.page, 2);
      expect(page.hasMore, isTrue);
      expect(
        page.items.single.imageUrl,
        'https://api.example.com/uploads/l1.jpg',
      );
    });

    test('sans catégorie : paramètre absent', () async {
      server.body = {'listings': <Object>[], 'pagination': <String, dynamic>{}};

      await repository.fetchFeed(page: 1);

      expect(
        server.lastRequest!.queryParameters.containsKey('categoryId'),
        isFalse,
      );
    });

    test('erreur serveur : ServerFailure', () async {
      server
        ..status = 500
        ..body = {'error': 'Internal'};

      final result = await repository.fetchFeed(page: 1);

      expect((result as Err).failure, isA<ServerFailure>());
    });

    test(
      'réponse inattendue : UnexpectedFailure, jamais de plantage',
      () async {
        server.body = {'autre': 'chose'};

        final result = await repository.fetchFeed(page: 1);

        expect((result as Err).failure, isA<UnexpectedFailure>());
      },
    );
  });

  group('Catégories', () {
    test('GET /api/filters', () async {
      server.body = {
        'data': {
          'categories': [
            {'id': 'c1', 'name': 'Logement'},
          ],
        },
      };

      final result = await repository.fetchCategories();

      expect(server.lastRequest!.path, '/api/filters');
      expect((result as Ok<List<ListingCategory>>).value, const [
        ListingCategory(id: 'c1', name: 'Logement'),
      ]);
    });

    test('trop de requêtes : RateLimitFailure', () async {
      server
        ..status = 429
        ..body = {'error': 'Too many'};

      final result = await repository.fetchCategories();

      expect((result as Err).failure, isA<RateLimitFailure>());
    });
  });

  group('Détail', () {
    test('GET /api/listings/:id (identifiant encodé)', () async {
      server.body = {
        'listing': {
          'id': 'l1',
          'title': 'Lit',
          'price': 700,
          'createdAt': '2026-10-18T08:00:00Z',
          'user': {'id': 'u1', 'username': 'aminata'},
        },
      };

      final result = await repository.fetchListing('l1');

      expect(server.lastRequest!.path, '/api/listings/l1');
      expect((result as Ok<ListingDetail>).value.seller.name, 'aminata');
    });

    test('annonce introuvable : NotFoundFailure', () async {
      server
        ..status = 404
        ..body = {'error': 'Listing not found'};

      final result = await repository.fetchListing('nope');

      expect((result as Err).failure, isA<NotFoundFailure>());
    });

    test('annonces similaires', () async {
      server.body = {
        'listings': [
          {
            'id': 'l2',
            'title': 'Table',
            'price': 400,
            'createdAt': '2026-10-18T08:00:00Z',
          },
        ],
      };

      final result = await repository.fetchSimilar('l1');

      expect(server.lastRequest!.path, '/api/listings/l1/similar');
      expect((result as Ok<List<ListingSummary>>).value.single.id, 'l2');
    });

    test('lieux : GET /api/filters', () async {
      server.body = {
        'data': {
          'locations': [
            {
              'slug': 'casablanca',
              'name': 'Casablanca',
              'districts': [
                {'slug': 'maarif', 'name': 'Maârif'},
              ],
            },
          ],
        },
      };

      final result = await repository.fetchLocations();

      final locations = (result as Ok<ListingLocations>).value;
      expect(
        locations.label(city: 'casablanca', district: 'maarif'),
        'Maârif, Casablanca',
      );
    });
  });

  group('Contact et signalement', () {
    test('numéro du vendeur', () async {
      server.body = {'phone': '+212612345678', 'whatsapp': true};

      final result = await repository.fetchSellerContact('l1');

      expect(server.lastRequest!.path, '/api/listings/l1/contact');
      expect(
        (result as Ok<SellerContact>).value,
        const SellerContact(phone: '+212612345678', whatsapp: true),
      );
    });

    test('numéro non partagé : NotFoundFailure', () async {
      server
        ..status = 404
        ..body = {'error': 'Contact not available'};

      final result = await repository.fetchSellerContact('l1');

      expect((result as Err).failure, isA<NotFoundFailure>());
    });

    test('signalement : POST avec motif et détail', () async {
      server
        ..status = 201
        ..body = {'message': 'Report received'};

      final result = await repository.reportListing(
        id: 'l1',
        reason: ReportReason.scam,
        details: 'Demande un virement',
      );

      final request = server.lastRequest!;
      expect(request.method, 'POST');
      expect(request.path, '/api/listings/l1/report');
      expect(request.data, {
        'reason': 'SCAM',
        'details': 'Demande un virement',
      });
      expect(result.isOk, isTrue);
    });

    test('déjà signalée (409) : réussi', () async {
      server
        ..status = 409
        ..body = {'error': 'Listing already reported'};

      final result = await repository.reportListing(
        id: 'l1',
        reason: ReportReason.spam,
      );

      expect(result.isOk, isTrue);
      expect(server.lastRequest!.data, {'reason': 'SPAM'});
    });

    test('sans connexion (401) : UnauthorizedFailure', () async {
      server
        ..status = 401
        ..body = {'error': 'Unauthorized'};

      final result = await repository.reportListing(
        id: 'l1',
        reason: ReportReason.other,
      );

      expect((result as Err).failure, isA<UnauthorizedFailure>());
    });
  });
}
