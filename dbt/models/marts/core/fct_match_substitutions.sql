with matches as (

    select 
        match_id,
        edition_year as world_cup_id,
        md5(trim(home_team_name)) as home_team_id,
        md5(trim(away_team_name)) as away_team_id,
        trim(home_team_name) as home_team_name,
        trim(away_team_name) as away_team_name,
        
        -- Substituições Mandante e Visitante
        trim(both ']' from trim(both '[' from home_team_substitutions)) as home_substitutions_raw,
        trim(both ']' from trim(both '[' from away_team_substitutions)) as away_substitutions_raw

    from {{ ref('stg_matches') }}

),

numbers as (
    select 1 as n union all select 2 union all select 3 union all select 4 union all select 5
    union all select 6 union all select 7 union all select 8 union all select 9 union all select 10
    union all select 11 union all select 12 union all select 13 union all select 14 union all select 15
),

-- 1. Explode Substituições Mandante (HOME)
home_subs_exploded as (
    select
        m.match_id, m.world_cup_id, m.home_team_id as team_id, m.home_team_name as team_name,
        'HOME' as team_side,
        trim(substring_index(substring_index(m.home_substitutions_raw, ', ', n.n), ', ', -1)) as sub_raw_text
    from matches m
    inner join numbers n on n.n <= (length(m.home_substitutions_raw) - length(replace(m.home_substitutions_raw, ', ', '')) + 2) / 2
    where m.home_substitutions_raw is not null and m.home_substitutions_raw != ''
),

-- 2. Explode Substituições Visitante (AWAY)
away_subs_exploded as (
    select
        m.match_id, m.world_cup_id, m.away_team_id as team_id, m.away_team_name as team_name,
        'AWAY' as team_side,
        trim(substring_index(substring_index(m.away_substitutions_raw, ', ', n.n), ', ', -1)) as sub_raw_text
    from matches m
    inner join numbers n on n.n <= (length(m.away_substitutions_raw) - length(replace(m.away_substitutions_raw, ', ', '')) + 2) / 2
    where m.away_substitutions_raw is not null and m.away_substitutions_raw != ''
),

all_subs_combined as (
    select * from home_subs_exploded
    union all select * from away_subs_exploded
),

parsed_text as (

    select
        md5(concat(match_id, team_side, sub_raw_text)) as substitution_id,
        match_id,
        world_cup_id,
        team_id,
        team_name,
        team_side,
        
        -- Extração do Minuto Texto (Antes do ';')
        case 
            when sub_raw_text like '%;%' then 
                trim(substring_index(sub_raw_text, ';', 1))
            when sub_raw_text like '%·%' then 
                trim(substring_index(sub_raw_text, '·', -1))
            else null
        end as minute_text,

        -- Extração do Jogador que ENTROU (3ª posição separada por '|')
        case 
            when sub_raw_text like '%|%|%' then 
                trim(substring_index(substring_index(sub_raw_text, '|', 3), '|', -1))
            when sub_raw_text like '%|In:|%' then 
                trim(substring_index(substring_index(sub_raw_text, '|In:|', -1), '|', 1))
            else null
        end as player_in_name,

        -- Extração do Jogador que SAIU (4ª posição separada por '|' removendo 'for ')
        case 
            when sub_raw_text like '%|for %' then 
                trim(replace(substring_index(sub_raw_text, '|', -1), 'for ', ''))
            when sub_raw_text like '%|Out:|%' then 
                trim(substring_index(sub_raw_text, '|Out:|', -1))
            else null
        end as player_out_name,

        sub_raw_text

    from all_subs_combined

),

final as (

    select
        substitution_id,
        match_id,
        world_cup_id,
        team_id,
        team_name,
        team_side,
        player_in_name,
        player_out_name,
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

        sub_raw_text

    from parsed_text

)

select * from final