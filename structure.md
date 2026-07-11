todo_bloc_guide/
├── .gitignore
├── .metadata
├── README.md
├── CONTRIBUTING.md
├── LICENSE
├── analysis_options.yaml
├── pubspec.yaml
├── pubspec.lock
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_colors.dart
│   │   │   ├── app_strings.dart
│   │   │   └── app_dimens.dart
│   │   ├── theme/
│   │   │   └── app_theme.dart
│   │   ├── utils/
│   │   │   └── date_formatter.dart
│   │   └── database/
│   │       └── local_database.dart
│   ├── data/
│   │   ├── models/
│   │   │   └── todo_model.dart
│   │   └── repositories/
│   │       └── todo_repository.dart
│   ├── logic/
│   │   ├── todos_cubit.dart
│   │   └── todos_state.dart
│   └── presentation/
│       ├── screens/
│       │   ├── home_screen.dart
│       │   └── add_edit_todo_screen.dart
│       └── widgets/
│           ├── todo_card.dart
│           ├── custom_button.dart
│           ├── custom_text_field.dart
│           ├── empty_state.dart
│           ├── filter_chip_bar.dart
│           ├── search_bar_widget.dart
│           └── confirmation_dialog.dart
├── test/
│   ├── logic/
│   │   └── todos_cubit_test.dart
│   └── widget/
│       └── home_screen_test.dart
└── assets/
    └── .gitkeep