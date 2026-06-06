-- =====================================================================
-- SteamQuest - 04_roles_permissoes.sql
-- Trabalho de Banco de Dados - 4o semestre UCDB
-- Responsável: Dupla 5-6
-- Parte Aluno A: roles admin_sq e operador_sq
-- =====================================================================


-- =====================================================================
-- LIMPEZA DAS ROLES
-- =====================================================================
-- Remove as roles caso já existam, evitando erro ao executar o script novamente.

DROP ROLE IF EXISTS admin_sq;
DROP ROLE IF EXISTS operador_sq;


-- =====================================================================
-- CRIAÇÃO DAS ROLES
-- =====================================================================

CREATE ROLE admin_sq;
CREATE ROLE operador_sq;


-- =====================================================================
-- PERMISSÕES GERAIS DE USO DO SCHEMA
-- =====================================================================

GRANT USAGE ON SCHEMA public TO admin_sq;
GRANT USAGE ON SCHEMA public TO operador_sq;


-- =====================================================================
-- ADMIN_SQ
-- Administrador do sistema.
-- Pode consultar, inserir, alterar e excluir dados em todas as tabelas.
-- =====================================================================

GRANT SELECT, INSERT, UPDATE, DELETE
ON ALL TABLES IN SCHEMA public
TO admin_sq;

GRANT USAGE, SELECT, UPDATE
ON ALL SEQUENCES IN SCHEMA public
TO admin_sq;


-- =====================================================================
-- OPERADOR_SQ
-- Operador interno da plataforma.
-- Pode consultar usuários, gerenciar catálogo, keys, pedidos e pagamentos.
-- Não possui DELETE para evitar remoção indevida de dados importantes.
-- =====================================================================

GRANT SELECT
ON usuario
TO operador_sq;

GRANT SELECT, INSERT, UPDATE
ON desenvolvedora, publicadora, jogo, categoria, jogo_categoria
TO operador_sq;

GRANT SELECT, INSERT, UPDATE
ON key_jogo, pedido, item_pedido, pagamento, biblioteca_usuario
TO operador_sq;

GRANT SELECT
ON avaliacao_jogo, auditoria_preco_jogo
TO operador_sq;

GRANT USAGE, SELECT
ON ALL SEQUENCES IN SCHEMA public
TO operador_sq;


-- =====================================================================
-- PERMISSÕES PADRÃO PARA FUTURAS TABELAS E SEQUENCES
-- =====================================================================
-- Garante permissões para objetos criados futuramente no schema public.

ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO admin_sq;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT USAGE, SELECT, UPDATE ON SEQUENCES TO admin_sq;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT SELECT, INSERT, UPDATE ON TABLES TO operador_sq;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT USAGE, SELECT ON SEQUENCES TO operador_sq;


-- =====================================================================
-- FIM DO SCRIPT 04 - PARTE ALUNO A
-- =====================================================================