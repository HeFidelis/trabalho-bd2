-- =====================================================================
-- SteamQuest - 03_indices.sql
-- Trabalho de Banco de Dados - 4o semestre UCDB
-- Responsável: Dupla 3-4
-- =====================================================================


-- =====================================================================
-- KEY_JOGO
-- Busca de keys disponíveis para venda
-- =====================================================================
CREATE INDEX idx_key_jogo_jogo_status
ON key_jogo (jogo_id, status);


-- =====================================================================
-- PEDIDO
-- Consultas de pedidos por usuário e status
-- =====================================================================
CREATE INDEX idx_pedido_usuario
ON pedido (usuario_id);

CREATE INDEX idx_pedido_status
ON pedido (status);


-- =====================================================================
-- ITEM_PEDIDO
-- Consultas de itens por pedido e por jogo
-- =====================================================================
CREATE INDEX idx_item_pedido_pedido
ON item_pedido (pedido_id);

CREATE INDEX idx_item_pedido_jogo
ON item_pedido (jogo_id);


-- =====================================================================
-- BIBLIOTECA_USUARIO
-- Biblioteca de jogos de um usuário
-- =====================================================================
CREATE INDEX idx_biblioteca_usuario
ON biblioteca_usuario (usuario_id);


-- =====================================================================
-- AVALIACAO_JOGO
-- Relatórios de avaliações
-- =====================================================================
CREATE INDEX idx_avaliacao_jogo
ON avaliacao_jogo (jogo_id);

CREATE INDEX idx_avaliacao_usuario
ON avaliacao_jogo (usuario_id);


-- =====================================================================
-- JOGO
-- Pesquisa de jogos por título
-- =====================================================================
CREATE INDEX idx_jogo_titulo
ON jogo (titulo);


-- =====================================================================
-- FIM DO SCRIPT 03
-- =====================================================================