with matches as (

    select 
        match_id,
        edition_year as world_cup_id,
        md5(trim(home_team_name)) as home_team_id,
        md5(trim(away_team_name)) as away_team_id,
        trim(home_team_name) as home_team_name,
        trim(away_team_name) as away_team_name,
        
        -- Cartões Mandante
        trim(both ']' from trim(both '[' from home_team_yellow_cards_timeline)) as home_yellow_cards_raw,
        trim(both ']' from trim(both '[' from home_team_red_cards)) as home_red_cards_raw,
        trim(both ']' from trim(both '[' from home_team_second_yellow_cards)) as home_second_yellow_cards_raw,

        -- Cartões Visitante
        trim(both ']' from trim(both '[' from away_team_yellow_cards_timeline)) as away_yellow_cards_raw,
        trim(both ']' from trim(both '[' from away_team_red_cards)) as away_red_cards_raw,
        trim(both ']' from trim(both '[' from away_team_second_yellow_cards)) as away_second_yellow_cards_raw

    from {{ ref('stg_matches') }}

),

numbers as (
    select 1 as n union all select 2 union all select 3 union all select 4 union all select 5
    union all select 6 union all select 7 union all select 8 union all select 9 union all select 10
    union all select 11 union all select 12 union all select 13 union all select 14 union all select 15
),

-- 1. Cartões Amarelos (HOME e AWAY) - Separados por vírgula
home_yellow_exploded as (
    select
        m.match_id, m.world_cup_id, m.home_team_id as team_id, m.home_team_name as team_name,
        'HOME' as team_side, 'AMARELO' as card_type,
        trim(substring_index(substring_index(m.home_yellow_cards_raw, ', ', n.n), ', ', -1)) as card_raw_text
    from matches m
    inner join numbers n on n.n <= (length(m.home_yellow_cards_raw) - length(replace(m.home_yellow_cards_raw, ', ', '')) + 2) / 2
    where m.home_yellow_cards_raw is not null and m.home_yellow_cards_raw != ''
),

away_yellow_exploded as (
    select
        m.match_id, m.world_cup_id, m.away_team_id as team_id, m.away_team_name as team_name,
        'AWAY' as team_side, 'AMARELO' as card_type,
        trim(substring_index(substring_index(m.away_yellow_cards_raw, ', ', n.n), ', ', -1)) as card_raw_text
    from matches m
    inner join numbers n on n.n <= (length(m.away_yellow_cards_raw) - length(replace(m.away_yellow_cards_raw, ', ', '')) + 2) / 2
    where m.away_yellow_cards_raw is not null and m.away_yellow_cards_raw != ''
),

-- 2. Cartões Vermelhos Diretos (HOME e AWAY) - Separados por PIPE '|'
home_red_exploded as (
    select
        m.match_id, m.world_cup_id, m.home_team_id as team_id, m.home_team_name as team_name,
        'HOME' as team_side, 'VERMELHO' as card_type,
        trim(substring_index(substring_index(m.home_red_cards_raw, '|', n.n), '|', -1)) as card_raw_text
    from matches m
    inner join numbers n on n.n <= (length(m.home_red_cards_raw) - length(replace(m.home_red_cards_raw, '|', '')) + 1)
    where m.home_red_cards_raw is not null and m.home_red_cards_raw != ''
),

away_red_exploded as (
    select
        m.match_id, m.world_cup_id, m.away_team_id as team_id, m.away_team_name as team_name,
        'AWAY' as team_side, 'VERMELHO' as card_type,
        trim(substring_index(substring_index(m.away_red_cards_raw, '|', n.n), '|', -1)) as card_raw_text
    from matches m
    inner join numbers n on n.n <= (length(m.away_red_cards_raw) - length(replace(m.away_red_cards_raw, '|', '')) + 1)
    where m.away_red_cards_raw is not null and m.away_red_cards_raw != ''
),

-- 3. Segundo Amarelo / Vermelho (HOME e AWAY) - Separados por PIPE '|'
home_second_yellow_exploded as (
    select
        m.match_id, m.world_cup_id, m.home_team_id as team_id, m.home_team_name as team_name,
        'HOME' as team_side, 'SEGUNDO_AMARELO' as card_type,
        trim(substring_index(substring_index(m.home_second_yellow_cards_raw, '|', n.n), '|', -1)) as card_raw_text
    from matches m
    inner join numbers n on n.n <= (length(m.home_second_yellow_cards_raw) - length(replace(m.home_second_yellow_cards_raw, '|', '')) + 1)
    where m.home_second_yellow_cards_raw is not null and m.home_second_yellow_cards_raw != ''
),

away_second_yellow_exploded as (
    select
        m.match_id, m.world_cup_id, m.away_team_id as team_id, m.away_team_name as team_name,
        'AWAY' as team_side, 'SEGUNDO_AMARELO' as card_type,
        trim(substring_index(substring_index(m.away_second_yellow_cards_raw, '|', n.n), '|', -1)) as card_raw_text
    from matches m
    inner join numbers n on n.n <= (length(m.away_second_yellow_cards_raw) - length(replace(m.away_second_yellow_cards_raw, '|', '')) + 1)
    where m.away_second_yellow_cards_raw is not null and m.away_second_yellow_cards_raw != ''
),

all_cards_combined as (
    select * from home_yellow_exploded
    union all select * from away_yellow_exploded
    union all select * from home_red_exploded
    union all select * from away_red_exploded
    union all select * from home_second_yellow_exploded
    union all select * from away_second_yellow_exploded
),

parsed_text as (

    select
        md5(concat(match_id, team_side, card_type, card_raw_text)) as card_id,
        match_id,
        world_cup_id,
        team_id,
        team_name,
        team_side,
        card_type,
        
        -- Extração do Jogador (Pega após o último pipe '|', ou antes de '·' se for formato alternativo)
        case 
            when card_raw_text like '%|%' then 
                trim(substring_index(card_raw_text, '|', -1))
            when card_raw_text like '%·%' then 
                trim(substring_index(card_raw_text, '·', 1))
            else card_raw_text
        end as player_name,
        
        -- Extração do Minuto Texto (Pega antes do ';' ou depois do '·')
        case 
            when card_raw_text like '%;%' then 
                trim(substring_index(card_raw_text, ';', 1))
            when card_raw_text like '%·%' then 
                trim(substring_index(card_raw_text, '·', -1))
            else null
        end as minute_text,

        card_raw_text

    from all_cards_combined

),

final as (

    select
        card_id,
        match_id,
        world_cup_id,
        team_id,
        team_name,
        team_side,
        card_type,
        player_name,
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

        card_raw_text

    from parsed_text

)

select * from final