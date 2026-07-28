{{ config(
    materialized='view',
    schema='marts'
) }}

-- ============================================================
-- View: analytics_world_cup_summary
-- Objetivo: Resumo de cada edição da Copa do Mundo — campeão,
-- vice, público, gols, melhor ataque/defesa e artilheiro da
-- edição.
--
-- Observações de design:
--   - total_matches/total_goals/total_attendance são recalculados
--     a partir de fct_matches (granular) e usados com prioridade;
--     caem para os campos originais de dim_world_cups (metadata
--     da fonte) apenas se o cálculo vier nulo.
--   - "Melhor ataque/defesa" considera gols pró/contra do time
--     somando partidas como mandante e visitante na mesma edição.
-- ============================================================

with world_cups as (

    select * from {{ ref('dim_world_cups') }}

),

matches_stats as (

    select
        world_cup_id,
        count(distinct match_id) as total_matches_calculated,
        sum(home_team_score + away_team_score) as total_goals,
        sum(match_attendance) as total_attendance_calculated
    from {{ ref('fct_matches') }}
    group by world_cup_id

),

team_goals_per_cup as (

    select
        world_cup_id,
        team_id,
        team_name,
        sum(goals_for) as goals_for,
        sum(goals_against) as goals_against
    from (
        select world_cup_id, home_team_id as team_id, home_team_name as team_name,
               home_team_score as goals_for, away_team_score as goals_against
        from {{ ref('fct_matches') }}

        union all

        select world_cup_id, away_team_id as team_id, away_team_name as team_name,
               away_team_score as goals_for, home_team_score as goals_against
        from {{ ref('fct_matches') }}
    ) t
    group by world_cup_id, team_id, team_name

),

best_attack as (

    select
        world_cup_id,
        team_name as best_attack_team,
        goals_for as best_attack_goals,
        row_number() over (partition by world_cup_id order by goals_for desc) as rn
    from team_goals_per_cup

),

best_defense as (

    select
        world_cup_id,
        team_name as best_defense_team,
        goals_against as best_defense_goals,
        row_number() over (partition by world_cup_id order by goals_against asc) as rn
    from team_goals_per_cup

),

top_scorer_per_cup as (

    select
        world_cup_id,
        scorer_name,
        count(*) as goals,
        row_number() over (partition by world_cup_id order by count(*) desc) as rn
    from {{ ref('fct_match_goals') }}
    where goal_type != 'GOL_CONTRA'
      and scorer_name is not null
      and trim(scorer_name) != ''
    group by world_cup_id, scorer_name

),

final as (

    select
        wc.world_cup_id,
        wc.host_country,
        wc.champion_country,
        wc.champion_team_id,
        wc.runner_up_country,
        wc.runner_up_team_id,
        wc.total_teams_qualified,

        coalesce(ms.total_matches_calculated, wc.total_matches_played) as total_matches,
        ms.total_goals,
        round(ms.total_goals / nullif(ms.total_matches_calculated, 0), 2) as avg_goals_per_match,

        coalesce(ms.total_attendance_calculated, wc.total_attendance) as total_attendance,
        wc.avg_attendance,

        ba.best_attack_team,
        ba.best_attack_goals,
        bd.best_defense_team,
        bd.best_defense_goals,

        ts.scorer_name as top_scorer_name,
        ts.goals as top_scorer_goals,
        wc.top_scorer_details as top_scorer_details_source

    from world_cups wc
    left join matches_stats ms on wc.world_cup_id = ms.world_cup_id
    left join best_attack ba on wc.world_cup_id = ba.world_cup_id and ba.rn = 1
    left join best_defense bd on wc.world_cup_id = bd.world_cup_id and bd.rn = 1
    left join top_scorer_per_cup ts on wc.world_cup_id = ts.world_cup_id and ts.rn = 1

)

select * from final
order by world_cup_id desc