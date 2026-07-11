// =============================================================================
// FILE: test/widget/home_screen_test.dart
// =============================================================================
// PURPOSE: Widget tests for the HomeScreen
// WHY: Tests how the UI responds to different BLoC states
//
// ═══════════════════════════════════════════════════════════════
// TESTING WIDGETS WITH BLoC
// ═══════════════════════════════════════════════════════════════
//
// Widget testing with BLoC is different from regular widget testing because:
//   1. The widget depends on a BlocProvider ancestor
//   2. We need to provide a mock or test cubit
//   3. We test "given this state, does the UI render correctly?"
//
// Two approaches:
//
// Approach 1: Mock the Cubit (recommended)
//   - Create a MockTodosCubit
//   - Use BlocProvider.value to provide it
//   - Manually emit states to test UI reaction
//   - Fast, isolated, no real cubit logic
//
// Approach 2: Use real Cubit with mock Repository
//   - Create a real TodosCubit with MockTodoRepository
//   - Trigger real logic (cubit.loadTodos())
//   - Test that the UI updates correctly
//   - Slower but tests the full integration
//
// We'll use Approach 1 for widget tests (fast & isolated)
// and Approach 2 is what we did in the cubit tests.
//
// =============================================================================

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:todo_bloc_guide/data/models/todo_model.dart';
import 'package:todo_bloc_guide/logic/todos_cubit.dart';
import 'package:todo_bloc_guide/logic/todos_state.dart';
import 'package:todo_bloc_guide/presentation/screens/home_screen.dart';

// ═══════════════════════════════════════════════════════════════
// Mock Cubit — Uses stream to emit states on demand
// ═══════════════════════════════════════════════════════════════
// MockBloc lets us control exactly what states the cubit emits.
// We can say "emit Loading, then emit Loaded" and test the UI.
//
class MockTodosCubit extends MockBloc<TodosCubit, TodosState>
    implements TodosCubit {}

void main() {
  late MockTodosCubit mockTodosCubit;

  setUp(() {
    mockTodosCubit = MockTodosCubit();
  });

  // ═══════════════════════════════════════════════════════════════
  // Helper: Wraps widget with BlocProvider
  // ═══════════════════════════════════════════════════════════════
  // Every widget test needs to wrap the widget in a BlocProvider
  // that provides our mock cubit. This helper avoids repetition.
  //
  Widget createSubject() {
    return BlocProvider<TodosCubit>.value(
      value: mockTodosCubit,
      child: const MaterialApp(home: HomeScreen()),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TEST: Loading State
  // ═══════════════════════════════════════════════════════════════
  testWidgets('shows loading indicator when state is TodosLoading', (
    tester,
  ) async {
    // Arrange: Tell the mock cubit what state to return
    when(() => mockTodosCubit.state).thenReturn(const TodosLoading());
    // Tell the mock cubit what its stream should emit
    whenListen(
      mockTodosCubit,
      Stream.value(const TodosLoading()),
      initialState: const TodosLoading(),
    );

    // Act: Render the widget
    await tester.pumpWidget(createSubject());

    // Assert: Find a CircularProgressIndicator
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    // Should NOT find empty state or todo list
    expect(find.byType(ListView), findsNothing);
  });

  // ═══════════════════════════════════════════════════════════════
  // TEST: Loaded State
  // ═══════════════════════════════════════════════════════════════
  testWidgets('shows todo list when state is TodosLoaded with todos', (
    tester,
  ) async {
    // Arrange
    final testTodos = [
      Todo(id: '1', title: 'Test Todo', createdAt: DateTime(2024)),
    ];

    final loadedState = TodosLoaded(todos: testTodos);
    when(() => mockTodosCubit.state).thenReturn(loadedState);
    whenListen(
      mockTodosCubit,
      Stream.value(loadedState),
      initialState: loadedState,
    );

    // Act
    await tester.pumpWidget(createSubject());

    // Assert: Should find the todo title text
    expect(find.text('Test Todo'), findsOneWidget);
    // Should NOT find loading indicator
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  // ═══════════════════════════════════════════════════════════════
  // TEST: Error State
  // ═══════════════════════════════════════════════════════════════
  testWidgets('shows error message when state is TodosError', (tester) async {
    // Arrange
    const errorState = TodosError('Something went wrong');
    when(() => mockTodosCubit.state).thenReturn(errorState);
    whenListen(
      mockTodosCubit,
      Stream.value(errorState),
      initialState: errorState,
    );

    // Act
    await tester.pumpWidget(createSubject());

    // Assert: Should find error icon and retry button
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  // ═══════════════════════════════════════════════════════════════
  // TEST: Empty State
  // ═══════════════════════════════════════════════════════════════
  testWidgets('shows empty state when TodosLoaded has no todos', (
    tester,
  ) async {
    // Arrange
    const emptyState = TodosLoaded(todos: []);
    when(() => mockTodosCubit.state).thenReturn(emptyState);
    whenListen(
      mockTodosCubit,
      Stream.value(emptyState),
      initialState: emptyState,
    );

    // Act
    await tester.pumpWidget(createSubject());

    // Assert: Should find empty state elements
    expect(find.byIcon(Icons.checklist_rounded), findsOneWidget);
    expect(find.text('No todos yet!'), findsOneWidget);
  });
}
