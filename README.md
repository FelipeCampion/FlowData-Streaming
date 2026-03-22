# FlowData-Streaming 🎬📺⚙️

![MySQL](https://img.shields.io/badge/mysql-%2300f.svg?style=for-the-badge&logo=mysql&logoColor=white)
![Status](https://img.shields.io/badge/Status-Concluído-brightgreen?style=for-the-badge)

**Arquitetura de banco de dados para streaming com hierarquia de episódios e automação de progresso.**

Este repositório contém a arquitetura de um banco de dados relacional para plataformas de vídeo on-demand (VOD). O projeto foca no gerenciamento híbrido de **filmes e séries**, utilizando gatilhos inteligentes para classificação de conteúdo e procedimentos armazenados para controle rigoroso de visualização e continuidade.

## Especificações Técnicas
* **Engine:** MySQL 8.0+
* **Modelagem:** Estrutura normalizada (3NF) com suporte a múltiplas temporadas e rastreabilidade de progresso por perfil.
* **Objetos:** Tabelas, Constraints (FKs com Delete Cascade), Triggers de automação e Stored Procedures.

## Funcionalidades Implementadas

### Classificação Automática de Catálogo (Triggers)
* **Inteligência de Tempo:** O sistema classifica automaticamente se um título é um "longa-metragem", "curta-metragem" ou "podcast/extra" com base na duração em minutos no momento do `insert`.
* **Gestão de Episódios:** Gatilhos específicos identificam automaticamente "extras/previews" em séries, garantindo a organização visual do conteúdo para o usuário final.

### Controle de Progresso e "Continuar Assistindo"
* **Upsert de Visualização:** Através da procedure `sp_registrar_progresso`, o sistema gerencia se deve criar um novo registro ou atualizar o tempo de parada do usuário, calculando o percentual concluído em tempo real.
* **Regra de Conclusão:** Vídeos com mais de 95% de visualização são marcados automaticamente como `concluido`, limpando a lista de "pendentes" do perfil de forma inteligente.

### Segurança e Auditoria (BI & Segurança)
* **Filtro de Recomendação Segura:** Uma view inteligente cruza a idade do perfil com a tabela de `faixas_etarias`, impedindo que perfis infantis visualizem títulos acima de sua classificação permitida.
* **Log de Governança:** Qualquer alteração em classificações etárias gera um rastro de auditoria na tabela `log_alteracoes_titulos`, registrando o valor antigo, o novo e a data da mudança para controle administrativo.

## 📖 Instruções de Uso

1.  **Definição (DDL):** Execute o script de estrutura para criar o schema, tabelas e as relações de integridade (FKs).
2.  **Manipulação (DML):** O script inclui uma massa de dados de teste para validar o funcionamento das triggers de classificação e as chaves estrangeiras.
3.  **Registrar Progresso:** Para simular um usuário assistindo a um conteúdo, utilize o comando:
    ```sql
    -- exemplo para filme (id_episodio como null)
    call sp_registrar_progresso(1, 1, null, '00:45:00', 120);

    -- exemplo para série (informando o id_episodio)
    call sp_registrar_progresso(1, 2, 5, '00:20:00', 50);
    ```

## 📊 Consultas de Validação
Para visualizar a inteligência do sistema em ação, utilize as views integradas:
```sql
select * from vw_continuar_serie;        -- lista de pendentes personalizada
select * from vw_resumo_catalogo;       -- métricas de duração por categoria
select * from vw_recomendacoes_seguras; -- controle parental ativo
