-- ============================================================
-- Teste: test_team_record_consistency
-- Objetivo: Validar que a soma de vitórias + empates + derrotas
--           é igual ao total de partidas para cada seleção
-- ============================================================
-- A query retorna linhas quando há INCONSISTÊNCIA (teste falha)
-- Se retornar 0 linhas, tudo está ok (teste passa)

select
    team_id,
    team_name,
    total_matches,
    (total_wins + total_draws + total_losses) as sum_results,
    (total_wins + total_draws + total_losses) - total_matches as discrepancy
from {{ ref('analytics_team_overall_performance') }}
where (total_wins + total_draws + total_losses) != total_matches