create database FlowData_Streaming
character set utf8mb4
collate utf8mb4_0900_ai_ci;

use FlowData_Streaming;

-- Criação da tabela de perfis
create table perfis(
id_perfil int auto_increment primary key,
nome_perfil varchar(30) not null,
idade int not null,
tipo_perfil enum('Adulto', 'Kids', 'Restrito') default 'Adulto'
);

-- Criação da tabela de titulos
create table titulos(
id_titulo int auto_increment primary key,
nome varchar(50) not null,
duracao_minutos int not null,
tipo_automatico enum('Curta-metragem', 'Longa-metragem', 'Podcast/Extra') default 'Longa-metragem',
ano_lancamento int not null,
sigla_classificacao varchar(5),
tipo varchar(50)
);

-- Criação da tabela de episódios para as séries
create table episodios(
id_episodio int auto_increment primary key,
id_titulo int not null,
tipo_automatic_ep enum('Extra/Preview', 'Episódio Padrão') default 'Episódio Padrão',
temporada int not null,
numero_episodio int not null,
nome_episodio varchar(100),
duracao_minutos int not null
);

-- Criação da tabela de faixas etarias
create table faixas_etarias(
sigla varchar(5) primary key,
idade_minima int not null
);

-- Inserção de faixas etarias no modelo Brasileiro
insert into faixas_etarias(sigla, idade_minima) 
values ('L', 0),
('10', 10),
('12', 12),
('14', 14),
('16', 16),
('18', 18);

-- Criação da tabela de separação das categorias
create table categorias(
id_categoria int auto_increment primary key,
nome_categoria varchar(50) not null unique
);

-- Criação da tabela relacional dos titulos e suas categorias
create table titulo_categorias(
id_titulo int,
id_categoria int,
primary key (id_titulo, id_categoria)
);

-- Criação da tabela de registo do historico de progresso de cada usuario para aquele titulo
create table historico_progresso(
id_progresso int auto_increment primary key,
id_perfil int,
id_titulo int,
id_episodio int,
unique key uq_perfil_titulo (id_perfil, id_titulo, id_episodio),
ultimo_timestamp time not null,
percentual_concluido decimal(5,2),
data_visualizacao timestamp default current_timestamp on update current_timestamp,
concluido boolean default false
);

-- Criação da tabela de historico de alteração das especificações dos titulos
create table log_alteracoes_titulos(
id_log int auto_increment primary key,
id_titulo int,
data_alteracao timestamp default current_timestamp,
campo_alterado varchar(50),
valor_antigo varchar(255),
valor_novo varchar(255)
);

-- Criação das pontes entre tabelas

alter table titulos
add constraint fk_ti_sigla foreign key (sigla_classificacao) references faixas_etarias (sigla);

alter table episodios
add constraint fk_ep_titulo foreign key (id_titulo) references titulos (id_titulo) on delete cascade;

alter table titulo_categorias
add constraint fk_tica_ti foreign key (id_titulo) references titulos (id_titulo) on delete cascade,
add constraint fk_tica_cat foreign key (id_categoria) references categorias (id_categoria) on delete cascade;

alter table historico_progresso
add constraint fk_his_per foreign key (id_perfil) references perfis (id_perfil) on delete cascade,
add constraint fk_his_ti foreign key (id_titulo) references titulos (id_titulo) on delete cascade,
add constraint fk_his_ep foreign key (id_episodio) references episodios (id_episodio) on delete cascade;

-- Criação das triggers

-- Trigger para separação de tipos entre os titulos
delimiter //

create trigger trg_separacao_tempo
before insert on titulos
for each row
begin
    if new.duracao_minutos < 15 then
        set new.tipo_automatico ='Podcast/Extra';
    elseif new.duracao_minutos <= 70 then
        set new.tipo_automatico ='Curta-metragem';
    else
        set new.tipo_automatico ='Longa-metragem';
    end if;
end//
delimiter ;

-- Trigger para registro de atualização entre os titulos
delimiter //

create trigger trg_log_titulos
after update on titulos
for each row
begin
    if old.sigla_classificacao <> new.sigla_classificacao then
        insert into log_alteracoes_titulos (id_titulo, campo_alterado, valor_antigo, valor_novo)
        values (old.id_titulo, 'classificacao', old.sigla_classificacao, new.sigla_classificacao);
    end if;
end //

delimiter ;

delimiter //

-- Trigger para separação de tipos entre os epsódios
create trigger trg_classificar_episodio
before insert on episodios
for each row

begin
    if new.duracao_minutos < 15 then
    set new.tipo_automatic_ep = 'Extra/Preview';
    else
    set new.tipo_automatic_ep = 'Episódio Padrão';
    end if;
end//
delimiter ;

-- Criação de procedures

-- Procedure para registro de progresso do titulo e epsódios
delimiter //

create procedure sp_registrar_progresso(
    in p_id_perfil int, 
    in p_id_titulo int, 
    in p_id_episodio int,
    in p_tempo time, 
    in p_total_minutos int
)
begin
    declare v_percentual decimal(5,2);
    set v_percentual = (time_to_sec(p_tempo) / (p_total_minutos * 60)) * 100;

    insert into historico_progresso (id_perfil, id_titulo, id_episodio, ultimo_timestamp, percentual_concluido, concluido)
    values (p_id_perfil, p_id_titulo, p_id_episodio, p_tempo, v_percentual, if(v_percentual > 95, 1, 0))
    on duplicate key update 
        ultimo_timestamp = p_tempo,
        percentual_concluido = v_percentual,
        concluido = if(v_percentual > 95, 1, 0);
end //

delimiter ;

-- Criação das views

create view vw_resumo_catalogo as
select 
    tipo_automatico as Categoria,
    count(*) as Total_Titulos,
    avg(duracao_minutos) as Media_Duracao
from titulos
group by tipo_automatico;

create view vw_recomendacoes_seguras as
select 
    p.nome_perfil,
    t.nome as titulo,
    t.tipo_automatico,
    t.sigla_classificacao
from perfis p
cross join titulos t
join faixas_etarias f on t.sigla_classificacao = f.sigla
where p.idade >= f.idade_minima;

create view vw_continuar_serie as
select 
    p.nome_perfil,
    t.nome as serie,
    e.temporada,
    e.numero_episodio,
    h.ultimo_timestamp
from historico_progresso h
join perfis p on h.id_perfil = p.id_perfil
join titulos t on h.id_titulo = t.id_titulo
left join episodios e on h.id_episodio = e.id_episodio
where h.concluido = false;
