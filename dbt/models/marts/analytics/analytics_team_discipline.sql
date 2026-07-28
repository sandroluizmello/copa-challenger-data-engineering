{{ config(
    materialized='view',
    schema='marts'
) }}

-- ============================================================
-- View: analytics_team_discipline
-- Objetivo: Estatísticas de disciplina de cada seleção (cartões
-- amarelos, vermelhos diretos e segundo amarelo) considerando
-- todas as Copas do Mundo disputadas.
--
-- Observações de design:
--   - "Expulsões" = vermelho direto + segundo amarelo, já que
--     ambos resultam em expulsão de campo.
--   - total_matches_played é recalculado somando aparições como
--     mandante e visitante em fct_matches, para servir de base
--     das médias por partida.
-- ============================================================

with cards as (

    select * from {{ ref('fct_match_cards') }}

),

team_matches_count as (

    select
        team_id,
        team_name,
        count(distinct match_id) as total_matches_played
    from (
        select home_team_id as team_id, home_team_name as team_name, match_id
        from {{ ref('fct_matches') }}

        union all

        select away_team_id as team_id, away_team_name as team_name, match_id
        from {{ ref('fct_matches') }}
    ) t
    group by team_id, team_name

),

cards_agg as (

    select
        team_id,
        team_name,

        sum(case when card_type = 'AMARELO' then 1 else 0 end) as yellow_cards,
        sum(case when card_type = 'VERMELHO' then 1 else 0 end) as red_cards_direct,
        sum(case when card_type = 'SEGUNDO_AMARELO' then 1 else 0 end) as second_yellow_cards,
        count(*) as total_cards

    from cards
    group by team_id, team_name

),

final as (

    select
        c.team_id,
        c.team_name,
        m.total_matches_played,

        c.yellow_cards,
        c.red_cards_direct,
        c.second_yellow_cards,
        (c.red_cards_direct + c.second_yellow_cards) as total_expulsions,
        c.total_cards,

        round(c.total_cards / nullif(m.total_matches_played, 0), 2) as avg_cards_per_match,
        round(
            (c.red_cards_direct + c.second_yellow_cards) / nullif(m.total_matches_played, 0),
        3) as avg_expulsions_per_match

    from cards_agg c
    left join team_matches_count m on c.team_id = m.team_id

)

select * from final
order by total_cards desc