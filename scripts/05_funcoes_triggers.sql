-- ============================================================
-- Dupla 7-8 - Triggers e Funções
-- Aluno A
-- ============================================================

-- ============================================================
-- Trigger de Auditoria de Preço
-- ============================================================

CREATE OR REPLACE FUNCTION fn_auditar_preco_jogo()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO auditoria_preco_jogo (
        jogo_id,
        preco_antigo,
        preco_novo,
        usuario_db
    )
    VALUES (
        OLD.id,
        OLD.preco,
        NEW.preco,
        CURRENT_USER
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_auditoria_preco_jogo
AFTER UPDATE OF preco
ON jogo
FOR EACH ROW
WHEN (OLD.preco IS DISTINCT FROM NEW.preco)
EXECUTE FUNCTION fn_auditar_preco_jogo();


-- ============================================================
-- Trigger de Cálculo Automático do Valor Total do Pedido
-- ============================================================

CREATE OR REPLACE FUNCTION fn_recalcular_valor_total()
RETURNS TRIGGER AS $$
DECLARE
    v_pedido_id BIGINT;
BEGIN

    v_pedido_id := COALESCE(NEW.pedido_id, OLD.pedido_id);

    UPDATE pedido
    SET valor_total = COALESCE(
        (
            SELECT SUM(preco_unitario * quantidade)
            FROM item_pedido
            WHERE pedido_id = v_pedido_id
        ),
        0
    )
    WHERE id = v_pedido_id;

    RETURN COALESCE(NEW, OLD);

END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_recalcular_valor_total
AFTER INSERT OR UPDATE OR DELETE
ON item_pedido
FOR EACH ROW
EXECUTE FUNCTION fn_recalcular_valor_total();
