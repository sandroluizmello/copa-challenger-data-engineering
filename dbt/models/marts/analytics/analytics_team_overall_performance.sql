{{ config(
    materialized='view',
    schema='marts'
) }}

-- ============================================================
-- View: analytics_team_overall_performance
-- Objetivo: Estatísticas agregadas de cada seleção considerando
-- TODAS as Copas do Mundo disputadas (partidas como mandante e
-- como visitante): vitórias, empates, derrotas, gols e saldo.
--
-- Observações de design:
--   - Quando o placar normal termina empatado e há disputa de
--     pênaltis registrada, o resultado é classificado como
--     WIN_PENALTIES / LOSS_PENALTIES (e contabilizado dentro de
--     total_wins / total_losses, mas exposto separadamente para
--     quem quiser analisar sem considerar pênaltis).
--   - Sem dados de shootout, o empate permanece como DRAW.
-- ============================================================

with home_perspective as (

    select
        match_id,
        world_cup_id,
        home_team_id as team_id,
        home_team_name as team_name,
        home_team_score as goals_for,
        away_team_score as goals_against,
        home_team_penalty_shootout_score as penalty_score_for,
        away_team_penalty_shootout_score as penalty_score_against
    from {{ ref('fct_matches') }}

),

away_perspective as (

    select
        match_id,
        world_cup_id,
        away_team_id as team_id,
        away_team_name as team_name,
        away_team_score as goals_for,
        home_team_score as goals_against,
        away_team_penalty_shootout_score as penalty_score_for,
        home_team_penalty_shootout_score as penalty_score_against
    from {{ ref('fct_matches') }}

),

team_matches as (

    select * from home_perspective
    union all
    select * from away_perspective

),

match_results as (

    select
        *,
        case
            when goals_for > goals_against then 'WIN'
            when goals_for < goals_against then 'LOSS'
            when goals_for = goals_against
                 and penalty_score_for > penalty_score_against then 'WIN_PENALTIES'
            when goals_for = goals_against
                 and penalty_score_for < penalty_score_against then 'LOSS_PENALTIES'
            else 'DRAW'
        end as match_result

    from team_matches

),

aggregated as (

    select
        team_id,
        team_name,

        count(distinct match_id) as total_matches,
        count(distinct world_cup_id) as total_world_cups_played,

        sum(case when match_result = 'WIN' then 1 else 0 end) as wins_regular,
        sum(case when match_result = 'WIN_PENALTIES' then 1 else 0 end) as wins_penalties,
        sum(case when match_result = 'LOSS' then 1 else 0 end) as losses_regular,
        sum(case when match_result = 'LOSS_PENALTIES' then 1 else 0 end) as losses_penalties,
        sum(case when match_result = 'DRAW' then 1 else 0 end) as draws,

        sum(goals_for) as total_goals_for,
        sum(goals_against) as total_goals_against

    from match_results
    group by team_id, team_name

),

final as (

    select
        team_id,
        team_name,
        total_world_cups_played,
        total_matches,

        (wins_regular + wins_penalties) as total_wins,
        draws as total_draws,
        (losses_regular + losses_penalties) as total_losses,

        wins_penalties as wins_by_penalties,
        losses_penalties as losses_by_penalties,

        total_goals_for,
        total_goals_against,
        (total_goals_for - total_goals_against) as goal_difference,

        round(total_goals_for / nullif(total_matches, 0), 2) as avg_goals_for_per_match,
        round(total_goals_against / nullif(total_matches, 0), 2) as avg_goals_against_per_match,

        round(
            100.0 * (wins_regular + wins_penalties) / nullif(total_matches, 0),
        2) as win_rate_pct

    from aggregated

)

select * from final
order by total_wins desc, goal_difference desc