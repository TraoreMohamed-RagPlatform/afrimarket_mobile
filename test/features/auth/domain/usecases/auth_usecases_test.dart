import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/features/auth/domain/entities/auth_user.dart';
import 'package:afrimarket_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:afrimarket_mobile/features/auth/domain/usecases/login_usecase.dart';
import 'package:afrimarket_mobile/features/auth/domain/usecases/logout_usecase.dart';
import 'package:afrimarket_mobile/features/auth/domain/usecases/register_usecase.dart';
import 'package:afrimarket_mobile/features/auth/domain/usecases/request_password_reset_usecase.dart';
import 'package:afrimarket_mobile/features/auth/domain/usecases/reset_password_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository;

const _user = AuthUser(
  id: 'u1',
  email: 'awa@example.com',
  username: 'awa',
  fullName: 'Awa Traoré',
);

void main() {
  late _MockAuthRepository repository;

  setUp(() => repository = _MockAuthRepository());

  test('connexion : e-mail nettoyé, mot de passe intact', () async {
    when(
      () => repository.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => const Ok<AuthUser>(_user));

    final result = await LoginUseCase(repository)(
      email: ' awa@example.com ',
      password: ' secret ',
    );

    expect((result as Ok<AuthUser>).value, _user);
    verify(
      () => repository.login(email: 'awa@example.com', password: ' secret '),
    ).called(1);
  });

  test('inscription : champs texte nettoyés, mot de passe intact', () async {
    when(
      () => repository.register(
        fullName: any(named: 'fullName'),
        username: any(named: 'username'),
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => const Ok<AuthUser>(_user));

    await RegisterUseCase(repository)(
      fullName: ' Awa Traoré ',
      username: ' awa ',
      email: ' awa@example.com ',
      password: ' Abc-1234 ',
    );

    verify(
      () => repository.register(
        fullName: 'Awa Traoré',
        username: 'awa',
        email: 'awa@example.com',
        password: ' Abc-1234 ',
      ),
    ).called(1);
  });

  test('demande de code : e-mail nettoyé', () async {
    when(() => repository.requestPasswordReset(email: any(named: 'email')))
        .thenAnswer((_) async => const Ok<void>(null));

    await RequestPasswordResetUseCase(repository)(email: ' awa@example.com ');

    verify(() => repository.requestPasswordReset(email: 'awa@example.com'))
        .called(1);
  });

  test('réinitialisation : e-mail et code nettoyés', () async {
    when(
      () => repository.resetPassword(
        email: any(named: 'email'),
        code: any(named: 'code'),
        newPassword: any(named: 'newPassword'),
      ),
    ).thenAnswer((_) async => const Ok<void>(null));

    await ResetPasswordUseCase(repository)(
      email: ' awa@example.com ',
      code: ' 123456 ',
      newPassword: ' Abc-1234 ',
    );

    verify(
      () => repository.resetPassword(
        email: 'awa@example.com',
        code: '123456',
        newPassword: ' Abc-1234 ',
      ),
    ).called(1);
  });

  test('déconnexion : délègue au repository', () async {
    when(() => repository.logout()).thenAnswer((_) async {});

    await LogoutUseCase(repository)();

    verify(() => repository.logout()).called(1);
  });

  test('AuthUser : égalité par valeur', () {
    const copy = AuthUser(
      id: 'u1',
      email: 'awa@example.com',
      username: 'awa',
      fullName: 'Awa Traoré',
    );
    expect(copy, _user);
    expect(copy.hashCode, _user.hashCode);
  });
}
