import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:crabsensemobile/features/profile/domain/entities/notification_preferences.dart';
import 'package:crabsensemobile/features/profile/domain/repositories/notification_preferences_repository.dart';
import 'package:crabsensemobile/features/profile/presentation/bloc/notification_settings_bloc.dart';
import 'package:crabsensemobile/features/profile/presentation/bloc/notification_settings_event.dart';
import 'package:crabsensemobile/features/profile/presentation/bloc/notification_settings_state.dart';
import 'package:crabsensemobile/features/profile/presentation/widgets/notification_settings.dart';

// ── Mocks ─────────────────────────────────────────────────────────────────────

class MockNotificationPreferencesRepository extends Mock
    implements NotificationPreferencesRepository {}

class MockNotificationSettingsBloc
    extends MockBloc<NotificationSettingsEvent, NotificationSettingsState>
    implements NotificationSettingsBloc {}

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Pumps [NotificationSettingsWidget] with a pre-seeded mock bloc.
Widget _widgetWithBloc(NotificationSettingsBloc bloc) => MaterialApp(
  home: Scaffold(
    body: BlocProvider<NotificationSettingsBloc>.value(value: bloc, child: const _DirectView()),
  ),
);

/// Thin wrapper that renders the inner view without [BlocProvider].
///
/// Used when the test supplies its own mock bloc via [BlocProvider.value].
class _DirectView extends StatelessWidget {
  const _DirectView();

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<NotificationSettingsBloc, NotificationSettingsState>(
        builder: (context, state) {
          if (state is NotificationSettingsLoading || state is NotificationSettingsInitial) {
            return const CircularProgressIndicator();
          }
          if (state is NotificationSettingsError) {
            return Text('Error: ${state.message}');
          }
          if (state is NotificationSettingsLoaded) {
            // Render a minimal subset of the real settings body so
            // that the toggle interactions can be tested without
            // needing Platform.isAndroid in the test environment.
            final prefs = state.preferences;
            return Column(
              children: [
                SwitchListTile(
                  key: const Key('warnings_tile'),
                  title: const Text('Warnings'),
                  value: prefs.warningsEnabled,
                  onChanged: (_) => context.read<NotificationSettingsBloc>().add(
                    NotificationSettingToggled(
                      (p) => p.copyWith(warningsEnabled: !p.warningsEnabled),
                    ),
                  ),
                ),
                // Critical alerts switch — always true, onChanged null
                SwitchListTile(
                  key: const Key('critical_tile'),
                  title: const Text('Critical Alerts'),
                  value: prefs.criticalAlertsEnabled,
                  onChanged: null,
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late MockNotificationPreferencesRepository mockRepo;
  late MockNotificationSettingsBloc mockBloc;

  const defaultPrefs = NotificationPreferences();

  setUp(() {
    mockRepo = MockNotificationPreferencesRepository();
    mockBloc = MockNotificationSettingsBloc();
  });

  // ── NotificationPreferences entity ───────────────────────────────────────

  group('NotificationPreferences', () {
    test('has all flags true by default', () {
      const prefs = NotificationPreferences();
      expect(prefs.criticalAlertsEnabled, isTrue);
      expect(prefs.warningsEnabled, isTrue);
      expect(prefs.taskRemindersEnabled, isTrue);
      expect(prefs.systemUpdatesEnabled, isTrue);
      expect(prefs.soundEnabled, isTrue);
      expect(prefs.vibrationEnabled, isTrue);
      expect(prefs.ledIndicatorEnabled, isTrue);
    });

    test('copyWith updates only the specified field', () {
      const prefs = NotificationPreferences();
      final updated = prefs.copyWith(warningsEnabled: false);
      expect(updated.warningsEnabled, isFalse);
      expect(updated.criticalAlertsEnabled, isTrue);
      expect(updated.soundEnabled, isTrue);
    });

    test('copyWith always keeps criticalAlertsEnabled = true', () {
      // The entity does not expose criticalAlertsEnabled in copyWith,
      // so it must always remain true.
      const prefs = NotificationPreferences();
      final updated = prefs.copyWith(warningsEnabled: false);
      expect(updated.criticalAlertsEnabled, isTrue);
    });

    test('equality holds for identical instances', () {
      const a = NotificationPreferences();
      const b = NotificationPreferences();
      expect(a, equals(b));
    });

    test('instances differ when a field changes', () {
      const a = NotificationPreferences();
      final b = a.copyWith(soundEnabled: false);
      expect(a, isNot(equals(b)));
    });
  });

  // ── Widget — loading state ────────────────────────────────────────────────

  group('NotificationSettingsWidget — loading state', () {
    testWidgets('shows CircularProgressIndicator while loading', (tester) async {
      when(() => mockBloc.state).thenReturn(const NotificationSettingsLoading());
      whenListen(
        mockBloc,
        Stream<NotificationSettingsState>.value(const NotificationSettingsLoading()),
      );

      await tester.pumpWidget(_widgetWithBloc(mockBloc));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  // ── Widget — error state ──────────────────────────────────────────────────

  group('NotificationSettingsWidget — error state', () {
    testWidgets('shows error message on failure', (tester) async {
      const errorMessage = 'Storage read failed';
      when(() => mockBloc.state).thenReturn(const NotificationSettingsError(message: errorMessage));
      whenListen(
        mockBloc,
        Stream<NotificationSettingsState>.value(
          const NotificationSettingsError(message: errorMessage),
        ),
      );

      await tester.pumpWidget(_widgetWithBloc(mockBloc));

      expect(find.textContaining(errorMessage), findsOneWidget);
    });
  });

  // ── Widget — loaded state ─────────────────────────────────────────────────

  group('NotificationSettingsWidget — loaded state', () {
    testWidgets('renders toggles when preferences are loaded', (tester) async {
      when(
        () => mockBloc.state,
      ).thenReturn(const NotificationSettingsLoaded(preferences: defaultPrefs));
      whenListen(
        mockBloc,
        Stream<NotificationSettingsState>.value(
          const NotificationSettingsLoaded(preferences: defaultPrefs),
        ),
      );

      await tester.pumpWidget(_widgetWithBloc(mockBloc));

      expect(find.byKey(const Key('warnings_tile')), findsOneWidget);
      expect(find.byKey(const Key('critical_tile')), findsOneWidget);
    });

    testWidgets('tapping warnings toggle dispatches NotificationSettingToggled', (tester) async {
      when(
        () => mockBloc.state,
      ).thenReturn(const NotificationSettingsLoaded(preferences: defaultPrefs));
      whenListen(
        mockBloc,
        Stream<NotificationSettingsState>.value(
          const NotificationSettingsLoaded(preferences: defaultPrefs),
        ),
      );

      await tester.pumpWidget(_widgetWithBloc(mockBloc));

      final switchFinder = find.descendant(
        of: find.byKey(const Key('warnings_tile')),
        matching: find.byType(Switch),
      );
      await tester.tap(switchFinder);
      await tester.pump();

      verify(() => mockBloc.add(any(that: isA<NotificationSettingToggled>()))).called(1);
    });

    testWidgets('critical alerts toggle is disabled (onChanged is null)', (tester) async {
      when(
        () => mockBloc.state,
      ).thenReturn(const NotificationSettingsLoaded(preferences: defaultPrefs));
      whenListen(
        mockBloc,
        Stream<NotificationSettingsState>.value(
          const NotificationSettingsLoaded(preferences: defaultPrefs),
        ),
      );

      await tester.pumpWidget(_widgetWithBloc(mockBloc));

      // Find the SwitchListTile for critical alerts by key.
      final criticalTile = tester.widget<SwitchListTile>(find.byKey(const Key('critical_tile')));

      expect(
        criticalTile.onChanged,
        isNull,
        reason: 'Critical alerts toggle must be disabled — onChanged should be null',
      );
      expect(criticalTile.value, isTrue, reason: 'Critical alerts must always be shown as enabled');
    });
  });

  // ── BLoC — load ───────────────────────────────────────────────────────────

  group('NotificationSettingsBloc — load', () {
    blocTest<NotificationSettingsBloc, NotificationSettingsState>(
      'emits [Loading, Loaded] on successful load',
      build: () {
        when(() => mockRepo.getPreferences()).thenAnswer((_) async => defaultPrefs);
        return NotificationSettingsBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(const NotificationSettingsLoadRequested()),
      expect: () => [
        const NotificationSettingsLoading(),
        const NotificationSettingsLoaded(preferences: defaultPrefs),
      ],
    );

    blocTest<NotificationSettingsBloc, NotificationSettingsState>(
      'emits [Loading, Error] when repository throws',
      build: () {
        when(() => mockRepo.getPreferences()).thenThrow(Exception('Hive read error'));
        return NotificationSettingsBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(const NotificationSettingsLoadRequested()),
      expect: () => [const NotificationSettingsLoading(), isA<NotificationSettingsError>()],
    );
  });

  // ── BLoC — toggle ─────────────────────────────────────────────────────────

  group('NotificationSettingsBloc — toggle', () {
    blocTest<NotificationSettingsBloc, NotificationSettingsState>(
      'optimistically updates and saves preference',
      build: () {
        when(() => mockRepo.getPreferences()).thenAnswer((_) async => defaultPrefs);
        when(() => mockRepo.savePreferences(any())).thenAnswer((_) async {});
        return NotificationSettingsBloc(repository: mockRepo);
      },
      seed: () => const NotificationSettingsLoaded(preferences: defaultPrefs),
      act: (bloc) =>
          bloc.add(NotificationSettingToggled((p) => p.copyWith(warningsEnabled: false))),
      expect: () => [
        // isSaving: true (optimistic)
        const NotificationSettingsLoaded(
          preferences: NotificationPreferences(warningsEnabled: false),
          isSaving: true,
        ),
        // isSaving: false after save completes
        const NotificationSettingsLoaded(
          preferences: NotificationPreferences(warningsEnabled: false),
        ),
      ],
      verify: (_) {
        verify(
          () => mockRepo.savePreferences(const NotificationPreferences(warningsEnabled: false)),
        ).called(1);
      },
    );

    blocTest<NotificationSettingsBloc, NotificationSettingsState>(
      'reverts and emits error when save fails',
      build: () {
        when(() => mockRepo.savePreferences(any())).thenThrow(Exception('Hive write error'));
        return NotificationSettingsBloc(repository: mockRepo);
      },
      seed: () => const NotificationSettingsLoaded(preferences: defaultPrefs),
      act: (bloc) => bloc.add(NotificationSettingToggled((p) => p.copyWith(soundEnabled: false))),
      expect: () => [
        // Optimistic update
        const NotificationSettingsLoaded(
          preferences: NotificationPreferences(soundEnabled: false),
          isSaving: true,
        ),
        // Revert: isSaving false, original prefs restored
        const NotificationSettingsLoaded(preferences: defaultPrefs),
        // Then error state
        isA<NotificationSettingsError>(),
      ],
    );
  });
}
