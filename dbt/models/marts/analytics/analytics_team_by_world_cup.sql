{{ config(
    materialized='view',
    schema='marts'
) }}

-- ============================================================
-- View: analytics_team_by_world_cup
-- Objetivo: Performance de cada seleção em CADA edição da Copa
-- do Mundo (quebra temporal), diferente de
-- analytics_team_overall_performance que soma tudo.
--
-- Observações de design:
--   - Mesma lógica de resultado (WIN/DRAW/LOSS incluindo
--     pênaltis) usada em analytics_team_overall_performance.
--     Se o projeto crescer, vale extrair essa lógica para um
--     modelo intermediário (staging/intermediate) e reutilizar
--     nas duas views em vez de duplicar o CASE WHEN.
--   - last_round_reached é um proxy: pega o match_round da
--     última partida do time naquela edição (por data), já que
--     não existe uma coluna explícita de "fase final atingida".
--     Funciona bem para mata-mata (time eliminado para de jogar),
--     mas pode não refletir perfeitamente formatos antigos com
--     regras diferentes de desempate.
-- ============================================================

with home_perspective as (

    select
        match_id, world_cup_id, match_date, match_round,
        home_team_id as team_id, home_team_name as team_name,
        home_team_score as goals_for, away_team_score as goals_against,
        home_team_penalty_shootout_score as penalty_score_for,
        away_team_penalty_shootout_score as penalty_score_against
    from {{ ref('fct_matches') }}

),

away_perspective as (

    select
        match_id, world_cup_id, match_date, match_round,
        away_team_id as team_id, away_team_name as team_name,
        away_team_score as goals_for, home_team_score as goals_against,
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

-- Última partida disputada pelo time naquela copa (proxy para fase mais profunda alcançada)
last_match_per_team_cup as (

    select
        team_id,
        world_cup_id,
        match_round,
        row_number() over (
            partition by team_id, world_cup_id
            order by match_date desc
        ) as rn
    from team_matches

),

aggregated as (

    select
        team_id,
        team_name,
        world_cup_id,

        count(distinct match_id) as total_matches,
        sum(case when match_result in ('WIN', 'WIN_PENALTIES') then 1 else 0 end) as wins,
        sum(case when match_result = 'DRAW' then 1 else 0 end) as draws,
        sum(case when match_result in ('LOSS', 'LOSS_PENALTIES') then 1 else 0 end) as losses,

        sum(goals_for) as goals_for,
        sum(goals_against) as goals_against

    from match_results
    group by team_id, team_name, world_cup_id

),

final as (

    select
        a.team_id,
        a.team_name,
        a.world_cup_id,

        a.total_matches,
        a.wins,
        a.draws,
        a.losses,

        a.goals_for,
        a.goals_against,
        (a.goals_for - a.goals_against) as goal_difference,

        round(100.0 * a.wins / nullif(a.total_matches, 0), 2) as win_rate_pct,

        lm.match_round as last_round_reached

    from aggregated a
    left join last_match_per_team_cup lm
        on a.team_id = lm.team_id
       and a.world_cup_id = lm.world_cup_id
       and lm.rn = 1

)

select * from final
order by world_cup_id desc, wins desc