-- ============================================================
-- Teste: test_no_negative_goals
-- Objetivo: Validar que não existe nenhum registro com gols
--           negativos em fct_matches, analytics_team_overall_performance,
--           analytics_world_cup_summary, etc
-- ============================================================
-- A query retorna linhas quando há GOLS NEGATIVOS (teste falha)
-- Se retornar 0 linhas, tudo está ok (teste passa)

-- Verificar fct_matches
select
    'fct_matches - home_team_score' as source,
    match_id,
    home_team_score as negative_value
from {{ ref('fct_matches') }}
where home_team_score < 0

union all

select
    'fct_matches - away_team_score' as source,
    match_id,
    away_team_score as negative_value
from {{ ref('fct_matches') }}
where away_team_score < 0

union all

-- Verificar analytics_team_overall_performance
select
    'analytics_team_overall_performance - total_goals_for' as source,
    team_id,
    total_goals_for as negative_value
from {{ ref('analytics_team_overall_performance') }}
where total_goals_for < 0

union all

select
    'analytics_team_overall_performance - total_goals_against' as source,
    team_id,
    total_goals_against as negative_value
from {{ ref('analytics_team_overall_performance') }}
where total_goals_against < 0

union all

-- Verificar analytics_world_cup_summary
select
    'analytics_world_cup_summary - total_goals' as source,
    world_cup_id,
    total_goals as negative_value
from {{ ref('analytics_world_cup_summary') }}
where total_goals < 0