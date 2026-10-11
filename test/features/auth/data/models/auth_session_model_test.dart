import 'package:afrimarket_mobile/features/auth/data/models/auth_session_model.dart';
import 'package:afrimarket_mobile/features/auth/domain/entities/auth_user.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _json() => {
  'message': 'Login successful',
  'user': {
    'id': 'u1',
    'email': 'awa@example.com',
    'username': 'awa',
    'fullName': 'Awa Traoré',
  },
  'accessToken': 'ACCESS',
  'refreshToken': 'REFRESH',
  'accessTokenExpiresIn': 900,
};

void main() {
  test('lit la réponse de connexion', () {
    final model = AuthSessionModel.fromJson(_json());

    expect(model.accessToken, 'ACCESS');
    expect(model.refreshToken, 'REFRESH');
    expect(
      model.user,
      const AuthUser(
        id: 'u1',
        email: 'awa@example.com',
        username: 'awa',
        fullName: 'Awa Traoré',
      ),
    );
  });

  test('nom complet vide accepté', () {
    final json = _json();
    (json['user'] as Map<String, dynamic>)['fullName'] = '';

    expect(AuthSessionModel.fromJson(json).user.fullName, isEmpty);
  });

  test('toString ne révèle jamais les tokens', () {
    final text = AuthSessionModel.fromJson(_json()).toString();

    expect(text, isNot(contains('ACCESS')));
    expect(text, isNot(contains('REFRESH')));
  });

  group('réponse invalide : FormatException', () {
    final cases = <String, void Function(Map<String, dynamic>)>{
      'user absent': (json) => json.remove('user'),
      'user non objet': (json) => json['user'] = 'awa',
      'accessToken absent': (json) => json.remove('accessToken'),
      'accessToken vide': (json) => json['accessToken'] = '',
      'refreshToken non texte': (json) => json['refreshToken'] = 42,
      'id absent': (json) =>
          (json['user'] as Map<String, dynamic>).remove('id'),
    };

    for (final MapEntry(key: name, value: mutate) in cases.entries) {
      test(name, () {
        final json = _json();
        mutate(json);

        expect(
          () => AuthSessionModel.fromJson(json),
          throwsA(isA<FormatException>()),
        );
      });
    }
  });
}
