import 'package:afrimarket_mobile/core/session/session_provider.dart';
import 'package:afrimarket_mobile/shared/widgets/auth_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n.dart';

class _FixedSession extends SessionNotifier {
  new(this._status);

  final SessionStatus _status;

  @override
  SessionStatus build() => _status;
}

Future<void> _pump(WidgetTester tester, SessionStatus status) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [sessionProvider.overrideWith(() => _FixedSession(status))],
      child: localizedApp(
        const AuthGate(
          signInPrompt: Text('invitation'),
          child: Text('contenu'),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('connecté : le contenu', (tester) async {
    await _pump(tester, SessionStatus.authenticated);

    expect(find.text('contenu'), findsOneWidget);
    expect(find.text('invitation'), findsNothing);
  });

  testWidgets('visiteur : l’invitation', (tester) async {
    await _pump(tester, SessionStatus.unauthenticated);

    expect(find.text('invitation'), findsOneWidget);
    expect(find.text('contenu'), findsNothing);
  });

  testWidgets('session inconnue : ni l’un ni l’autre', (tester) async {
    await _pump(tester, SessionStatus.unknown);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('contenu'), findsNothing);
  });
}
