with matches as (

    select 
        match_id,
        edition_year as world_cup_id,
        md5(trim(home_team_name)) as home_team_id,
        md5(trim(away_team_name)) as away_team_id,
        trim(home_team_name) as home_team_name,
        trim(away_team_name) as away_team_name,
        
        -- Pênaltis Convertidos na Disputa (Mandante e Visitante)
        trim(both ']' from trim(both '[' from home_team_shootout_goals_timeline)) as home_shootout_goals_raw,
        trim(both ']' from trim(both '[' from away_team_shootout_goals_timeline)) as away_shootout_goals_raw,

        -- Pênaltis Perdidos na Disputa (Mandante e Visitante)
        trim(both ']' from trim(both '[' from home_team_shootout_misses_timeline)) as home_shootout_misses_raw,
        trim(both ']' from trim(both '[' from away_team_shootout_misses_timeline)) as away_shootout_misses_raw

    from {{ ref('stg_matches') }}

),

numbers as (
    select 1 as n union all select 2 union all select 3 union all select 4 union all select 5
    union all select 6 union all select 7 union all select 8 union all select 9 union all select 10
    union all select 11 union all select 12 union all select 13 union all select 14 union all select 15
),

-- Explode separado por VÍRGULA (', ')

-- 1. Pênaltis Convertidos - Mandante (HOME)
home_goals_exploded as (
    select
        m.match_id, m.world_cup_id, m.home_team_id as team_id, m.home_team_name as team_name,
        'HOME' as team_side, true as is_goal,
        trim(substring_index(substring_index(m.home_shootout_goals_raw, ', ', n.n), ', ', -1)) as shootout_raw_text
    from matches m
    inner join numbers n on n.n <= (length(m.home_shootout_goals_raw) - length(replace(m.home_shootout_goals_raw, ', ', '')) + 2) / 2
    where m.home_shootout_goals_raw is not null and m.home_shootout_goals_raw != ''
),

-- 2. Pênaltis Convertidos - Visitante (AWAY)
away_goals_exploded as (
    select
        m.match_id, m.world_cup_id, m.away_team_id as team_id, m.away_team_name as team_name,
        'AWAY' as team_side, true as is_goal,
        trim(substring_index(substring_index(m.away_shootout_goals_raw, ', ', n.n), ', ', -1)) as shootout_raw_text
    from matches m
    inner join numbers n on n.n <= (length(m.away_shootout_goals_raw) - length(replace(m.away_shootout_goals_raw, ', ', '')) + 2) / 2
    where m.away_shootout_goals_raw is not null and m.away_shootout_goals_raw != ''
),

-- 3. Pênaltis Perdidos - Mandante (HOME)
home_misses_exploded as (
    select
        m.match_id, m.world_cup_id, m.home_team_id as team_id, m.home_team_name as team_name,
        'HOME' as team_side, false as is_goal,
        trim(substring_index(substring_index(m.home_shootout_misses_raw, ', ', n.n), ', ', -1)) as shootout_raw_text
    from matches m
    inner join numbers n on n.n <= (length(m.home_shootout_misses_raw) - length(replace(m.home_shootout_misses_raw, ', ', '')) + 2) / 2
    where m.home_shootout_misses_raw is not null and m.home_shootout_misses_raw != ''
),

-- 4. Pênaltis Perdidos - Visitante (AWAY)
away_misses_exploded as (
    select
        m.match_id, m.world_cup_id, m.away_team_id as team_id, m.away_team_name as team_name,
        'AWAY' as team_side, false as is_goal,
        trim(substring_index(substring_index(m.away_shootout_misses_raw, ', ', n.n), ', ', -1)) as shootout_raw_text
    from matches m
    inner join numbers n on n.n <= (length(m.away_shootout_misses_raw) - length(replace(m.away_shootout_misses_raw, ', ', '')) + 2) / 2
    where m.away_shootout_misses_raw is not null and m.away_shootout_misses_raw != ''
),

all_shootouts_combined as (
    select * from home_goals_exploded
    union all select * from away_goals_exploded
    union all select * from home_misses_exploded
    union all select * from away_misses_exploded
),

parsed_text as (

    select
        md5(concat(match_id, team_side, cast(is_goal as char), shootout_raw_text)) as shootout_id,
        match_id,
        world_cup_id,
        team_id,
        team_name,
        team_side,
        is_goal,

        -- Ordem da cobrança (1º elemento antes do '|')
        cast(substring_index(shootout_raw_text, '|', 1) as signed) as shot_order,

        -- Placar no momento (2º elemento entre '|')
        substring_index(substring_index(shootout_raw_text, '|', 2), '|', -1) as score_at_moment,

        -- Nome do Jogador (3º elemento após o último '|')
        trim(substring_index(shootout_raw_text, '|', -1)) as player_name,

        shootout_raw_text

    from all_shootouts_combined

)

select 
    shootout_id,
    match_id,
    world_cup_id,
    team_id,
    team_name,
    team_side,
    shot_order,
    player_name,
    is_goal,
    score_at_moment,
    shootout_raw_text
from parsed_text
order by match_id, shot_order asc