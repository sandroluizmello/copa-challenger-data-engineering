{{ config(
    materialized='view',
    schema='marts'
) }}

-- ============================================================
-- View: analytics_team_evolution_over_time
-- Objetivo: Comparar a performance de cada time entre a copa
-- atual e a copa ANTERIOR EM QUE ELE PARTICIPOU (não
-- necessariamente a edição cronologicamente anterior — se o
-- time não se classificou para uma edição, ela é pulada na
-- comparação).
--
-- Observações de design:
--   - Constrói em cima de analytics_team_by_world_cup (reuso em
--     vez de recalcular vitórias/gols do zero).
--   - performance_rank_in_career: rankeia todas as participações
--     do time da melhor pra pior (1 = melhor campanha da
--     história do time).
-- ============================================================

with team_cups as (

    select * from {{ ref('analytics_team_by_world_cup') }}

),

with_lag as (

    select
        *,
        lag(wins) over (partition by team_id order by world_cup_id asc) as previous_wins,
        lag(goal_difference) over (partition by team_id order by world_cup_id asc) as previous_goal_difference,
        lag(win_rate_pct) over (partition by team_id order by world_cup_id asc) as previous_win_rate_pct,
        lag(world_cup_id) over (partition by team_id order by world_cup_id asc) as previous_world_cup_id
    from team_cups

),

with_rank as (

    select
        *,
        row_number() over (
            partition by team_id
            order by wins desc, goal_difference desc
        ) as performance_rank_in_career
    from with_lag

),

final as (

    select
        team_id,
        team_name,
        world_cup_id,
        previous_world_cup_id,

        wins,
        previous_wins,
        (wins - previous_wins) as wins_delta,

        goal_difference,
        previous_goal_difference,
        (goal_difference - previous_goal_difference) as goal_difference_delta,

        win_rate_pct,
        previous_win_rate_pct,
        round(win_rate_pct - previous_win_rate_pct, 2) as win_rate_pct_delta,

        last_round_reached,
        performance_rank_in_career,

        case
            when previous_wins is null then 'PRIMEIRA_PARTICIPACAO'
            when wins > previous_wins then 'MELHOROU'
            when wins < previous_wins then 'PIOROU'
            else 'ESTAVEL'
        end as trend_label

    from with_rank

)

select * from final
order by team_id, world_cup_id