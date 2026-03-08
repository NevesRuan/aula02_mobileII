# ARCH.md — Arquitetura Feature-First

## Estrutura Final

```text
lib/
  main.dart                                 ← entry point; cria e injeta TodoRepositoryImpl no TodoViewModel
  ui/
    app_root.dart                           ← MaterialApp + rota inicial
  core/
    errors/
      app_errors.dart                       ← AppError (exception compartilhada)
  features/
    todos/
      domain/
        todo_entity.dart                    ← entidade pura (sem fromJson, sem imports de data/)
        todo_repository.dart                ← interface abstract TodoRepository + TodoFetchResult
      data/
        todo_model.dart                     ← TodoModel extends Todo; contem fromJson/toJson
        todo_remote_datasource.dart         ← acesso HTTP (jsonplaceholder)
        todo_local_datasource.dart          ← persistencia SharedPreferences (lastSync)
        todo_repository_impl.dart           ← implementacao: decide entre remoto e local
      presentation/
        todo_viewmodel.dart                 ← ChangeNotifier; depende de TodoRepository (interface)
        todos_page.dart                     ← StatefulWidget; sem http, sem shared_preferences
        widgets/
          add_todo_dialog.dart              ← AlertDialog para criar novo TODO
          add_todo_dialog.dart                      ← AlertDialog para criar novo TODO
```

## Fluxo de Dependencias

```
main.dart
  └─ cria TodoRepositoryImpl (injetado no TodoViewModel)
  └─ AppRoot
       └─ TodosPage  ──read─→  TodoViewModel
                                 └─ TodoRepository (interface)
                                      └─ TodoRepositoryImpl
                                           ├─ TodoRemoteDataSource  (http)
                                           └─ TodoLocalDataSource   (shared_preferences)
```

## Tabela de Responsabilidades

| Arquivo | Camada | Responsabilidade |
|---|---|---|
| `todo_entity.dart` | domain | Estrutura de dados pura da entidade Todo |
| `todo_repository.dart` | domain | Contrato (interface) do repositorio; define TodoFetchResult |
| `todo_model.dart` | data | DTO com fromJson/toJson; estende Todo |
| `todo_remote_datasource.dart` | data | Requisicoes HTTP ao JSONPlaceholder |
| `todo_local_datasource.dart` | data | Leitura/escrita de lastSync via SharedPreferences |
| `todo_repository_impl.dart` | data | Unica classe que coordena o acesso remoto e local |
| `todo_viewmodel.dart` | presentation | Estado reativo via ChangeNotifier; sem widgets, sem BuildContext |
| `todos_page.dart` | presentation | UI da lista de todos; isolada de HTTP e SharedPreferences |
| `add_todo_dialog.dart` | presentation/widgets | Dialog de criacao de novo TODO (Widget) |
| `app_root.dart` | ui | Configuracao do MaterialApp, tema e rota principal |
| `app_errors.dart` | core | Excecao tipada (AppError) para uso global |

## Decisoes Arquiteturais

### Onde ficou a validacao?
Em TodoViewModel.addTodo(). A validacao de titulo vazio fica na camada de apresentacao (ViewModel), pois trata-se de uma regra de UX, nao uma regra estrita de negocio. Nenhuma logica previa foi alterada, apenas o local do arquivo foi ajustado.

### Onde ficou o parsing JSON?
Em TodoModel.fromJson() (Data Layer). A entidade Todo permanece absolutamente pura — sem metodos de conversao JSON e sem importar nada de data/. O TodoRepositoryImpl atua na fronteira, mapeando TodoModel → Todo.

### Por que TodoViewModel recebe TodoRepository via construtor?
Para respeitar o isolamento da apresentacao: *_viewmodel.dart nao deve importar implementacoes concretas. A injecao via construtor no main.dart isola a dependencia do TodoRepositoryImpl no entry point. Isso facilita a criacao de testes (usando mocks do repositorio) sem necessidade de alterar a logica interna do ViewModel.

### Decisoes conservadoras registradas
- app_root.dart mantido em lib/ui/ (nao em lib/features/) por ser infraestrutura da aplicacao, nao feature especifica.
- app_errors.dart movido para lib/core/errors/ por ser excecao compartilhavel entre features.
- Nenhuma logica interna foi alterada em nenhuma classe.

### Como voce tratou erros?

A abordagem utiliza tres camadas de tratamento, preservando a logica original do projeto:
  
  Data Layer: O TodoRemoteDataSource e direto. Se o status for diferente de 2xx, ele estoura uma Exception com o codigo HTTP e deixa o erro subir.

  ViewModel: Centraliza o controle. O TodoViewModel usa try/catch em todas as chamadas. Se der erro, ele atualiza o errorMessage, notifica a UI e, no caso do toggleCompleted, faz o rollback do estado local para manter a consistencia.

  UI (TodosPage): Trata o erro de forma condicional.
      Lista vazia: Tela de erro com botao de "Retry".
      Com cache: O erro e ignorado visualmente para nao atrapalhar a experiencia de quem ja esta vendo os dados.