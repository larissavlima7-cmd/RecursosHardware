# App de Registro de Ponto com Geolocalização e Biometria

## Descrição
Um aplicativo que permite ao funcionário registrar seu ponto de trabalho quando estiver a até 100 metros do local de trabalho. A autenticação pode ser feita via NIF/email e senha ou utilizando reconhecimento facial via biometria.
- Funcionalidades:
Autenticação por NIF/email e senha ou reconhecimento facial.
Verificação de localização usando geolocalização.
Armazenamento do registro de ponto com data, hora e localização.
Integração com Firebase para autenticação e armazenamento dos dados.

## Ferramentas
Para essa aplicação funcionar é preciso ter instalado na máquina o Flutter SDK, Android Studio ou BlueStacks para a execução, VsCode e conta no Firebase.

Para a execução do projeto será utilizado as bibliotecas `geolocator` e `local_auth` que pode ser lida na documentação do flutter em `pub.dev`. Além disso, será preciso uma integração com o Firebase, uma plataforma do Google que atua como um servidor em nuvem. Ele vai ser importante para a autenticação de senhas e para o banco de dados. E para integração é necessário instalar os pacotes no projeto `firebase_core`, `firebase_auth`, `cloud_firestore`.


## Instalação e Uso
Boa parte das ferramentas já estavam instaladas na minha máquina, faltava apenas o Firebase. O firebase não é um programa que precisa ser instalado, e sim, conectado ao código do Flutter. 
Para isso:
1. acesse o Console do Firebase com uma conta pessoal do google;
2. Clique em crie um projeto;
3. Nomeie o projeto e conclua a criação;
4. No menu lateral esquerdo, pesquise por "Authentication" na barra de pesquisa no topo;
5. Clica em Authentication e depois no botão Começar.
6. Na lista de fornecedores, clica em E-mail/Palavra-passe.
7. Ativa o primeiro interruptor e clica em Salvar.
8. Para criar o bd, pesquise por Firestore;
9. Clique no botão Criar base de dados.
10. Seleciona a opção Iniciar no modo de teste (permite a leitura e escrita de dados sem bloqueios de permissões durante o desenvolvimento).
11. Clica em Seguinte.
12. Mantém a localização do servidor predefinida e clica em Ativar. 

#### Integração Firebase com Flutter
No projeto já criado em Flutter, instale as ferramentas do firebase com o comando `npm install -g firebase-tools` no terminal dentro do seu projeto. Depois é preciso adicionar temporariamente o caminho do NPM ao ambeinte através do comando `$env:Path += ";$env:APPDATA\npm"`, então autenticar o firebase por meio do login `firebase login`, ativar o flutterfire CLI `dart pub global activate flutterfire_cli` e por fim configurar a conexaão com o projeto `dart pub global run flutterfire_cli:flutterfire configure`.

#### Instalando as dependencias
Para que seja possivel utilizar as bibliotecas é preciso instalar as dependencias através do terminal com o comando `flutter pub add firebase_core firebase_auth cloud_firestore geolocator local_auth`.