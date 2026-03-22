use flowdata_streaming;

-- inserindo dados base
insert into perfis (nome_perfil, idade, tipo_perfil) values ('felipe admin', 25, 'adulto');
insert into categorias (nome_categoria) values ('sci-fi'), ('drama'), ('ação');

-- inserindo faixas etarias (modelo brasileiro)
insert ignore into faixas_etarias(sigla, idade_minima) 
values ('l', 0), ('10', 10), ('12', 12), ('14', 14), ('16', 16), ('18', 18);

-- simulação de catálogo (filmes e séries)
-- a trigger trg_separacao_tempo vai classificar como 'longa-metragem'
insert into titulos (nome, duracao_minutos, ano_lancamento, sigla_classificacao, tipo) 
values ('interestelar', 169, 2014, '10', 'filme');

-- inserindo uma série
insert into titulos (nome, duracao_minutos, ano_lancamento, sigla_classificacao, tipo) 
values ('the last of us', 50, 2023, '16', 'série');

-- inserindo episódios (a trigger trg_classificar_episodio atua aqui)
insert into episodios (id_titulo, temporada, numero_episodio, nome_episodio, duracao_minutos) 
values 
(2, 1, 1, 'quando estiver perdido', 81), 
(2, 1, 2, 'teaser da temporada', 5);    

-- teste de lógica de progresso (procedure)
-- felipe assistiu 1h20m de interestelar (filme - id_episodio é null)
call sp_registrar_progresso(1, 1, null, '01:20:00', 169);

-- felipe assistiu 30 min do ep 1 de tlou (série - id_episodio é 1)
call sp_registrar_progresso(1, 2, 1, '00:30:00', 81);

-- felipe finalizou o ep 2 (98% concluído - deve marcar concluido = true)
call sp_registrar_progresso(1, 2, 2, '00:51:00', 52);

-- teste de auditoria (trigger de log)
-- alterando a classificação de tlou para disparar o log
update titulos set sigla_classificacao = '18' where id_titulo = 2;

-- verificação dos resultados (views)
select * from vw_continuar_serie;
select nome_episodio, tipo_automatic_ep from episodios;
select * from log_alteracoes_titulos;
