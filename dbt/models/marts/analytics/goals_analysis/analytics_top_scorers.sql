{{ config(
    materialized='view',
    schema='marts'
) }}

-- ============================================================
-- View: analytics_top_scorers
-- Objetivo: Ranking histórico de artilheiros das Copas do Mundo.
--
-- Observações de design:
--   - Gols contra (GOL_CONTRA) são excluídos, pois não devem
--     contar a favor do jogador que marcou.
--   - Agrupamento por (scorer_name, team_name) em vez de só
--     scorer_name, para não misturar jogadores homônimos de
--     seleções diferentes.
--   - scorer_name vem de parsing de texto (fct_match_goals) —
--     grafias diferentes do mesmo jogador (acentos, abreviações)
--     podem aparecer como linhas separadas. Recomenda-se uma
--     normalização de nomes numa iteração futura caso o ranking
--     apresente duplicidades.
-- ============================================================

with goals_only as (

    select *
    from {{ ref('fct_match_goals') }}
    where goal_type != 'GOL_CONTRA'
      and scorer_name is not null
      and trim(scorer_name) != ''

),

aggregated as (

    select
        scorer_name,
        team_id,
        team_name,

        count(*) as total_goals,
        sum(case when goal_type = 'PENALTI' then 1 else 0 end) as penalty_goals,
        count(distinct match_id) as matches_scored_in,
        count(distinct world_cup_id) as world_cups_scored_in,
        min(world_cup_id) as first_world_cup_scored,
        max(world_cup_id) as last_world_cup_scored

    from goals_only
    group by scorer_name, team_id, team_name

),

final as (

    select
        scorer_name,
        team_name,

        total_goals,
        penalty_goals,
        (total_goals - penalty_goals) as open_play_goals,

        matches_scored_in,
        round(total_goals / nullif(matches_scored_in, 0), 2) as avg_goals_per_match,

        world_cups_scored_in,
        first_world_cup_scored,
        last_world_cup_scored

    from aggregated

)

select * from final
order by total_goals desc