// =============================================================================
// FILE: test/logic/todos_cubit_test.dart
// =============================================================================
// PURPOSE: Unit tests for TodosCubit
// WHY: Testing is where BLoC/Cubit truly SHINES compared to other state management!
//
// ═══════════════════════════════════════════════════════════════
// WHY BLoC IS THE MOST TESTABLE STATE MANAGEMENT SOLUTION
// ═══════════════════════════════════════════════════════════════
//
// With setState():
//   - Business logic is mixed with UI code
//   - You need to render widgets to test logic
//   - Testing is slow and fragile
//   - "How do I test what happens when user taps button?"
//
// With BLoC/Cubit:
//   - Business logic is ISOLATED in the cubit
//   - No UI code needed for testing
//   - Testing is fast (milliseconds, not seconds)
//   - "Just call cubit.method() and check the emitted states"
//
// The testing pattern is always:
//   1. Arrange: Set up initial state and mocks
//   2. Act: Call a cubit method
//   3. Assert: Check the emitted states
//
// ═══════════════════════════════════════════════════════════════
// bloc_test PACKAGE — The Secret Weapon
// ═══════════════════════════════════════════════════════════════
//
// The bloc_test package provides a special blocTest() function that:
//   - Handles all the stream subscription boilerplate
//   - Lets you specify WHAT to do (act)
//   - Lets you specify WHAT to expect (expect)
//   - Handles async operations automatically (wait)
//   - Can skip initial states (skip)
//
// Compare:
//
// ❌ Without bloc_test:
//    test('load todos', () async {
//      final cubit = TodosCubit(repo: mockRepo);
//      final states = <TodosState>[];
//      final subscription = cubit.stream.listen(states.add);
//      await cubit.loadTodos();
//      await Future.delayed(Duration(milliseconds: 100));
//      expect(states, [TodosLoading(), TodosLoaded(todos)]);
//      await subscription.cancel();
//      await cubit.close();
//    });
//
// ✅ With bloc_test:
//    blocTest<TodosCubit, TodosState>(
//      'load todos',
//      build: () => TodosCubit(repo: mockRepo),
//      act: (cubit) => cubit.loadTodos(),
//      expect: () => [TodosLoading(), TodosLoaded(todos)],
//    );
//
// Much cleaner! And it handles all the lifecycle management.
//
// =============================================================================

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:todo_bloc_guide/data/models/todo_model.dart';
import 'package:todo_bloc_guide/data/repositories/todo_repository.dart';
import 'package:todo_bloc_guide/logic/todos_cubit.dart';
import 'package:todo_bloc_guide/logic/todos_state.dart';

// ═══════════════════════════════════════════════════════════════
// MOCK CLASSES
// ═══════════════════════════════════════════════════════════════
// A Mock is a fake version of a class that we control in tests.
// Instead of using a REAL TodoRepository (which would use a real database),
// we use a MOCK repository that returns whatever we tell it to.
//
// WHY?
//   1. Speed: No disk I/O — tests run in milliseconds
//   2. Isolation: We're testing the CUBIT, not the database
//   3. Control: We can make the mock return errors, empty lists, etc.
//   4. Consistency: Real databases can have timing issues in tests
//
// mocktail is the library we use to create mocks.
// It's the successor to mockito — simpler API, no code generation needed.
//
class MockTodoRepository extends Mock implements TodoRepository {}

// Test data — sample todos for testing
final testTodos = [
  Todo(
    id: '1',
    title: 'Test Todo 1',
    description: 'Description 1',
    isCompleted: false,
    priority: TodoPriority.high,
    category: TodoCategory.work,
    createdAt: DateTime(2024, 1, 1),
  ),
  Todo(
    id: '2',
    title: 'Test Todo 2',
    description: 'Description 2',
    isCompleted: true,
    priority: TodoPriority.low,
    category: TodoCategory.personal,
    createdAt: DateTime(2024, 1, 2),
  ),
];

void main() {
  // ═══════════════════════════════════════════════════════════════
  // TEST SETUP
  // ═══════════════════════════════════════════════════════════════
  // setUp runs BEFORE each test — creates fresh instances so tests
  // don't affect each other
  //
  late MockTodoRepository mockRepository;
  late TodosCubit todosCubit;

  setUp(() {
    mockRepository = MockTodoRepository();
    // Register fallback values for mocktail
    // When mocking methods that accept complex types (like Todo),
    // mocktail needs a "fallback" instance for internal processing
    registerFallbackValue(
      Todo(id: 'fallback', title: 'fallback', createdAt: DateTime(2024)),
    );
  });

  // ═══════════════════════════════════════════════════════════════
  // TEST: Initial State
  // ═══════════════════════════════════════════════════════════════
  // The simplest test: "When cubit is created, what's its initial state?"
  group('TodosCubit Initial State', () {
    test('initial state should be TodosInitial', () {
      todosCubit = TodosCubit(todoRepository: mockRepository);
      expect(todosCubit.state, equals(const TodosInitial()));
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // TEST: Load Todos
  // ═══════════════════════════════════════════════════════════════
  // Testing the happy path: "When loadTodos is called, does the cubit
  // emit Loading → Loaded states with the correct data?"
  //
  group('Load Todos', () {
    blocTest<TodosCubit, TodosState>(
      'emits [TodosLoading, TodosLoaded] when loadTodos succeeds',

      // build: Create the cubit with the mock repository
      // This is the "Arrange" step
      build: () {
        // Tell the mock repository what to return when getAllTodos is called
        // "When mockRepository.getAllTodos() is called, return testTodos"
        when(
          () => mockRepository.getAllTodos(),
        ).thenAnswer((_) async => testTodos);

        return TodosCubit(todoRepository: mockRepository);
      },

      // act: Call the method we're testing
      // This is the "Act" step
      act: (cubit) => cubit.loadTodos(),

      // expect: What states should be emitted IN ORDER
      // This is the "Assert" step
      // Note: The states must be in EXACT order — BLoC states are a sequence!
      expect: () => [const TodosLoading(), TodosLoaded(todos: testTodos)],

      // Verify that the repository method was actually called
      verify: (_) {
        verify(() => mockRepository.getAllTodos()).called(1);
      },
    );

    // ───────── Error Case ─────────
    blocTest<TodosCubit, TodosState>(
      'emits [TodosLoading, TodosError] when loadTodos fails',

      build: () {
        // Tell the mock to throw an error
        when(
          () => mockRepository.getAllTodos(),
        ).thenThrow(Exception('Database error'));

        return TodosCubit(todoRepository: mockRepository);
      },

      act: (cubit) => cubit.loadTodos(),

      // We expect Loading → Error (no Loaded state)
      expect: () => [
        const TodosLoading(),
        isA<TodosError>(), // Use isA<> because error message includes exception details
      ],
    );
  });

  // ═══════════════════════════════════════════════════════════════
  // TEST: Add Todo
  // ═══════════════════════════════════════════════════════════════
  group('Add Todo', () {
    blocTest<TodosCubit, TodosState>(
      'emits TodosLoaded with new todo after addTodo',

      build: () {
        // Mock the add method (returns void, so we just use thenAnswer)
        when(() => mockRepository.addTodo(any())).thenAnswer((_) async {});
        // Mock loadTodos (called after adding to refresh the list)
        when(
          () => mockRepository.getAllTodos(),
        ).thenAnswer((_) async => testTodos);

        // Start with a loaded state (simulating existing todos)
        final cubit = TodosCubit(todoRepository: mockRepository);
        return cubit;
      },

      // We need to seed the cubit with an initial loaded state
      // because addTodo only works if the current state is TodosLoaded
      seed: () => TodosLoaded(todos: testTodos),

      act: (cubit) => cubit.addTodo(
        title: 'New Todo',
        description: 'New Description',
        priority: TodoPriority.high,
        category: TodoCategory.work,
      ),

      // After adding, we expect:
      //   1. TodosLoaded with refreshed data (from loadTodos inside addTodo)
      //   2. TodoAdded action state
      //   3. TodosLoaded again (re-emitted after action state)
      expect: () => [isA<TodosLoaded>(), isA<TodoAdded>(), isA<TodosLoaded>()],

      verify: (_) {
        verify(() => mockRepository.addTodo(any())).called(1);
        verify(() => mockRepository.getAllTodos()).called(1);
      },
    );
  });

  // ═══════════════════════════════════════════════════════════════
  // TEST: Search & Filter
  // ═══════════════════════════════════════════════════════════════
  // These are synchronous operations — no database calls needed!
  // The cubit just updates the state's filter properties.
  //
  group('Search and Filter', () {
    blocTest<TodosCubit, TodosState>(
      'emits TodosLoaded with searchQuery when searchTodos is called',
      build: () => TodosCubit(todoRepository: mockRepository),
      seed: () => TodosLoaded(todos: testTodos),
      act: (cubit) => cubit.searchTodos('Test'),
      expect: () => [TodosLoaded(todos: testTodos, searchQuery: 'Test')],
    );

    blocTest<TodosCubit, TodosState>(
      'emits TodosLoaded with selectedCategory when filterByCategory is called',
      build: () => TodosCubit(todoRepository: mockRepository),
      seed: () => TodosLoaded(todos: testTodos),
      act: (cubit) => cubit.filterByCategory(TodoCategory.work),
      expect: () => [
        TodosLoaded(todos: testTodos, selectedCategory: TodoCategory.work),
      ],
    );

    blocTest<TodosCubit, TodosState>(
      'clears category filter when same category is selected again (toggle)',

      build: () => TodosCubit(todoRepository: mockRepository),

      // Start with Work category already selected
      seed: () =>
          TodosLoaded(todos: testTodos, selectedCategory: TodoCategory.work),

      // Select Work again → should toggle off
      act: (cubit) => cubit.filterByCategory(TodoCategory.work),

      expect: () => [
        TodosLoaded(todos: testTodos), // selectedCategory is null
      ],
    );
  });
}
