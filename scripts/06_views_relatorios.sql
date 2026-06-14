-- ==============================================================================
-- Script 06: Views e Relatórios
-- Descrição: Criação de views para análise de vendas, receitas, avaliações e estoque.
-- ==============================================================================

-- 1. vw_top_jogos_vendidos
-- Retorna os jogos mais vendidos contabilizando apenas os pedidos finalizados.
CREATE OR REPLACE VIEW vw_top_jogos_vendidos AS
SELECT
    j.id AS jogo_id,
    j.titulo,
    SUM(ip.quantidade) AS total_copias_vendidas,
    SUM(ip.preco_unitario * ip.quantidade) AS receita_total
FROM jogo j
JOIN item_pedido ip ON j.id = ip.jogo_id
JOIN pedido p ON ip.pedido_id = p.id
WHERE p.status = 'finalizado'
GROUP BY j.id, j.titulo
ORDER BY total_copias_vendidas DESC;

-- 2. vw_receita_por_mes
-- Calcula o faturamento da plataforma agrupado por ano e mês, baseado nos pagamentos aprovados.
CREATE OR REPLACE VIEW vw_receita_por_mes AS
SELECT
    EXTRACT(YEAR FROM pg.data_pagamento) AS ano,
    EXTRACT(MONTH FROM pg.data_pagamento) AS mes,
    SUM(pg.valor_pago) AS receita_total
FROM pagamento pg
WHERE pg.status = 'aprovado'
GROUP BY ano, mes
ORDER BY ano DESC, mes DESC;

-- 3. vw_media_avaliacao_por_jogo
-- Calcula a nota média e o total de avaliações de cada jogo.
CREATE OR REPLACE VIEW vw_media_avaliacao_por_jogo AS
SELECT
    j.id AS jogo_id,
    j.titulo,
    ROUND(AVG(a.nota), 2) AS media_notas,
    COUNT(a.id) AS total_avaliacoes
FROM jogo j
LEFT JOIN avaliacao_jogo a ON j.id = a.jogo_id
GROUP BY j.id, j.titulo
ORDER BY media_notas DESC NULLS LAST;

-- 4. vw_estoque_keys
-- Mostra a quantidade de chaves em cada status para controle de disponibilidade.
CREATE OR REPLACE VIEW vw_estoque_keys AS
SELECT
    j.id AS jogo_id,
    j.titulo,
    COUNT(kj.id) FILTER (WHERE kj.status = 'disponivel') AS keys_disponiveis,
    COUNT(kj.id) FILTER (WHERE kj.status = 'vendida') AS keys_vendidas,
    COUNT(kj.id) FILTER (WHERE kj.status = 'reservada') AS keys_reservadas,
    COUNT(kj.id) FILTER (WHERE kj.status = 'cancelada') AS keys_canceladas
FROM jogo j
LEFT JOIN key_jogo kj ON j.id = kj.jogo_id
GROUP BY j.id, j.titulo
ORDER BY keys_disponiveis ASC;