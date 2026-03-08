import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'ui/app_root.dart';
import 'features/todos/presentation/todo_viewmodel.dart';
import 'features/todos/data/todo_repository_impl.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TodoViewModel(TodoRepositoryImpl())),
      ],
      child: const AppRoot(),
    ),
  );
}
