🎯 Flutter To-Do App — Complete BLoC (Cubit) Guide
A production-ready To-Do application that doubles as a comprehensive, step-by-step guide to BLoC (Cubit) state management in Flutter.

FlutterDartBLoCLicense

📖 Table of Contents
🤔 Why BLoC/Cubit?
🏗️ Architecture Overview
📚 BLoC vs Cubit — Deep Dive
🧩 Core BLoC Concepts Explained
🚀 Getting Started
📁 Project Structure
🔧 Key Features
🧪 Testing
🤝 Contributing
📄 License
🤔 Why BLoC/Cubit?
The Problem BLoC Solves
In Flutter, setState() works for tiny apps. But as your app grows:

Problem	Example
Spaghetti State	15 setState() calls in one widget
Unnecessary Rebuilds	Entire screen rebuilds when one item changes
No Testability	Can't test business logic without UI
State Chaos	No single source of truth — state scattered everywhere
Hard to Debug	"Why did the UI update?" — no clear answer
BLoC's Solution
┌─────────────┐     Events/Methods     ┌─────────────┐     States     ┌─────────────┐│             │ ──────────────────────► │             │ ─────────────►│             ││   UI Layer  │                        │  BLoC/Cubit │               │   UI Layer  ││  (Widgets)  │ ◄────────────────────── │  (Logic)    │ ◄─────────────│  (Widgets)  ││             │      Rebuild UI         │             │   New State   │             │└─────────────┘                         └─────────────┘               └─────────────┘
BLoC/Cubit provides:

✅ Separation of Concerns — UI knows nothing about data sources
✅ Single Source of Truth — One state object, one place to modify it
✅ Testability — Test business logic independently from UI
✅ Reactivity — UI auto-updates when state changes
✅ Traceability — Every state change can be logged/tracked
🏗️ Architecture Overview
This project follows Clean Architecture principles:

lib/├── core/           → Shared utilities, constants, theme, database├── data/           → Data layer: models + repositories (HOW data is fetched)├── logic/          → Business logic layer: Cubits + States (WHAT the app does)└── presentation/   → UI layer: screens + widgets (WHAT the user sees)
Data Flow (The Complete Picture)
User Tap → Widget calls Cubit Method → Cubit talks to Repository → Repository talks to Database → Database returns Data → Repository returns Model → Cubit emits new State → Widget rebuilds
┌──────────────────────────────────────────────────────────────────┐│                     PRESENTATION LAYER                           ││  ┌──────────┐  BlocProvider  ┌──────────┐  BlocBuilder          ││  │  Screen   │ ────────────► │   Cubit   │ ◄────────────────    ││  │ (Widget)  │  call method  │           │  rebuild on state    ││  └──────────┘               └─────┬─────┘                      ││                                    │                             │├────────────────────────────────────┼────────────────────────────┤│                     LOGIC LAYER    │                             ││                                    ▼                             ││                            ┌──────────────┐                     ││                            │  Repository   │                     ││                            └──────┬───────┘                     ││                                   │                              │├───────────────────────────────────┼──────────────────────────────┤│                     DATA LAYER    │                              ││                                   ▼                              ││                           ┌──────────────┐                      ││                           │   Hive DB     │                      ││                           └──────────────┘                      │└──────────────────────────────────────────────────────────────────┘
📚 BLoC vs Cubit — Deep Dive
Cubit (What we use in this project)
// ═══════════════════════════════════════════════════════════════// CUBIT: A simpler version of BLoC// - Uses METHODS to trigger state changes (not events)// - Call a method → Emit a new state. That's it!// - Perfect for 90% of use cases// - Less boilerplate, easier to understand// ═══════════════════════════════════════════════════════════════class TodosCubit extends Cubit<TodosState> {  // Cubit requires an initial state  TodosCubit() : super(TodosInitial());    // Methods (instead of events) trigger state changes  void loadTodos() {    emit(TodosLoading());     // Step 1: Emit loading state    final todos = repo.get(); // Step 2: Get data    emit(TodosLoaded(todos)); // Step 3: Emit loaded state  }}// In UI: cubit.loadTodos(); — Simple!
BLoC (The full version)
// ═══════════════════════════════════════════════════════════════// BLoC: Event-driven state management// - Uses EVENTS to trigger state changes (not methods)// - Event → EventHandler → Emit State// - More structured, better for complex flows// - Built-in event transformation (debounce, throttle, etc.)// ═══════════════════════════════════════════════════════════════abstract class TodosEvent {}         // Base eventclass LoadTodos extends TodosEvent {} // Specific eventclass TodosBloc extends Bloc<TodosEvent, TodosState> {  TodosBloc() : super(TodosInitial()) {    // Register event handlers    on<LoadTodos>(_onLoadTodos);  }    Future<void> _onLoadTodos(LoadTodos event, Emitter<TodosState> emit) async {    emit(TodosLoading());    final todos = await repo.get();    emit(TodosLoaded(todos));  }}// In UI: bloc.add(LoadTodos()); — Event-based!
When to Use Which?
Criteria	Cubit ✅	BLoC ✅
Simple state transitions	✅	
CRUD operations	✅	
Need event transformation		✅
Complex event sequences		✅
Want less boilerplate	✅	
Need event queuing/retry		✅
Learning BLoC for first time	✅	
Rule of thumb: Start with Cubit. Switch to BLoC only when you need advanced event handling. Cubit IS a subset of BLoC — the migration is trivial.

🧩 Core BLoC Concepts Explained
1. State
// ═══════════════════════════════════════════════════════════════// STATE: A snapshot of your app's data at a moment in time// - MUST be immutable (never modify, always create new)// - MUST extend Equatable (for efficient comparison)// - Represents "what the UI should look like"// ═══════════════════════════════════════════════════════════════//// Think of State like a photograph:// - You can take a new photo, but you can't change an old one// - Each photo captures exactly how things looked at that moment// - The UI "looks at" the current photo to render itself//class TodosLoaded extends Equatable {  final List<Todo> todos;    const TodosLoaded(this.todos);    // Equatable: tells BLoC "two states are equal if these props match"  // Without this, BlocBuilder might not rebuild when it should!  @override  List<Object> get props => [todos];}
2. Cubit
// ═══════════════════════════════════════════════════════════════// CUBIT: The "brain" that manages state// - Holds the current state// - Exposes methods to change state// - Uses emit() to broadcast new states// - Only ONE rule: emit() can only be called INSIDE the cubit// ═══════════════════════════════════════════════════════════════//// Think of Cubit like a traffic controller:// - It receives requests (method calls)// - It decides what the new state should be// - It broadcasts the new state (emit)// - All widgets listening to this cubit get notified//class CounterCubit extends Cubit<int> {  CounterCubit() : super(0); // Initial state = 0    void increment() => emit(state + 1);  // New state = old + 1  void decrement() => emit(state - 1);  // New state = old - 1  void reset() => emit(0);              // Reset to 0}
3. BlocProvider
// ═══════════════════════════════════════════════════════════════// BlocProvider: Makes a Cubit/Bloc available to the widget tree// - Uses InheritedWidget under the hood// - Any descendant widget can access the cubit// - Automatically closes the cubit when provider is removed// ═══════════════════════════════════════════════════════════════//// Think of BlocProvider like a water pipe:// - It connects the water source (cubit) to all faucets (widgets)// - Any widget "downstream" can access the water (state)// - When you remove the pipe, the water stops (cubit is closed)//BlocProvider<TodosCubit>(  create: (context) => TodosCubit(todoRepository)..loadTodos(),  child: HomeScreen(),  // HomeScreen and ALL its children can access TodosCubit)// Access from any descendant:final cubit = context.read<TodosCubit>();  // Get cubit (no rebuild)
4. BlocBuilder
// ═══════════════════════════════════════════════════════════════// BlocBuilder: Rebuilds UI when state changes// - Like StreamBuilder but specifically for BLoC/Cubit// - Only rebuilds the widget INSIDE BlocBuilder, not the whole screen// - Can filter which state changes trigger rebuilds (buildWhen)// ═══════════════════════════════════════════════════════════════//// Think of BlocBuilder like a TV screen:// - It displays the current "channel" (state)// - When the channel changes (new state emitted), it updates the display// - You can choose to only update for certain channels (buildWhen)//BlocBuilder<TodosCubit, TodosState>(  // Optional: Only rebuild when this returns true  buildWhen: (previousState, currentState) {    return currentState is TodosLoaded; // Only rebuild on TodosLoaded  },  builder: (context, state) {    if (state is TodosLoading) return LoadingIndicator();    if (state is TodosLoaded) return TodoList(state.todos);    if (state is TodosError) return ErrorWidget(state.message);    return SizedBox(); // Fallback  },)
5. BlocListener
// ═══════════════════════════════════════════════════════════════// BlocListener: Executes ONE-TIME actions when state changes// - Does NOT rebuild the widget// - Perfect for: SnackBars, Dialogs, Navigation, Haptics// - listenWhen: Filter which state changes trigger the callback// ═══════════════════════════════════════════════════════════════//// Think of BlocListener like a doorbell:// - It rings ONCE when someone arrives (state changes)// - It doesn't change the house (no rebuild)// - You respond to the doorbell (show SnackBar, navigate, etc.)//BlocListener<TodosCubit, TodosState>(  listenWhen: (previous, current) => previous != current,  listener: (context, state) {    if (state is TodoAdded) {      ScaffoldMessenger.of(context).showSnackBar(        SnackBar(content: Text('Todo added! 🎉')),      );    }    if (state is TodosError) {      showErrorDialog(context, state.message);    }  },  child: TodoList(), // This widget is NOT rebuilt)
6. BlocConsumer
// ═══════════════════════════════════════════════════════════════// BlocConsumer: Combines BlocBuilder + BlocListener// - Use when you need BOTH rebuild AND one-time actions// - More efficient than nesting BlocBuilder inside BlocListener// ═══════════════════════════════════════════════════════════════BlocConsumer<TodosCubit, TodosState>(  listener: (context, state) {    // One-time actions (SnackBars, Navigation, Dialogs)    if (state is TodoDeleted) {      showSnackBar('Todo deleted! 🗑️');    }  },  builder: (context, state) {    // Rebuild UI based on state    if (state is TodosLoaded) return TodoList(state.todos);    return LoadingIndicator();  },)
7. MultiBlocProvider
// ═══════════════════════════════════════════════════════════════// MultiBlocProvider: Provides MULTIPLE Cubits/Blocs at once// - Cleaner than nesting multiple BlocProviders// - All descendants can access ANY of the provided cubits// ═══════════════════════════════════════════════════════════════// ❌ Ugly nested approach:BlocProvider<ThemeCubit>(  create: (_) => ThemeCubit(),  child: BlocProvider<TodosCubit>(    create: (_) => TodosCubit(repo),    child: App(),  ),)// ✅ Clean multi-provider approach:MultiBlocProvider(  providers: [    BlocProvider(create: (_) => ThemeCubit()),    BlocProvider(create: (_) => TodosCubit(repo)..loadTodos()),  ],  child: App(),)
8. context.read vs context.watch vs context.select
// ═══════════════════════════════════════════════════════════════// THREE WAYS TO ACCESS CUBIT/BLOC FROM UI// ═══════════════════════════════════════════════════════════════// 1. context.read<T>() — Get cubit WITHOUT listening (NO rebuilds)//    Use for: Calling methods (addTodo, deleteTodo, etc.)//    Why: You don't want the widget to rebuild just because you//    called a method — only when the STATE changes!final cubit = context.read<TodosCubit>();cubit.addTodo(newTodo); // Trigger action, no rebuild from this line// 2. context.watch<T>() — Get cubit AND listen (REBUILDS on state change)//    Use for: Getting current state in build method//    Same as using BlocBuilder but inlinefinal state = context.watch<TodosCubit>().state;if (state is TodosLoaded) return Text('${state.todos.length} todos');// 3. context.select<T, R>() — Listen to SPECIFIC part of state//    Use for: Optimizing rebuilds — only rebuild when selected value changes//    This is the MOST efficient option!final todoCount = context.select<TodosCubit, int>(  (cubit) => cubit.state is TodosLoaded     ? (cubit.state as TodosLoaded).todos.length     : 0,);// Only rebuilds when todo count changes, not for other state changes!
🚀 Getting Started
Prerequisites
Flutter SDK 3.0+ (Install Guide)
Dart SDK 3.0+
Android Studio / VS Code
An emulator or physical device
Installation
# 1. Clone the repositorygit clone https://github.com/YOUR_USERNAME/todo_bloc_guide.git# 2. Navigate to project directorycd todo_bloc_guide# 3. Install dependenciesflutter pub get# 4. Generate Hive adapters (for local database serialization)flutter packages pub run build_runner build# 5. Run the appflutter run
🔧 Key Features
✅ Add, Edit, Delete Todos — Full CRUD with BLoC/Cubit
✅ Toggle Completion — Mark todos as done/undone
✅ Search & Filter — Real-time search + category filtering
✅ Persistent Storage — Hive local database
✅ Beautiful Animations — Staggered list animations, transitions
✅ Priority Levels — High, Medium, Low with color coding
✅ Dark/Light Theme — Theme switching with BLoC
✅ Swipe to Delete — Interactive dismiss gestures
✅ Empty States — Friendly illustrations when no todos
✅ Form Validation — Input validation with error messages
✅ Undo Delete — SnackBar with undo action
🧪 Testing
# Run all testsflutter test# Run with coverageflutter test --coverage# Run specific test fileflutter test test/logic/todos_cubit_test.dart
🤝 Contributing
See CONTRIBUTING.md

📄 License
This project is licensed under the MIT License — see LICENSE

🙏 Acknowledgments
flutter_bloc by Felix Angelov
Hive by Simon Leier
Flutter Team for the amazing framework
💡 Pro Tip: Read the code comments! Every file is extensively commented to explain not just WHAT the code does, but WHY it's written that way.