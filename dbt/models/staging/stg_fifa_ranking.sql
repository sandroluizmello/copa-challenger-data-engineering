with source_fifa_ranking as (

    select * from {{ source('raw', 'fifa_ranking') }}

),

renamed as (

    select
        -- Padronização/Harmonização das Seleções
        case 
            when trim(team) = 'USA' then 'United States'
            when trim(team) = 'Czechia' then 'Czech Republic'
            else trim(team)
        end as team_name,

        trim(team_code) as team_code,
        trim(association) as continental_federation,

        -- Métricas e Posições do Ranking
        cast(`rank` as signed) as fifa_rank,
        cast(previous_rank as signed) as previous_fifa_rank,
        cast(points as decimal(6,2)) as total_points,
        cast(previous_points as decimal(6,2)) as previous_total_points

    from source_fifa_ranking

)

select * from renamed