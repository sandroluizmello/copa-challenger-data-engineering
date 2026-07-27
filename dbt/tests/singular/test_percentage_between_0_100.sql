-- ============================================================
-- Teste: test_percentage_between_0_100
-- Objetivo: Validar que nenhuma coluna de percentual está
--           fora do range [0, 100]
-- ============================================================
-- A query retorna linhas quando há PERCENTUAIS INVÁLIDOS
-- Se retornar 0 linhas, tudo está ok (teste passa)

-- Verificar analytics_team_overall_performance
select
    'analytics_team_overall_performance - win_rate_pct' as source,
    team_id,
    team_name,
    win_rate_pct as invalid_percentage
from {{ ref('analytics_team_overall_performance') }}
where win_rate_pct < 0 or win_rate_pct > 100

union all

-- Verificar analytics_team_by_world_cup
select
    'analytics_team_by_world_cup - win_rate_pct' as source,
    team_id,
    team_name,
    win_rate_pct as invalid_percentage
from {{ ref('analytics_team_by_world_cup') }}
where win_rate_pct < 0 or win_rate_pct > 100

union all

-- Verificar analytics_world_cup_summary
select
    'analytics_world_cup_summary - avg_goals_per_match' as source,
    world_cup_id,
    host_country as team_name,
    avg_goals_per_match as invalid_percentage
from {{ ref('analytics_world_cup_summary') }}
where avg_goals_per_match < 0

union all

-- Verificar analytics_team_evolution_over_time
select
    'analytics_team_evolution_over_time - win_rate_pct' as source,
    team_id,
    team_name,
    win_rate_pct as invalid_percentage
from {{ ref('analytics_team_evolution_over_time') }}
where win_rate_pct < 0 or win_rate_pct > 100