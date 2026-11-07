import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/features/messaging/data/models/messaging_json.dart';
import 'package:afrimarket_mobile/features/safety/data/datasources/safety_remote_datasource.dart';
import 'package:afrimarket_mobile/features/safety/data/repositories/safety_repository_impl.dart';
import 'package:afrimarket_mobile/features/safety/domain/entities/blocked_person.dart';
import 'package:afrimarket_mobile/features/safety/domain/entities/person_report_reason.dart';
import 'package:afrimarket_mobile/features/safety/domain/safety_conflicts.dart';
import 'package:afrimarket_mobile/features/safety/domain/usecases/safety_usecases.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_http_server.dart';

void main() {
  late FakeHttpServer server;
  late SafetyUseCases safety;

  setUp(() {
    server = FakeHttpServer();
    safety = SafetyUseCases(
      SafetyRepositoryImpl(SafetyRemoteDataSource(server.client())),
    );
  });

  test('liste : lue prudemment (identifiants, dates, adresses)', () async {
    server.respond([
      (
        200,
        {
          'blocks': [
            {
              'userId': 'u1',
              'name': ' Youssef B. ',
              'avatar': '/uploads/u1.jpg',
              'blockedAt': '2026-11-07T10:00:00.000Z',
            },
            {
              'userId': 'u2',
              'name': null,
              'avatar': 'javascript:alert(1)',
              'blockedAt': '2026-11-06T10:00:00.000Z',
            },
            {'userId': '../x', 'blockedAt': '2026-11-06T10:00:00.000Z'},
            {'userId': 'u3'},
            'texte',
          ],
        },
      ),
    ]);

    final result = await safety.blockedPeople();

    expect(server.requests.single.path, '/api/users/me/blocks');
    final people = (result as Ok<List<BlockedPerson>>).value;
    expect(people.map((p) => p.userId), ['u1', 'u2']);
    expect(people.first.name, 'Youssef B.');
    expect(people.first.avatarUrl, 'https://api.example.com/uploads/u1.jpg');
    expect(people.first.blockedAt, DateTime.utc(2026, 11, 7, 10));
    expect(people.last.name, isNull);
    expect(people.last.avatarUrl, isNull);
  });

  test('réponse sans liste : UnexpectedFailure', () async {
    server.respond([
      (200, {'items': <Object>[]}),
    ]);

    final result = await safety.blockedPeople();

    expect((result as Err).failure, isA<UnexpectedFailure>());
  });

  test('bloquer, débloquer : bonnes routes', () async {
    server.respond([
      (201, {'blocked': true}),
      (204, null),
    ]);

    expect((await safety.block('u1')).isOk, isTrue);
    expect((await safety.unblock('u_1')).isOk, isTrue);

    expect(server.requests.map((r) => '${r.method} ${r.path}'), [
      'POST /api/users/me/blocks',
      'DELETE /api/users/me/blocks/u_1',
    ]);
    expect(server.requests.first.data, {'userId': 'u1'});
  });

  test('signaler : motif, détail nettoyé, discussion', () async {
    server.respond([
      (201, {'reported': true}),
    ]);

    await safety.report(
      userId: 'u1',
      reason: PersonReportReason.harassment,
      details: '  Insultes répétées  ',
      conversationId: 'c1',
    );

    final request = server.requests.single;
    expect(request.method, 'POST');
    expect(request.path, '/api/users/u1/report');
    expect(request.data, {
      'reason': 'HARASSMENT',
      'details': 'Insultes répétées',
      'conversationId': 'c1',
    });
  });

  test('signaler sans détail ni discussion : champs absents', () async {
    server.respond([
      (201, {'reported': true}),
    ]);

    await safety.report(userId: 'u1', reason: PersonReportReason.spam);

    expect(server.requests.single.data, {'reason': 'SPAM'});
  });

  test('déjà signalée : ConflictFailure avec son code', () async {
    server.respond([
      (409, {'error': 'Already reported', 'code': 'ALREADY_REPORTED'}),
    ]);

    final result = await safety.report(
      userId: 'u1',
      reason: PersonReportReason.scam,
    );

    expect(
      (result as Err).failure,
      isA<ConflictFailure>().having(
        (f) => f.code,
        'code',
        SafetyConflicts.alreadyReported,
      ),
    );
  });

  test('discussion : « bloquée par moi » lu, faux par défaut', () {
    final base = Uri.parse('https://api.example.com');
    Map<String, dynamic> json({Object? blockedByMe}) => {
      'id': 'c1',
      'role': 'buying',
      'otherUser': {'id': 'u1', 'name': 'Aminata', 'canReceiveMessages': false},
      'blockedByMe': ?blockedByMe,
    };

    expect(
      MessagingJson.conversation(json(blockedByMe: true), base)!.blockedByMe,
      isTrue,
    );
    expect(
      MessagingJson.conversation(json(blockedByMe: 'oui'), base)!.blockedByMe,
      isFalse,
    );
    expect(MessagingJson.conversation(json(), base)!.blockedByMe, isFalse);
  });
}
