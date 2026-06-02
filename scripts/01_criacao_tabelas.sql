-- =====================================================================
-- SteamQuest - 01_criacao_tabelas.sql
-- Trabalho de Banco de Dados - 4o semestre UCDB
-- SGBD: PostgreSQL
--
-- Ordem de execucao: este e o PRIMEIRO script a ser rodado.
-- Cria todas as tabelas com PKs, FKs e constraints (CHECK / UNIQUE / NOT NULL).
-- Indices adicionais ficam no 03_indices.sql.
-- =====================================================================

-- Opcional: criar schema dedicado.
-- CREATE SCHEMA IF NOT EXISTS steamquest;
-- SET search_path TO steamquest, public;

-- Garante recriacao limpa em ambiente de desenvolvimento.
-- ATENCAO: nao rodar em producao - apaga dados.
DROP TABLE IF EXISTS auditoria_preco_jogo CASCADE;
DROP TABLE IF EXISTS avaliacao_jogo       CASCADE;
DROP TABLE IF EXISTS biblioteca_usuario   CASCADE;
DROP TABLE IF EXISTS pagamento            CASCADE;
DROP TABLE IF EXISTS item_pedido          CASCADE;
DROP TABLE IF EXISTS pedido               CASCADE;
DROP TABLE IF EXISTS key_jogo             CASCADE;
DROP TABLE IF EXISTS jogo_categoria       CASCADE;
DROP TABLE IF EXISTS categoria            CASCADE;
DROP TABLE IF EXISTS jogo                 CASCADE;
DROP TABLE IF EXISTS publicadora          CASCADE;
DROP TABLE IF EXISTS desenvolvedora       CASCADE;
DROP TABLE IF EXISTS usuario              CASCADE;


-- =====================================================================
-- USUARIO
-- =====================================================================
CREATE TABLE usuario (
    id              BIGSERIAL    PRIMARY KEY,
    nome            VARCHAR(120) NOT NULL,
    email           VARCHAR(150) NOT NULL,
    senha_hash      VARCHAR(255) NOT NULL,
    cpf             VARCHAR(14)  NOT NULL,
    data_nascimento DATE         NOT NULL,
    data_cadastro   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ativo           BOOLEAN      NOT NULL DEFAULT TRUE,

    CONSTRAINT uq_usuario_email CHECK (email LIKE '%_@_%._%'),
    CONSTRAINT uq_usuario_email_unico UNIQUE (email),
    CONSTRAINT uq_usuario_cpf_unico   UNIQUE (cpf),
    CONSTRAINT ck_usuario_nascimento  CHECK (data_nascimento <= CURRENT_DATE)
);


-- =====================================================================
-- DESENVOLVEDORA
-- =====================================================================
CREATE TABLE desenvolvedora (
    id           BIGSERIAL    PRIMARY KEY,
    nome         VARCHAR(120) NOT NULL,
    pais         VARCHAR(60),
    ano_fundacao INT,

    CONSTRAINT uq_desenvolvedora_nome  UNIQUE (nome),
    CONSTRAINT ck_desenvolvedora_ano   CHECK (ano_fundacao IS NULL OR ano_fundacao BETWEEN 1900 AND 2100)
);


-- =====================================================================
-- PUBLICADORA
-- =====================================================================
CREATE TABLE publicadora (
    id   BIGSERIAL    PRIMARY KEY,
    nome VARCHAR(120) NOT NULL,
    pais VARCHAR(60),

    CONSTRAINT uq_publicadora_nome UNIQUE (nome)
);


-- =====================================================================
-- JOGO
-- =====================================================================
CREATE TABLE jogo (
    id                BIGSERIAL     PRIMARY KEY,
    titulo            VARCHAR(150)  NOT NULL,
    descricao         TEXT,
    preco             NUMERIC(10,2) NOT NULL,
    data_lancamento   DATE,
    desenvolvedora_id BIGINT        NOT NULL,
    publicadora_id    BIGINT        NOT NULL,
    ativo             BOOLEAN       NOT NULL DEFAULT TRUE,

    CONSTRAINT ck_jogo_preco_positivo CHECK (preco >= 0),

    CONSTRAINT fk_jogo_desenvolvedora
        FOREIGN KEY (desenvolvedora_id) REFERENCES desenvolvedora(id)
        ON UPDATE CASCADE ON DELETE RESTRICT,

    CONSTRAINT fk_jogo_publicadora
        FOREIGN KEY (publicadora_id) REFERENCES publicadora(id)
        ON UPDATE CASCADE ON DELETE RESTRICT
);


-- =====================================================================
-- CATEGORIA
-- =====================================================================
CREATE TABLE categoria (
    id        BIGSERIAL    PRIMARY KEY,
    nome      VARCHAR(80)  NOT NULL,
    descricao VARCHAR(200),

    CONSTRAINT uq_categoria_nome UNIQUE (nome)
);


-- =====================================================================
-- JOGO_CATEGORIA  (associativa N:N)
-- =====================================================================
CREATE TABLE jogo_categoria (
    jogo_id      BIGINT NOT NULL,
    categoria_id BIGINT NOT NULL,

    CONSTRAINT pk_jogo_categoria PRIMARY KEY (jogo_id, categoria_id),

    CONSTRAINT fk_jc_jogo
        FOREIGN KEY (jogo_id) REFERENCES jogo(id)
        ON UPDATE CASCADE ON DELETE CASCADE,

    CONSTRAINT fk_jc_categoria
        FOREIGN KEY (categoria_id) REFERENCES categoria(id)
        ON UPDATE CASCADE ON DELETE CASCADE
);


-- =====================================================================
-- KEY_JOGO
-- =====================================================================
CREATE TABLE key_jogo (
    id           BIGSERIAL    PRIMARY KEY,
    jogo_id      BIGINT       NOT NULL,
    codigo_key   VARCHAR(64)  NOT NULL,
    status       VARCHAR(15)  NOT NULL DEFAULT 'disponivel',
    data_criacao TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    data_venda   TIMESTAMP,

    CONSTRAINT uq_key_codigo UNIQUE (codigo_key),

    CONSTRAINT ck_key_status CHECK (
        status IN ('disponivel','reservada','vendida','cancelada')
    ),

    CONSTRAINT ck_key_data_venda CHECK (
        (status = 'vendida' AND data_venda IS NOT NULL) OR
        (status <> 'vendida')
    ),

    CONSTRAINT fk_key_jogo
        FOREIGN KEY (jogo_id) REFERENCES jogo(id)
        ON UPDATE CASCADE ON DELETE RESTRICT
);


-- =====================================================================
-- PEDIDO
-- =====================================================================
CREATE TABLE pedido (
    id          BIGSERIAL     PRIMARY KEY,
    usuario_id  BIGINT        NOT NULL,
    data_pedido TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status      VARCHAR(15)   NOT NULL DEFAULT 'pendente',
    valor_total NUMERIC(10,2) NOT NULL DEFAULT 0,

    CONSTRAINT ck_pedido_status CHECK (
        status IN ('pendente','pago','finalizado','cancelado')
    ),

    CONSTRAINT ck_pedido_valor_total CHECK (valor_total >= 0),

    CONSTRAINT fk_pedido_usuario
        FOREIGN KEY (usuario_id) REFERENCES usuario(id)
        ON UPDATE CASCADE ON DELETE RESTRICT
);


-- =====================================================================
-- ITEM_PEDIDO
-- =====================================================================
CREATE TABLE item_pedido (
    id             BIGSERIAL     PRIMARY KEY,
    pedido_id      BIGINT        NOT NULL,
    jogo_id        BIGINT        NOT NULL,
    key_id         BIGINT,
    preco_unitario NUMERIC(10,2) NOT NULL,
    quantidade     INT           NOT NULL DEFAULT 1,

    CONSTRAINT ck_item_preco       CHECK (preco_unitario >= 0),
    CONSTRAINT ck_item_quantidade  CHECK (quantidade > 0),

    CONSTRAINT uq_item_pedido_jogo UNIQUE (pedido_id, jogo_id),
    CONSTRAINT uq_item_key         UNIQUE (key_id),

    CONSTRAINT fk_item_pedido
        FOREIGN KEY (pedido_id) REFERENCES pedido(id)
        ON UPDATE CASCADE ON DELETE CASCADE,

    CONSTRAINT fk_item_jogo
        FOREIGN KEY (jogo_id) REFERENCES jogo(id)
        ON UPDATE CASCADE ON DELETE RESTRICT,

    CONSTRAINT fk_item_key
        FOREIGN KEY (key_id) REFERENCES key_jogo(id)
        ON UPDATE CASCADE ON DELETE RESTRICT
);


-- =====================================================================
-- PAGAMENTO
-- =====================================================================
CREATE TABLE pagamento (
    id             BIGSERIAL     PRIMARY KEY,
    pedido_id      BIGINT        NOT NULL,
    metodo         VARCHAR(20)   NOT NULL,
    status         VARCHAR(15)   NOT NULL DEFAULT 'pendente',
    valor_pago     NUMERIC(10,2) NOT NULL,
    data_pagamento TIMESTAMP,

    CONSTRAINT ck_pagamento_metodo CHECK (
        metodo IN ('cartao','pix','boleto')
    ),

    CONSTRAINT ck_pagamento_status CHECK (
        status IN ('pendente','aprovado','recusado','estornado')
    ),

    CONSTRAINT ck_pagamento_valor CHECK (valor_pago >= 0),

    CONSTRAINT fk_pagamento_pedido
        FOREIGN KEY (pedido_id) REFERENCES pedido(id)
        ON UPDATE CASCADE ON DELETE CASCADE
);


-- =====================================================================
-- BIBLIOTECA_USUARIO
-- =====================================================================
CREATE TABLE biblioteca_usuario (
    id             BIGSERIAL  PRIMARY KEY,
    usuario_id     BIGINT     NOT NULL,
    jogo_id        BIGINT     NOT NULL,
    key_id         BIGINT     NOT NULL,
    data_aquisicao TIMESTAMP  NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_biblioteca_key            UNIQUE (key_id),
    CONSTRAINT uq_biblioteca_usuario_key    UNIQUE (usuario_id, key_id),

    CONSTRAINT fk_bib_usuario
        FOREIGN KEY (usuario_id) REFERENCES usuario(id)
        ON UPDATE CASCADE ON DELETE RESTRICT,

    CONSTRAINT fk_bib_jogo
        FOREIGN KEY (jogo_id) REFERENCES jogo(id)
        ON UPDATE CASCADE ON DELETE RESTRICT,

    CONSTRAINT fk_bib_key
        FOREIGN KEY (key_id) REFERENCES key_jogo(id)
        ON UPDATE CASCADE ON DELETE RESTRICT
);


-- =====================================================================
-- AVALIACAO_JOGO
-- =====================================================================
CREATE TABLE avaliacao_jogo (
    id         BIGSERIAL PRIMARY KEY,
    usuario_id BIGINT    NOT NULL,
    jogo_id    BIGINT    NOT NULL,
    nota       INT       NOT NULL,
    comentario TEXT,
    data       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT ck_avaliacao_nota CHECK (nota BETWEEN 1 AND 5),

    CONSTRAINT uq_avaliacao_usuario_jogo UNIQUE (usuario_id, jogo_id),

    CONSTRAINT fk_aval_usuario
        FOREIGN KEY (usuario_id) REFERENCES usuario(id)
        ON UPDATE CASCADE ON DELETE CASCADE,

    CONSTRAINT fk_aval_jogo
        FOREIGN KEY (jogo_id) REFERENCES jogo(id)
        ON UPDATE CASCADE ON DELETE CASCADE
);


-- =====================================================================
-- AUDITORIA_PRECO_JOGO
-- Populada pelo trigger AFTER UPDATE em jogo.preco (script 05).
-- =====================================================================
CREATE TABLE auditoria_preco_jogo (
    id             BIGSERIAL     PRIMARY KEY,
    jogo_id        BIGINT        NOT NULL,
    preco_antigo   NUMERIC(10,2) NOT NULL,
    preco_novo     NUMERIC(10,2) NOT NULL,
    usuario_db     VARCHAR(80)   NOT NULL,
    data_alteracao TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_audit_jogo
        FOREIGN KEY (jogo_id) REFERENCES jogo(id)
        ON UPDATE CASCADE ON DELETE CASCADE
);


-- =====================================================================
-- FIM DO SCRIPT 01
-- Proximo: 03_indices.sql  (02 e usado caso constraints sejam separadas)
-- =====================================================================
