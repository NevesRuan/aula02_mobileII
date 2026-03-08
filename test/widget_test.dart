// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:todo_refatoracao_baguncado/ui/app_root.dart';
import 'package:todo_refatoracao_baguncado/features/todos/presentation/todo_viewmodel.dart';
import 'package:todo_refatoracao_baguncado/features/todos/data/todo_repository_impl.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => TodoViewModel(TodoRepositoryImpl())),
        ],
        child: const AppRoot(),
      ),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}