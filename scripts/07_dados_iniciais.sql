-- ==============================================================================
-- Script 07: Dados Iniciais
-- Descrição: Carga de dados fictícios para testes das views, transações e triggers.
-- ==============================================================================

-- 1. Inserir Usuários (Senhas fictícias / CPF único)
INSERT INTO usuario (nome, email, senha_hash, cpf, data_nascimento, ativo) VALUES
('Gabriel Ferreira', 'gabriel@email.com', 'hash_senha_1', '11122233344', '1995-04-12', true),
('Rata Atômica', 'rata.atomica@email.com', 'hash_senha_2', '22233344455', '2001-08-25', true),
('Doidinha Gamer', 'doidinha@email.com', 'hash_senha_3', '33344455566', '1999-11-03', true);

-- 2. Inserir Desenvolvedoras
INSERT INTO desenvolvedora (nome, pais, ano_fundacao) VALUES
('Square Enix', 'Japão', 1975),
('NetEase Games', 'China', 1997),
('MAIET Entertainment', 'Coreia do Sul', 1998);

-- 3. Inserir Publicadoras
INSERT INTO publicadora (nome, pais) VALUES
('Square Enix', 'Japão'),
('NetEase Games', 'China'),
('Masangsoft', 'Coreia do Sul');

-- 4. Inserir Categorias
INSERT INTO categoria (nome, descricao) VALUES
('JRPG', 'Jogos de RPG japoneses clássicos com forte foco narrativo'),
('Hero Shooter', 'Jogos de tiro competitivos baseados em heróis com habilidades únicas'),
('Ação TPS', 'Jogos de tiro em terceira pessoa focados em movimentação rápida');

-- 5. Inserir Jogos
INSERT INTO jogo (titulo, descricao, preco, data_lancamento, desenvolvedora_id, publicadora_id, ativo) VALUES
('Dragon Quest XI: Echoes of an Elusive Age', 'Um épico conto sobre o Luminary em um mundo repleto de charme.', 199.90, '2017-07-29', 1, 1, true),
('Dragon Quest VIII: Journey of the Cursed King', 'Acompanhe Eight na jornada do rei amaldiçoado.', 89.90, '2004-11-27', 1, 1, true),
('Marvel Rivals', 'Monte sua equipe de super-heróis e batalhe em cenários destrutíveis.', 0.00, '2024-12-06', 2, 2, true),
('GunZ: The Duel', 'Ação frenética focada em mecânicas avançadas de movimentação (K-Style).', 15.50, '2003-01-01', 3, 3, true);

-- 6. Inserir Associação Jogo <-> Categoria
INSERT INTO jogo_categoria (jogo_id, categoria_id) VALUES
(1, 1), (2, 1), (3, 2), (4, 3);

-- 7. Inserir Keys de Jogos
-- Algumas chaves estão disponíveis para as transações de teste futuras e outras vendidas para o histórico.
INSERT INTO key_jogo (jogo_id, codigo_key, status) VALUES
(1, 'DQ11-AAAA-BBBB-CCCC', 'vendida'),
(1, 'DQ11-XXXX-YYYY-ZZZZ', 'disponivel'),
(2, 'DQ08-1111-2222-3333', 'disponivel'),
(3, 'MRVL-HERO-5555-6666', 'disponivel'),
(4, 'GUNZ-KSTL-7777-8888', 'vendida'),
(4, 'GUNZ-KSTL-9999-0000', 'disponivel');

-- 8. Inserir Pedidos Históricos
-- Simulando compras já concluídas no passado para alimentar os relatórios.
INSERT INTO pedido (usuario_id, data_pedido, status, valor_total) VALUES
(1, CURRENT_TIMESTAMP - INTERVAL '5 days', 'finalizado', 199.90),
(2, CURRENT_TIMESTAMP - INTERVAL '2 days', 'finalizado', 15.50);

-- 9. Inserir Itens do Pedido
INSERT INTO item_pedido (pedido_id, jogo_id, key_id, preco_unitario, quantidade) VALUES
(1, 1, 1, 199.90, 1),
(2, 4, 5, 15.50, 1);

-- 10. Inserir Pagamentos
INSERT INTO pagamento (pedido_id, metodo, status, valor_pago, data_pagamento) VALUES
(1, 'pix', 'aprovado', 199.90, CURRENT_TIMESTAMP - INTERVAL '5 days'),
(2, 'cartao', 'aprovado', 15.50, CURRENT_TIMESTAMP - INTERVAL '2 days');

-- 11. Inserir Biblioteca do Usuário
-- (Na prática isso deve ser populado pela sua Trigger trg_biblioteca_pos_pedido, 
-- mas estamos inserindo o histórico passado diretamente).
INSERT INTO biblioteca_usuario (usuario_id, jogo_id, key_id, data_aquisicao) VALUES
(1, 1, 1, CURRENT_TIMESTAMP - INTERVAL '5 days'),
(2, 4, 5, CURRENT_TIMESTAMP - INTERVAL '2 days');

-- 12. Inserir Avaliações
INSERT INTO avaliacao_jogo (usuario_id, jogo_id, nota, comentario) VALUES
(1, 1, 5, 'Atmosfera acolhedora e narrativa extremamente sincera. O elenco de personagens é incrível!'),
(2, 4, 4, 'Ótimo para treinar mecânicas de movimento e tracking para aplicar em outros shooters. A comunidade ainda joga.');