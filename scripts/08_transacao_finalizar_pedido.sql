-- =====================================================================
-- SteamQuest - 08_transacao_finalizar_pedido.sql
-- Dupla 9-10 - Transacao de Finalizar Pedido
-- Aluno A: funcao fn_finalizar_pedido com lock do pedido (FOR UPDATE)
--
-- Ordem de execucao: rodar APOS 01_criacao_tabelas.sql e
-- 05_funcoes_triggers.sql. Depende das tabelas e da trigger
-- trg_biblioteca_pos_pedido, que popula a biblioteca do usuario
-- quando o pedido passa para o status 'finalizado'.
-- =====================================================================

CREATE OR REPLACE FUNCTION fn_finalizar_pedido(
    p_pedido_id BIGINT,
    p_metodo    VARCHAR DEFAULT 'pix'
)
RETURNS VOID AS $$
DECLARE
    v_pedido  pedido%ROWTYPE;
    v_item    RECORD;
    v_key_id  BIGINT;
BEGIN
    -- -----------------------------------------------------------------
    -- 1) LOCK DO PEDIDO (Aluno A)
    -- Trava a linha do pedido com FOR UPDATE. Isso impede que duas
    -- transacoes concorrentes finalizem o mesmo pedido ao mesmo tempo:
    -- a segunda chamada fica bloqueada ate a primeira terminar
    -- (COMMIT ou ROLLBACK), evitando finalizacao em duplicidade.
    -- -----------------------------------------------------------------
    SELECT *
      INTO v_pedido
      FROM pedido
     WHERE id = p_pedido_id
       FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Pedido % nao encontrado.', p_pedido_id;
    END IF;

    -- So finaliza pedidos que ainda estao abertos.
    IF v_pedido.status NOT IN ('pendente', 'pago') THEN
        RAISE EXCEPTION
            'Pedido % nao pode ser finalizado (status atual: %).',
            p_pedido_id, v_pedido.status;
    END IF;

    -- O pedido precisa ter pelo menos um item.
    IF NOT EXISTS (SELECT 1 FROM item_pedido WHERE pedido_id = p_pedido_id) THEN
        RAISE EXCEPTION 'Pedido % nao possui itens.', p_pedido_id;
    END IF;

    -- -----------------------------------------------------------------
    -- 2) RESERVA DE KEYS POR ITEM
    -- Para cada item ainda sem key, reserva uma key disponivel do jogo,
    -- marca a key como 'vendida' e vincula a key ao item do pedido.
    --
    -- [Aluno B] Este bloco sera reforcado: a busca da key usara
    -- FOR UPDATE SKIP LOCKED (para que vendas concorrentes nao briguem
    -- pela mesma key) e o RAISE EXCEPTION de "sem key" sera tratado
    -- junto com o teste de ROLLBACK.
    -- -----------------------------------------------------------------
    FOR v_item IN
        SELECT id, jogo_id
          FROM item_pedido
         WHERE pedido_id = p_pedido_id
           AND key_id IS NULL
    LOOP
        SELECT id
          INTO v_key_id
          FROM key_jogo
         WHERE jogo_id = v_item.jogo_id
           AND status  = 'disponivel'
         ORDER BY id
         LIMIT 1
           FOR UPDATE;

        IF v_key_id IS NULL THEN
            RAISE EXCEPTION
                'Sem key disponivel para o jogo % (item %).',
                v_item.jogo_id, v_item.id;
        END IF;

        -- Marca a key como vendida. A trigger trg_key_validacao garante
        -- que uma key vendida nunca volta para outro status.
        UPDATE key_jogo
           SET status     = 'vendida',
               data_venda = CURRENT_TIMESTAMP
         WHERE id = v_key_id;

        -- Vincula a key ao item do pedido.
        UPDATE item_pedido
           SET key_id = v_key_id
         WHERE id = v_item.id;
    END LOOP;

    -- -----------------------------------------------------------------
    -- 3) PAGAMENTO (Aluno A)
    -- Gera o pagamento aprovado com o valor total do pedido (ja calculado
    -- pela trigger trg_recalcular_valor_total a cada item inserido).
    -- -----------------------------------------------------------------
    INSERT INTO pagamento (pedido_id, metodo, status, valor_pago, data_pagamento)
    VALUES (p_pedido_id, p_metodo, 'aprovado', v_pedido.valor_total, CURRENT_TIMESTAMP);

    -- -----------------------------------------------------------------
    -- 4) FINALIZACAO (Aluno A)
    -- Atualiza o status para 'finalizado'. Isso dispara a trigger
    -- trg_biblioteca_pos_pedido, que insere os jogos na biblioteca do
    -- usuario usando a key reservada em cada item.
    -- -----------------------------------------------------------------
    UPDATE pedido
       SET status = 'finalizado'
     WHERE id = p_pedido_id;

    RAISE NOTICE 'Pedido % finalizado com sucesso (pagamento via %).',
                 p_pedido_id, p_metodo;
END;
$$ LANGUAGE plpgsql;


-- =====================================================================
-- TESTE (Aluno A): exemplo de chamada bem-sucedida da transacao
--
-- Roda dentro de uma transacao com ROLLBACK ao final, entao serve como
-- demonstracao sem sujar o banco. Os RAISE NOTICE comprovam o resultado:
-- pedido finalizado, pagamento aprovado, key vendida e jogo na biblioteca.
-- =====================================================================
BEGIN;

DO $$
DECLARE
    v_dev_id           BIGINT;
    v_pub_id           BIGINT;
    v_jogo_id          BIGINT;
    v_usuario_id       BIGINT;
    v_pedido_id        BIGINT;
    v_status_pedido    pedido.status%TYPE;
    v_status_pagamento pagamento.status%TYPE;
    v_status_key       key_jogo.status%TYPE;
    v_qtd_biblioteca   INT;
BEGIN
    -- 1) Massa de teste minima (jogo com 1 key disponivel + pedido com 1 item)
    INSERT INTO desenvolvedora (nome) VALUES ('Dev Teste') RETURNING id INTO v_dev_id;
    INSERT INTO publicadora    (nome) VALUES ('Pub Teste') RETURNING id INTO v_pub_id;

    INSERT INTO jogo (titulo, preco, desenvolvedora_id, publicadora_id)
    VALUES ('Jogo de Teste', 59.90, v_dev_id, v_pub_id)
    RETURNING id INTO v_jogo_id;

    INSERT INTO key_jogo (jogo_id, codigo_key)
    VALUES (v_jogo_id, 'KEY-TESTE-0001');

    INSERT INTO usuario (nome, email, senha_hash, cpf, data_nascimento)
    VALUES ('Cliente Teste', 'cliente.teste@steamquest.dev', 'hash_teste',
            '123.456.789-00', DATE '2000-01-01')
    RETURNING id INTO v_usuario_id;

    INSERT INTO pedido (usuario_id) VALUES (v_usuario_id)
    RETURNING id INTO v_pedido_id;

    INSERT INTO item_pedido (pedido_id, jogo_id, preco_unitario)
    VALUES (v_pedido_id, v_jogo_id, 59.90);

    -- 2) Chamada da transacao de finalizar pedido
    PERFORM fn_finalizar_pedido(v_pedido_id, 'pix');

    -- 3) Verificacoes (provam que a transacao funcionou)
    SELECT status   INTO v_status_pedido    FROM pedido             WHERE id = v_pedido_id;
    SELECT status   INTO v_status_pagamento FROM pagamento          WHERE pedido_id = v_pedido_id;
    SELECT status   INTO v_status_key       FROM key_jogo           WHERE jogo_id = v_jogo_id;
    SELECT COUNT(*) INTO v_qtd_biblioteca   FROM biblioteca_usuario WHERE usuario_id = v_usuario_id;

    RAISE NOTICE '--- RESULTADO DO TESTE (chamada bem-sucedida) ---';
    RAISE NOTICE 'Pedido %: status = %', v_pedido_id, v_status_pedido;        -- finalizado
    RAISE NOTICE 'Pagamento: status = %', v_status_pagamento;                 -- aprovado
    RAISE NOTICE 'Key do jogo %: status = %', v_jogo_id, v_status_key;        -- vendida
    RAISE NOTICE 'Itens na biblioteca do usuario %: %', v_usuario_id, v_qtd_biblioteca; -- 1

    IF v_status_pedido = 'finalizado'
       AND v_status_pagamento = 'aprovado'
       AND v_qtd_biblioteca = 1 THEN
        RAISE NOTICE 'TESTE OK: pedido finalizado, pagamento aprovado e jogo na biblioteca.';
    ELSE
        RAISE EXCEPTION 'TESTE FALHOU: estado inesperado apos finalizar o pedido.';
    END IF;
END $$;

ROLLBACK;
