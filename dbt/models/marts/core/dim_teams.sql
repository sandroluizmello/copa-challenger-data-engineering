with all_team_names as (

    select distinct trim(home_team_name) as team_name
    from {{ ref('stg_matches') }}

    union

    select distinct trim(away_team_name) as team_name
    from {{ ref('stg_matches') }}

    union

    select distinct team_name
    from {{ ref('stg_fifa_ranking') }}

),

-- Metadados vindos do Ranking FIFA
fifa_metadata as (

    select 
        team_name,
        max(team_code) as team_code,
        max(coalesce(continental_federation, 'Unknown')) as continental_federation
    from {{ ref('stg_fifa_ranking') }}
    group by 1

),

-- Mapeamento Histórico (Apenas para seleções extintas/dissolvidas)
historical_teams_mapping as (

    select 'Serbia and Montenegro' as team_name, 'SCG' as team_code, 'UEFA' as continental_federation
    union all select 'FR Yugoslavia', 'FRY', 'UEFA'
    union all select 'West Germany', 'FRG', 'UEFA'
    union all select 'Yugoslavia', 'YUG', 'UEFA'
    union all select 'Czechoslovakia', 'TCH', 'UEFA'
    union all select 'Soviet Union', 'URS', 'UEFA'
    union all select 'Germany DR', 'GDR', 'UEFA'
    union all select 'Zaire', 'ZAI', 'CAF'
    union all select 'Dutch East Indies', 'INA', 'AFC'

),

final as (

    select
        -- PK padronizada via MD5
        md5(t.team_name) as team_id,
        t.team_name,

        -- Prioriza os metadados da FIFA, se nulo/Unknown busca no mapeamento histórico
        coalesce(f.team_code, h.team_code) as team_code,
        coalesce(
            nullif(f.continental_federation, 'Unknown'), 
            h.continental_federation, 
            'Unknown'
        ) as continental_federation

    from all_team_names t
    left join fifa_metadata f 
        on t.team_name = f.team_name
    left join historical_teams_mapping h
        on t.team_name = h.team_name

)

select * from final