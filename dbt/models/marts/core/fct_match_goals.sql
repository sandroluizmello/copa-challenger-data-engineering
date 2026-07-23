with matches as (

    select 
        match_id,
        edition_year as world_cup_id,
        md5(trim(home_team_name)) as home_team_id,
        md5(trim(away_team_name)) as away_team_id,
        trim(home_team_name) as home_team_name,
        trim(away_team_name) as away_team_name,
        
        -- Timeline Principal
        trim(both ']' from trim(both '[' from home_team_goals_timeline)) as home_goals_raw,
        trim(both ']' from trim(both '[' from away_team_goals_timeline)) as away_goals_raw,

        -- Gols de Pênalti
        trim(both ']' from trim(both '[' from home_team_penalty_goals)) as home_penalty_goals_raw,
        trim(both ']' from trim(both '[' from away_team_penalty_goals)) as away_penalty_goals_raw,

        -- Gols Contra
        trim(both ']' from trim(both '[' from home_team_own_goals)) as home_own_goals_raw,
        trim(both ']' from trim(both '[' from away_team_own_goals)) as away_own_goals_raw

    from {{ ref('stg_matches') }}

),

numbers as (
    select 1 as n union all select 2 union all select 3 union all select 4 union all select 5
    union all select 6 union all select 7 union all select 8 union all select 9 union all select 10
    union all select 11 union all select 12 union all select 13 union all select 14 union all select 15
),

-- 1. Explode dos Gols de Timeline Principal
home_goals_exploded as (
    select
        m.match_id, m.world_cup_id, m.home_team_id as team_id, m.home_team_name as team_name,
        'HOME' as team_side, 'GOL_NORMAL' as goal_type_default,
        trim(substring_index(substring_index(m.home_goals_raw, ', ', n.n), ', ', -1)) as goal_raw_text
    from matches m
    inner join numbers n on n.n <= (length(m.home_goals_raw) - length(replace(m.home_goals_raw, ', ', '')) + 2) / 2
    where m.home_goals_raw is not null and m.home_goals_raw != ''
),

away_goals_exploded as (
    select
        m.match_id, m.world_cup_id, m.away_team_id as team_id, m.away_team_name as team_name,
        'AWAY' as team_side, 'GOL_NORMAL' as goal_type_default,
        trim(substring_index(substring_index(m.away_goals_raw, ', ', n.n), ', ', -1)) as goal_raw_text
    from matches m
    inner join numbers n on n.n <= (length(m.away_goals_raw) - length(replace(m.away_goals_raw, ', ', '')) + 2) / 2
    where m.away_goals_raw is not null and m.away_goals_raw != ''
),

-- 2. Explode de Pênaltis
home_penalty_exploded as (
    select
        m.match_id, m.world_cup_id, m.home_team_id as team_id, m.home_team_name as team_name,
        'HOME' as team_side, 'PENALTI' as goal_type_default,
        trim(substring_index(substring_index(m.home_penalty_goals_raw, '|', n.n), '|', -1)) as goal_raw_text
    from matches m
    inner join numbers n on n.n <= (length(m.home_penalty_goals_raw) - length(replace(m.home_penalty_goals_raw, '|', '')) + 1)
    where m.home_penalty_goals_raw is not null and m.home_penalty_goals_raw != ''
),

away_penalty_exploded as (
    select
        m.match_id, m.world_cup_id, m.away_team_id as team_id, m.away_team_name as team_name,
        'AWAY' as team_side, 'PENALTI' as goal_type_default,
        trim(substring_index(substring_index(m.away_penalty_goals_raw, '|', n.n), '|', -1)) as goal_raw_text
    from matches m
    inner join numbers n on n.n <= (length(m.away_penalty_goals_raw) - length(replace(m.away_penalty_goals_raw, '|', '')) + 1)
    where m.away_penalty_goals_raw is not null and m.away_penalty_goals_raw != ''
),

-- 3. Explode de Gols Contra
home_own_exploded as (
    select
        m.match_id, m.world_cup_id, m.home_team_id as team_id, m.home_team_name as team_name,
        'HOME' as team_side, 'GOL_CONTRA' as goal_type_default,
        trim(substring_index(substring_index(m.home_own_goals_raw, '|', n.n), '|', -1)) as goal_raw_text
    from matches m
    inner join numbers n on n.n <= (length(m.home_own_goals_raw) - length(replace(m.home_own_goals_raw, '|', '')) + 1)
    where m.home_own_goals_raw is not null and m.home_own_goals_raw != ''
),

away_own_exploded as (
    select
        m.match_id, m.world_cup_id, m.away_team_id as team_id, m.away_team_name as team_name,
        'AWAY' as team_side, 'GOL_CONTRA' as goal_type_default,
        trim(substring_index(substring_index(m.away_own_goals_raw, '|', n.n), '|', -1)) as goal_raw_text
    from matches m
    inner join numbers n on n.n <= (length(m.away_own_goals_raw) - length(replace(m.away_own_goals_raw, '|', '')) + 1)
    where m.away_own_goals_raw is not null and m.away_own_goals_raw != ''
),

all_goals_combined as (
    select * from home_goals_exploded
    union all select * from away_goals_exploded
    union all select * from home_penalty_exploded
    union all select * from away_penalty_exploded
    union all select * from home_own_exploded
    union all select * from away_own_exploded
),

parsed_text as (

    select
        md5(concat(match_id, team_side, goal_type_default, goal_raw_text)) as goal_id,
        match_id,
        world_cup_id,
        team_id,
        team_name,
        team_side,
        goal_type_default as goal_type,
        
        -- Extração do Minuto Texto
        case 
            when goal_type_default = 'GOL_NORMAL' then 
                trim(replace(substring_index(goal_raw_text, '|', 1), ';', ''))
            when goal_raw_text like '%·%' then 
                trim(substring_index(goal_raw_text, '·', -1))
            else null
        end as minute_text,
        
        -- Marcador do Gol
        case 
            when goal_type_default = 'GOL_NORMAL' then 
                trim(substring_index(substring_index(goal_raw_text, '|', 3), '|', -1))
            when goal_raw_text like '%·%' then 
                trim(replace(replace(substring_index(goal_raw_text, '·', 1), '(OG)', ''), '(P)', ''))
            else goal_raw_text
        end as scorer_name,
        
        -- Assistência
        case 
            when goal_type_default = 'GOL_NORMAL' and goal_raw_text like '%|Assist:|%' then 
                trim(substring_index(goal_raw_text, '|Assist:|', -1))
            else null
        end as assist_player_name,

        goal_raw_text

    from all_goals_combined

),

goals_with_minutes as (

    select
        goal_id,
        match_id,
        world_cup_id,
        team_id,
        team_name,
        team_side,
        goal_type,
        minute_text,

        case 
            when minute_text like '%+%' then 
                cast(substring_index(minute_text, '+', 1) as signed) + cast(substring_index(minute_text, '+', -1) as signed)
            when minute_text regexp '^[0-9]+$' then
                cast(minute_text as signed)
            else null
        end as minute_numeric,

        case 
            when minute_text like '%+%' then true 
            else false 
        end as is_stoppage_time,

        scorer_name,
        assist_player_name,
        goal_raw_text,

        -- Determina quem se beneficiou do gol (+1 Ponto)
        case 
            when (team_side = 'HOME' and goal_type != 'GOL_CONTRA') 
              or (team_side = 'AWAY' and goal_type = 'GOL_CONTRA') then 1 
            else 0 
        end as home_points,

        case 
            when (team_side = 'AWAY' and goal_type != 'GOL_CONTRA') 
              or (team_side = 'HOME' and goal_type = 'GOL_CONTRA') then 1 
            else 0 
        end as away_points

    from parsed_text

),

-- Recalculo dinâmico do placar por Window Function
final as (

    select
        goal_id,
        match_id,
        world_cup_id,
        team_id,
        team_name,
        team_side,
        goal_type,
        minute_text,
        minute_numeric,
        is_stoppage_time,

        -- Placar Recalculado Cronologicamente
        concat(
            sum(home_points) over (
                partition by match_id 
                order by minute_numeric asc, goal_id asc
                rows between unbounded preceding and current row
            ),
            ':',
            sum(away_points) over (
                partition by match_id 
                order by minute_numeric asc, goal_id asc
                rows between unbounded preceding and current row
            )
        ) as score_at_moment,

        scorer_name,
        assist_player_name,
        goal_raw_text

    from goals_with_minutes

)

select * from final