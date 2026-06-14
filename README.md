# SteamQuest — Trabalho de Banco de Dados

**Universidade Católica Dom Bosco (UCDB)** — Banco de Dados — 4º semestre

E-commerce fictício de jogos digitais inspirado na Steam. Controla usuários, jogos, **keys digitais limitadas**, pedidos, pagamentos, biblioteca, avaliações e auditoria de preço.

> **SGBD:** PostgreSQL
> **Modelagem:** dbdiagram.io ([der/steamquest.dbml](der/steamquest.dbml))

---

## Sumário

1. [Descrição do sistema](#descrição-do-sistema)
2. [Integrantes](#integrantes)
3. [Modelagem / DER](#modelagem--der)
4. [Tabelas](#tabelas)
5. [Ordem de execução dos scripts](#ordem-de-execução-dos-scripts)
6. [Plano de commits por dupla](#plano-de-commits-por-dupla)
7. [Índices](#índices)
8. [Roles e Permissões](#roles-e-permissões)
9. [Triggers e Funções](#triggers-e-funções)
10. [Transação de Finalizar Pedido](#transação-de-finalizar-pedido)
11. [Views e Relatórios](#views-e-relatórios)
12. [Dados Iniciais](#dados-iniciais)
13. [Prints de execução](#prints-de-execução)
14. [Regras de Negócio](#regras-de-negócio)

---

## Descrição do sistema

O SteamQuest é uma plataforma fictícia de e-commerce de jogos digitais
inspirada na Steam. O banco modela o ciclo completo de venda: catálogo
de jogos, controle de keys digitais limitadas, pedidos, pagamentos,
biblioteca do usuário e avaliações.

O diferencial do modelo é o controle rigoroso de keys: cada jogo possui
um estoque finito de chaves digitais únicas. Uma key vendida nunca pode
ser revendida, e o pedido só é finalizado se houver key disponível para
cada item — garantia feita pela transação `fn_finalizar_pedido`.

---

## Integrantes

> Cada aluno edita **apenas a sua linha**. A contribuição deve descrever o que
> foi efetivamente feito (script, trigger, view, etc).

| #   | Nome completo             | Dupla | Contribuição                                                                                                                                                                                                                                                                                               |
| --- | ------------------------- | ----- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 01  | Heitor Fidelis            | 1-2   | DER + script 01 de criação de tabelas                                                                                                                                                                                                                                                                      |
| 02  | Felipe Rodrigues          | 1-2   | DER do SteamQuest em DBML + imagem exportada + Atualização do README                                                                                                                                                                                                                                       |
| 03  | Gabriel Felix             | 3-4   | Criação do script 03 de índices do banco de dados                                                                                                                                                                                                                                                          |
| 04  | Guilherme Acosta          | 3-4   | Documentação dos índices e atualização do README                                                                                                                                                                                                                                                           |
| 05  | Pietra Viegas             | 5-6   | Criação das roles admin_sq e operador_sq com definição de GRANTs e permissões administrativas/operacionais. Documentação das roles admin_sq e operador_sq no README.                                                                                                                                       |
| 06  | Kailani Menezes           | 5-6   | Criação da role cliente_sq com definição de GRANTs e REVOKEs para acesso controlado aos recursos da plataforma. Documentação da role cliente_sq e da estratégia de segurança baseada no princípio do menor privilégio.                                                                                     |
| 07  | Luis Felipe Andrade       | 7-8   | Implementação da trigger de auditoria de preço (trg_auditoria_preco_jogo), responsável por registrar alterações de preço dos jogos na tabela de auditoria. Implementação da trigger de recálculo automático do valor_total dos pedidos (trg_recalcular_valor_total) e documentação das triggers no README. |
| 08  | Vinícius Loureiro Cardoso | 7-8   | Implementação das triggers trg_key_validacao e trg_biblioteca_pos_pedido. Documentação das triggers no README.                                                                                                                                                                                             |
| 09  | Lucas Daniel Duarte Cabral | 9-10  | Implementação da transação `fn_finalizar_pedido` (script 08) com lock do pedido via `SELECT ... FOR UPDATE`, validações de status, geração do pagamento aprovado e finalização do pedido (que dispara a carga automática da biblioteca). Criação do teste de exemplo de chamada bem-sucedida da transação. |
| 10 | Pedro Ferreira Bastos | 9-10 | Implementação da reserva de keys utilizando `FOR UPDATE SKIP LOCKED`, evitando concorrência entre transações simultâneas. Tratamento de exceção para ausência de keys disponíveis, criação do teste de rollback e documentação da transação `fn_finalizar_pedido` no README. |                                                                                                                                                                                                                                                                           
| 11  | Vitor da Silva Chaves | 11-12 | Criação das views de relatórios (vw_top_jogos_vendidos, vw_receita_por_mes, vw_media_avaliacao_por_jogo, vw_estoque_keys) e inserção dos dados iniciais (script 07) para testes das regras de negócio. Documentação das views e dados no README.                                                                                                                                                                                                                                                                             
| 12  | Vitor da Silva Chaves | 11-12 | (Trabalho da dupla assumido integralmente pelo Aluno  11) |                                                                                                                                                                                                                                                                                             |

---

## Modelagem / DER

<!-- DUPLA 1-2 — preencher -->
<!-- 1. Subir o .png exportado do dbdiagram.io em /der/steamquest.png
     2. Colocar o link de visualização compartilhável do dbdiagram aqui
     3. Inserir a imagem abaixo -->

- Arquivo-fonte: [der/steamquest.dbml](der/steamquest.dbml)
- Link de visualização:(https://dbdiagram.io/d/6a1f1c57f15b4b04525b11d8)
- Imagem: ![alt text](Prints/DER_steamquest.png)

---

## Tabelas

| Tabela                 | Descrição                                                     |
| ---------------------- | ------------------------------------------------------------- |
| `usuario`              | Cliente da plataforma (email e CPF únicos).                   |
| `desenvolvedora`       | Estúdio que desenvolve o jogo.                                |
| `publicadora`          | Empresa que publica/distribui o jogo.                         |
| `jogo`                 | Catálogo de jogos digitais à venda.                           |
| `categoria`            | Gênero/categoria de jogo (RPG, FPS, Indie, etc).              |
| `jogo_categoria`       | Associativa N:N entre jogo e categoria.                       |
| `key_jogo`             | Key digital de um jogo (única e não-reutilizável).            |
| `pedido`               | Pedido feito por um usuário.                                  |
| `item_pedido`          | Item individual de um pedido, ligando jogo + key.             |
| `pagamento`            | Pagamento associado a um pedido.                              |
| `biblioteca_usuario`   | Jogos do usuário após pedido finalizado.                      |
| `avaliacao_jogo`       | Avaliação de um jogo por um usuário (nota 1 a 5).             |
| `auditoria_preco_jogo` | Log automático de alterações de preço (populado por trigger). |

---

## Ordem de execução dos scripts

Executar **nesta ordem exata** num banco PostgreSQL limpo:

```bash
psql -U postgres -d steamquest -f scripts/01_criacao_tabelas.sql
psql -U postgres -d steamquest -f scripts/03_indices.sql
psql -U postgres -d steamquest -f scripts/04_roles_permissoes.sql
psql -U postgres -d steamquest -f scripts/05_funcoes_triggers.sql
psql -U postgres -d steamquest -f scripts/06_views_relatorios.sql
psql -U postgres -d steamquest -f scripts/07_dados_iniciais.sql
psql -U postgres -d steamquest -f scripts/08_transacao_finalizar_pedido.sql
```

| Script                              | Responsável | Status      |
| ----------------------------------- | ----------- | ----------- |
| `01_criacao_tabelas.sql`            | Dupla 1-2   | ✅ Pronto   |
| `03_indices.sql`                    | Dupla 3-4   | ✅ Pronto   |
| `04_roles_permissoes.sql`           | Dupla 5-6   | ✅ Pronto   |
| `05_funcoes_triggers.sql`           | Dupla 7-8   | ✅ Pronto   |
| `06_views_relatorios.sql`           | Dupla 11-12 | ✅ Pronto   |
| `07_dados_iniciais.sql`             | Dupla 11-12 | ✅ Pronto   |
| `08_transacao_finalizar_pedido.sql` | Dupla 9-10  | ✅ Pronto   |

---

## Plano de commits por dupla

> **Regra de avaliação:** cada aluno precisa ter **no mínimo 2 commits relevantes** com autoria própria. Commits vazios, alterações mínimas ou só correção de acento **não contam**.
>
> Por isso, **dentro de cada dupla o trabalho é dividido antes de começar**. Cada aluno fica responsável por um pedaço lógico do script + uma seção do README. Assim, cada um faz 1 commit `feat:` (código) + 1 commit `docs:` (documentação) — 2 commits relevantes.

### Convenção de mensagens

| Prefixo  | Quando usar                                    |
| -------- | ---------------------------------------------- |
| `feat:`  | Nova funcionalidade (tabela, índice, trigger…) |
| `fix:`   | Correção de bug ou de constraint               |
| `docs:`  | Edição no README ou comentários no código      |
| `chore:` | Estrutura, gitignore, organização              |
| `test:`  | Inserção de exemplos / dados de teste          |

### 🟦 Dupla 1-2 — DER + Criação de tabelas

| Aluno   | Commit 1 (feat)                                                                                                          | Commit 2 (docs)                                              |
| ------- | ------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------ |
| Aluno A | `chore: estrutura inicial do repositorio` (`.gitignore` + esqueleto do README) + `feat: script 01 de criacao de tabelas` | `feat: script 01 de criacao de tabelas` (em commit separado) |
| Aluno B | `feat: DER do SteamQuest em DBML` (`der/steamquest.dbml` + `der/steamquest.png` exportado do dbdiagram.io)               | `docs: preenche descricao, modelagem e tabelas no README`    |

### 🟩 Dupla 3-4 — Índices

| Aluno   | Commit 1 (feat)                                              | Commit 2 (docs)                                              |
| ------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| Aluno A | `feat: indices em key_jogo, pedido e item_pedido`            | `docs: explica indices de keys e pedidos no README`          |
| Aluno B | `feat: indices em biblioteca_usuario, avaliacao_jogo e jogo` | `docs: explica indices de biblioteca e avaliacoes no README` |

### 🟧 Dupla 5-6 — Roles e Permissões

| Aluno   | Commit 1 (feat)                                      | Commit 2 (docs)                                          |
| ------- | ---------------------------------------------------- | -------------------------------------------------------- |
| Aluno A | `feat: cria roles admin_sq e operador_sq com GRANTs` | `docs: documenta roles admin e operador no README`       |
| Aluno B | `feat: cria role cliente_sq com GRANTs e REVOKEs`    | `docs: documenta role cliente e estrategia de seguranca` |

### 🟪 Dupla 7-8 — Triggers e Funções

| Aluno   | Commit 1 (feat)                                     | Commit 2 (feat / docs)                                  |
| ------- | --------------------------------------------------- | ------------------------------------------------------- |
| Aluno A | `feat: trigger auditoria preço do jogo preco_jogo ` | `feat: trigger recalcular valor total + docs no README` |
| Aluno B | `feat: trigger de validacao de status em key_jogo`  | `feat: trigger biblioteca pos-pedido + docs no README`  |

### 🟥 Dupla 9-10 — Transação de Finalizar Pedido

| Aluno   | Commit 1 (feat)                                                      | Commit 2 (test / docs)                                        |
| ------- | -------------------------------------------------------------------- | ------------------------------------------------------------- |
| Aluno A | `feat: funcao fn_finalizar_pedido com lock do pedido (FOR UPDATE)`   | `test: exemplo de chamada bem-sucedida da transacao`          |
| Aluno B | `feat: reserva de keys com FOR UPDATE SKIP LOCKED + RAISE EXCEPTION` | `test: exemplo de ROLLBACK quando falta key + docs no README` |

### 🟨 Dupla 11-12 — Views, Dados Iniciais e Fechamento do README

| Aluno   | Commit 1 (feat)                                                                                                      | Commit 2 (feat / docs)                                          |
| ------- | -------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------- |
| Aluno A | `feat: views vw_top_jogos_vendidos e vw_receita_por_mes` + INSERTs de usuários, devs, publishers, categorias e jogos | `docs: prints de execucao + secao Views e Relatorios no README` |
| Aluno B | `feat: views vw_media_avaliacao_por_jogo e vw_estoque_keys` + INSERTs de keys, pedidos e avaliações                  | `docs: secao Dados Iniciais + revisao final do README`          |

### Como cada aluno garante a própria autoria

No PC de cada um, antes do primeiro commit:

```bash
git config user.name "Seu Nome Completo"
git config user.email "seu_email@dominio.com"
```

Para conferir antes de commitar:

```bash
git config user.name
git config user.email
```

---

## Índices

<!-- DUPLA 3-4 — preencher -->
<!-- Para cada índice criado em scripts/03_indices.sql, escrever 1 linha:
     - NOME do índice
     - TABELA e colunas
     - QUAL consulta ele acelera (justificativa) -->

- **`idx_key_jogo_jogo_status`** (`key_jogo(jogo_id, status)`) — Acelera a busca de chaves digitais disponíveis (filtradas por status) para um determinado jogo, otimizando o processo de venda.
- **`idx_pedido_usuario`** (`pedido(usuario_id)`) — Acelera a consulta e exibição do histórico de pedidos de um usuário na plataforma.
- **`idx_pedido_status`** (`pedido(status)`) — Otimiza relatórios e consultas que filtram pedidos pelo estado da compra (ex: pendente, finalizado, cancelado).
- **`idx_item_pedido_pedido`** (`item_pedido(pedido_id)`) — Agiliza a busca de todos os itens vinculados a um pedido específico ao exibir os detalhes do carrinho ou da compra.
- **`idx_item_pedido_jogo`** (`item_pedido(jogo_id)`) — Acelera consultas de vendas e estatísticas de popularidade por jogo.
- **`idx_biblioteca_usuario`** (`biblioteca_usuario(usuario_id)`) — Acelera a listagem de jogos que pertencem à biblioteca de um usuário específico.
- **`idx_avaliacao_jogo`** (`avaliacao_jogo(jogo_id)`) — Otimiza consultas para calcular a média de notas de um jogo e listar suas avaliações correspondentes.
- **`idx_avaliacao_usuario`** (`avaliacao_jogo(usuario_id)`) — Acelera a busca de todas as avaliações que um usuário específico realizou.
- **`idx_jogo_titulo`** (`jogo(titulo)`) — Otimiza a pesquisa de jogos por título na barra de buscas da loja, acelerando a filtragem por texto.

---

## Roles e Permissões

<!-- DUPLA 5-6 — preencher -->
<!-- Tabela com as 3 roles criadas em scripts/04_roles_permissoes.sql.
     Para cada uma, explicar: o que pode SELECT, INSERT, UPDATE, DELETE. -->

| Role          | Permissões                                                                                                                                                                                                                                                                                                                                                                                                                              |
| ------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `admin_sq`    | Role administrativa do sistema. Possui permissão de `SELECT`, `INSERT`, `UPDATE` e `DELETE` em todas as tabelas do schema `public`, além de permissão de uso, consulta e atualização das sequences.                                                                                                                                                                                                                                     |
| `operador_sq` | Role voltada para operadores internos da plataforma. Pode consultar usuários, gerenciar catálogo, desenvolvedoras, publicadoras, categorias, jogos, keys, pedidos, itens, pagamentos e biblioteca. Possui permissão de `SELECT`, `INSERT` e `UPDATE` nas tabelas operacionais, apenas `SELECT` em avaliações e auditoria de preços, e não possui permissão de `DELETE`.                                                                 |
| `cliente_sq`  | Role clientes da plataforma. Possui permissão de SELECT no catálogo de jogos, categorias, desenvolvedoras e publicadoras. Pode consultar sua biblioteca, realizar consultas e registros de pedidos, além de cadastrar avaliações de jogos. Possui permissão de SELECT e UPDATE em seus dados de usuário. Não possui acesso às tabelas de auditoria e keys digitais, nem permissões de DELETE, seguindo o princípio do menor privilégio. |

---

## Triggers e Funções

<!-- DUPLA 7-8 — preencher -->
<!-- Para cada trigger em scripts/05_funcoes_triggers.sql, escrever:
     - NOME do trigger
     - EVENTO (BEFORE/AFTER, INSERT/UPDATE/DELETE, em qual tabela)
     - OBJETIVO (regra de negócio que ele garante) -->

- **`trg_auditoria_preco_jogo`** — Trigger AFTER UPDATE na tabela `jogo`. Registra automaticamente alterações de preço na tabela `auditoria_preco_jogo`, armazenando o valor antigo, o novo valor, o usuário do banco e a data da alteração.

- **`trg_recalcular_valor_total`** — Trigger AFTER INSERT, UPDATE ou DELETE na tabela `item_pedido`. Recalcula automaticamente o campo `valor_total` da tabela `pedido`, garantindo que o total reflita corretamente os itens associados ao pedido.

- **`trg_key_validacao`** — Trigger BEFORE UPDATE na tabela `key_jogo`. Impede que uma key marcada como vendida retorne para outro status, garantindo a integridade do estoque digital e evitando a reutilização de chaves já comercializadas.

- **`trg_biblioteca_pos_pedido`** — Trigger AFTER UPDATE na tabela `pedido`. Quando um pedido é finalizado, adiciona automaticamente os jogos adquiridos à biblioteca do usuário, garantindo que a biblioteca reflita corretamente as compras.

---

## Transação de Finalizar Pedido

<!-- DUPLA 9-10 — preencher -->
<!-- Explicar passo a passo o que a função fn_finalizar_pedido() faz:
     1. Como trava o pedido (SELECT ... FOR UPDATE)
     2. Como reserva uma key disponível por item (FOR UPDATE SKIP LOCKED)
     3. O que acontece se faltar key
     4. Como atualiza status, gera pagamento e dispara o trigger de biblioteca
     Incluir exemplo de chamada da função. -->

A função `fn_finalizar_pedido()` é responsável por concluir o processo de compra de forma segura e consistente, garantindo a integridade dos dados mesmo em cenários de acesso concorrente ao banco de dados.

- Utiliza `SELECT ... FOR UPDATE` para impedir que duas transações finalizem o mesmo pedido simultaneamente.
- Reserva uma key disponível para cada item do pedido.
- Utiliza `FOR UPDATE SKIP LOCKED` para evitar que duas transações concorrentes utilizem a mesma key.
- Caso não exista key disponível para algum dos jogos do pedido, a função gera uma exceção (`RAISE EXCEPTION`), interrompendo a execução e garantindo o rollback automático da transação.
- Após reservar as keys, registra o pagamento aprovado.
- Por fim, altera o pedido para `finalizado`, disparando a trigger que adiciona os jogos à biblioteca do usuário.

### Exemplo de chamada

A função pode ser executada informando o ID do pedido e o método de pagamento:

```sql
SELECT fn_finalizar_pedido(1, 'pix');
```

Após a execução:
- As keys são reservadas e marcadas como vendidas.
- O pagamento é registrado como aprovado.
- O pedido passa para o status `finalizado`.
- Os jogos são adicionados automaticamente à biblioteca do usuário pela trigger `trg_biblioteca_pos_pedido`.

---

## Views e Relatórios

<!-- DUPLA 11-12 — preencher -->
<!-- Para cada view criada em scripts/06_views_relatorios.sql:
     - NOME da view
     - O QUE ela mostra
     - Pequeno exemplo de SELECT -->

_A preencher pela Dupla 11-12._

- **`vw_top_jogos_vendidos`** Retorna o ranking dos jogos mais vendidos na plataforma, contabilizando o total de cópias e a receita gerada. Considera estritamente os pedidos com status 'finalizado'.
- **`vw_receita_por_mes`** Calcula o faturamento total da loja agrupado por ano e mês, baseado unicamente nos pagamentos com status 'aprovado', facilitando o acompanhamento financeiro.
- **`vw_media_avaliacao_por_jogo`** Exibe a nota média e o número total de avaliações de cada jogo, ordenando o catálogo dos títulos mais bem avaliados para os piores.
- **`vw_estoque_keys`** Apresenta um painel de controle crítico do estoque digital, contabilizando de forma agregada quantas chaves estão disponíveis, vendidas, reservadas ou canceladas para cada jogo.

---

## Dados Iniciais

<!-- DUPLA 11-12 — preencher -->
<!-- Resumir o que tem em scripts/07_dados_iniciais.sql:
     - Quantos usuários, jogos, keys, pedidos, avaliações
     - Estados variados (pedido pendente / finalizado / cancelado, etc) -->

O banco foi populado com um conjunto robusto de dados para permitir a validação imediata de todas as regras de negócio, triggers e da transação principal do sistema. A carga (script 07) inclui:
* **Cadastros Base:** 3 usuários ativos (com CPFs e emails únicos), 3 desenvolvedoras, 3 publicadoras e 3 categorias de jogos (JRPG, Hero Shooter, Ação TPS).
* **Catálogo e Estoque:** 4 jogos variados vinculados às suas categorias e um lote de keys digitais exclusivas, distribuídas entre os status `disponivel` e `vendida`.
* **Histórico de Vendas:** Simulação de 2 pedidos retroativos já concluídos, contendo a amarração completa de itens (jogos e keys), pagamentos aprovados e a consequente inserção dos jogos na tabela `biblioteca_usuario`.
* **Interação Social:** Avaliações de jogos registradas pelos usuários com notas e comentários, testando o relacionamento entre as contas e o catálogo.

---

## Prints de execução

<!-- DUPLA 11-12 — coordenar; cada dupla pode adicionar o print da sua parte -->
<!-- Salvar imagens em /prints/ e referenciá-las aqui. -->

![Resultado das Views](Prints/print_view.png)
*Consulta realizada nas views de relatórios.*

![Dados Iniciais](Prints/print_dados.png)
*Registros populados através do script 07 de dados iniciais.*

---

## Regras de Negócio

Regras garantidas pelo banco (via constraints, triggers e a transação):

- Um usuário pode realizar vários pedidos.
- Um pedido pode conter vários jogos.
- Um jogo pode pertencer a várias categorias (e vice-versa).
- Um jogo pode possuir várias keys digitais; **cada key é única**.
- Status válidos de key: `disponivel`, `reservada`, `vendida`, `cancelada`.
- **Uma key vendida não pode ser vendida novamente.**
- **Um usuário não pode receber duas vezes a mesma key.**
- O total do pedido é calculado a partir dos itens (trigger).
- **Um pedido só é finalizado se houver key disponível para cada jogo comprado.**
- Ao finalizar o pedido, o jogo entra automaticamente na biblioteca do usuário.
- Preço de jogo nunca pode ser negativo; quantidade nunca pode ser ≤ 0.
- Dados duplicados indevidos são bloqueados por `UNIQUE` (email, CPF, código de key, par usuário+jogo em avaliação, etc).

---

## Estrutura do repositório

```
├── README.md                ← este arquivo
├── .gitignore
├── der/
│   ├── steamquest.dbml      ← fonte (dbdiagram.io)
│   └── steamquest.png       ← imagem exportada
├── scripts/
│   ├── 01_criacao_tabelas.sql
│   ├── 03_indices.sql
│   ├── 04_roles_permissoes.sql
│   ├── 05_funcoes_triggers.sql
│   ├── 06_views_relatorios.sql
│   ├── 07_dados_iniciais.sql
│   └── 08_transacao_finalizar_pedido.sql
├── prints/                  ← screenshots de execução
└── docs/                    ← anotações extras 
```
