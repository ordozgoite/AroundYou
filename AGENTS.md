# Around You iOS

## Stack e projeto

- Swift/SwiftUI no target `WhatsGoingNearby` de `WhatsGoingNearby.xcodeproj`.
- Deployment target do app: iOS 16.4 em Debug e Release.
- Swift Package Manager: Firebase, Lottie, Socket.IO Client, SwiftUI Sliders, Kingfisher e PhoneNumberKit.
- Integrações Apple incluem Core Location, MapKit, UserNotifications e BackgroundTasks.

## Arquitetura e organização

O projeto segue MVVM pragmático, sem camada arquitetural rígida:

- `Screen/`: telas SwiftUI por feature; view models geralmente ficam ao lado das views.
- `Component/`: componentes SwiftUI reutilizáveis.
- `Model/`: modelos `Codable`, DTOs, enums e respostas.
- `Network/`: endpoints, cliente HTTP e serviços.
- `Manager/`: localização, notificações e ciclo de vida.
- `Navigation/`: rotas e coordenador.
- `Extension/`, `Util/`, `Mocks/`, `Assets.xcassets` e `Localize/`: suporte, mocks, assets e localização.

## SwiftUI, navegação e estado

- Construir interfaces com views e `@ViewBuilder`; extrair seções privadas quando a tela cresce.
- View models conformam a `ObservableObject`, usam `@Published` e, quando atualizam UI, frequentemente `@MainActor`.
- Usar `@StateObject` para propriedade do ciclo de vida, `@ObservedObject`/`@EnvironmentObject` para dependências e `@Binding` para estado do pai.
- `NavigationCoordinator` mantém `[AppRoute]`; `WhatsGoingNearbyApp` injeta autenticação, socket, localização e feed via environment.
- Preservar o estilo da feature adjacente; código legado e moderno coexistem.

## Serviços, rede e dados

- `AYEndpoints` descreve requisições; `HTTPClient` usa `URLSession`, `async/await`, `Codable` e `Result<T, RequestError>`.
- `AYServices.shared` expõe operações de domínio.
- Firebase atende Auth, Storage e Messaging; Socket.IO atende tempo real; Kingfisher atende imagens.
- Existe modelo Core Data e helpers, mas `PersistenceController.swift` está comentado. Não presumir persistência Core Data ativa sem verificar o fluxo.

## Localização, assets e testes

- Strings: `WhatsGoingNearby/Localize/Localizable.xcstrings`.
- Assets e AppIcon: `WhatsGoingNearby/Assets.xcassets`; previews usam `Preview Content` e `Mocks`.
- Não foi encontrado target XCTest/UI Test. `WhatsGoingNearby/Test/` contém views/utilitários manuais.

Build comprovável a partir da raiz:

```sh
xcodebuild -project WhatsGoingNearby.xcodeproj -scheme WhatsGoingNearby -configuration Debug -sdk iphonesimulator build CODE_SIGNING_ALLOWED=NO
```

Não documentar `xcodebuild test` como disponível sem target de testes.

## Replicação iOS → Android

- Durante replicações, este repositório é estritamente somente leitura.
- Não alterar, formatar, mover, renomear ou excluir arquivos iOS.
- Modificar o iOS somente mediante pedido explícito do usuário.
- Consulta como referência não autoriza correções ou melhorias.
- Verificar o estado Git antes e depois e preservar alterações preexistentes.
