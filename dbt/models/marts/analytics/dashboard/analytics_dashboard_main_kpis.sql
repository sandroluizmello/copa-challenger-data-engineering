{{ config(
    materialized='view',
    schema='marts'
) }}

-- ============================================================
-- View: analytics_dashboard_main_kpis
-- Objetivo: Consolidar os principais KPIs do histórico das
-- Copas do Mundo em uma única linha, para alimentar o
-- cabeçalho/homepage do dashboard.
--
-- Observações de design:
--   - total_goals usa home_team_score + away_team_score de
--     fct_matches (fonte mais confiável que contar linhas de
--     fct_match_goals, que depende de parsing de texto).
--   - top_scorer usa scorer_name de fct_match_goals excluindo
--     GOL_CONTRA. Como esse campo vem de parsing de texto,
--     grafias diferentes do mesmo jogador podem gerar contagens
--     separadas — recomenda-se normalizar nomes futuramente.
-- ============================================================

with world_cups_stats as (

    select
        count(distinct world_cup_id) as total_world_cups
    from {{ ref('dim_world_cups') }}

),

matches_stats as (

    select
        count(distinct match_id) as total_matches,
        sum(home_team_score + away_team_score) as total_goals,
        sum(match_attendance) as total_attendance
    from {{ ref('fct_matches') }}

),

teams_stats as (

    select
        count(distinct team_id) as total_teams
    from {{ ref('dim_teams') }}

),

-- Times com mais partidas disputadas (mandante + visitante)
team_appearances as (

    select
        team_id,
        team_name,
        count(*) as total_matches_played
    from (
        select home_team_id as team_id, home_team_name as team_name
        from {{ ref('fct_matches') }}

        union all

        select away_team_id as team_id, away_team_name as team_name
        from {{ ref('fct_matches') }}
    ) all_matches
    group by team_id, team_name

),

most_appearances as (

    select
        team_name as team_most_appearances,
        total_matches_played as most_appearances_count
    from team_appearances
    order by total_matches_played desc
    limit 1

),

-- Seleção com mais títulos (campeão em dim_world_cups)
titles_count as (

    select
        champion_country,
        count(*) as titles
    from {{ ref('dim_world_cups') }}
    where champion_country is not null
    group by champion_country

),

most_titles as (

    select
        champion_country as team_most_titles,
        titles as most_titles_count
    from titles_count
    order by titles desc
    limit 1

),

-- Artilheiro histórico (desconsiderando gols contra)
top_scorer as (

    select
        scorer_name,
        count(*) as total_goals_scored
    from {{ ref('fct_match_goals') }}
    where goal_type != 'GOL_CONTRA'
      and scorer_name is not null
      and trim(scorer_name) != ''
    group by scorer_name
    order by total_goals_scored desc
    limit 1

),

final as (

    select
        wc.total_world_cups,
        m.total_matches,
        m.total_goals,
        round(m.total_goals / nullif(m.total_matches, 0), 2) as avg_goals_per_match,
        m.total_attendance,
        round(m.total_attendance / nullif(m.total_matches, 0), 0) as avg_attendance_per_match,
        t.total_teams,
        ma.team_most_appearances,
        ma.most_appearances_count,
        mt.team_most_titles,
        mt.most_titles_count,
        ts.scorer_name as top_scorer_name,
        ts.total_goals_scored as top_scorer_goals

    from world_cups_stats wc
    cross join matches_stats m
    cross join teams_stats t
    cross join most_appearances ma
    cross join most_titles mt
    cross join top_scorer ts

)

select * from final