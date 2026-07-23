with source_world_cup as (

    select * from {{ ref('stg_world_cup') }}

),

final as (

    select
        -- PK Natural (Ano)
        cast(edition_year as signed) as world_cup_id,
        
        -- Atributos de Texto Limpos
        trim(host_country) as host_country,
        
        -- Seleções Campeã e Vice
        trim(champion_country) as champion_country,
        trim(runner_up_country) as runner_up_country,

        -- Foreign Keys (FKs) para conectar com dim_teams em MD5
        md5(trim(champion_country)) as champion_team_id,
        md5(trim(runner_up_country)) as runner_up_team_id,

        -- Detalhes adicionais
        trim(top_scorer_details) as top_scorer_details,
        
        -- Métricas Numéricas da Edição
        cast(total_teams as signed) as total_teams_qualified,
        cast(total_matches as signed) as total_matches_played,
        cast(total_attendance as signed) as total_attendance,
        cast(avg_attendance as decimal(10,2)) as avg_attendance

    from source_world_cup

)

select * from final