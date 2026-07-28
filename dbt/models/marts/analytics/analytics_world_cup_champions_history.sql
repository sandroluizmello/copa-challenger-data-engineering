{{ config(
    materialized='view',
    schema='marts'
) }}

-- ============================================================
-- View: analytics_world_cup_champions_history
-- Objetivo: Histórico de campeões/vices de cada edição, com
-- indicadores extras: time mais indisciplinado e time com mais
-- pênaltis convertidos em disputas por pênaltis.
--
-- Observações de design:
--   - Constrói em cima de analytics_world_cup_summary (reuso
--     em vez de recalcular campeão/vice/artilheiro do zero).
--   - "most_penalties_converted_team" considera apenas pênaltis
--     convertidos EM DISPUTAS (fct_match_penalty_shootouts),
--     não pênaltis marcados durante o jogo normal.
-- ============================================================

with base_summary as (

    select
        world_cup_id,
        host_country,
        champion_country,
        runner_up_country,
        top_scorer_name,
        top_scorer_goals
    from {{ ref('analytics_world_cup_summary') }}

),

cards_per_cup as (

    select
        world_cup_id,
        team_name,
        count(*) as total_cards,
        row_number() over (partition by world_cup_id order by count(*) desc) as rn
    from {{ ref('fct_match_cards') }}
    group by world_cup_id, team_name

),

most_carded_team as (

    select
        world_cup_id,
        team_name as most_carded_team,
        total_cards as most_carded_team_cards
    from cards_per_cup
    where rn = 1

),

penalties_converted_per_cup as (

    select
        world_cup_id,
        team_name,
        count(*) as penalties_converted,
        row_number() over (partition by world_cup_id order by count(*) desc) as rn
    from {{ ref('fct_match_penalty_shootouts') }}
    where is_goal = true
    group by world_cup_id, team_name

),

most_penalties_team as (

    select
        world_cup_id,
        team_name as most_penalties_converted_team,
        penalties_converted as most_penalties_converted_count
    from penalties_converted_per_cup
    where rn = 1

),

final as (

    select
        b.world_cup_id,
        b.host_country,
        b.champion_country,
        b.runner_up_country,
        b.top_scorer_name,
        b.top_scorer_goals,

        mc.most_carded_team,
        mc.most_carded_team_cards,

        mp.most_penalties_converted_team,
        mp.most_penalties_converted_count

    from base_summary b
    left join most_carded_team mc on b.world_cup_id = mc.world_cup_id
    left join most_penalties_team mp on b.world_cup_id = mp.world_cup_id

)

select * from final
order by world_cup_id desc