with raw_stadiums as (

    select distinct
        -- Extrai tudo ANTES da vírgula (Nome do Estádio)
        trim(substring_index(stadium_name, ',', 1)) as stadium_name,
        
        -- Extrai tudo DEPOIS da vírgula (Nome da Cidade)
        -- Se não houver vírgula, assume 'Unknown'
        case 
            when stadium_name like '%,%' then trim(substring_index(stadium_name, ',', -1))
            else 'Unknown'
        end as city_name,

        trim(host_country) as country_name

    from {{ ref('stg_matches') }}
    where stadium_name is not null and trim(stadium_name) != ''

),

stadiums_unique as (

    select
        stadium_name,
        max(city_name) as city_name,
        max(country_name) as country_name
    from raw_stadiums
    group by 1

),

final as (

    select
        -- PK padronizada em MD5 a partir do nome limpo do estádio
        md5(stadium_name) as stadium_id,
        stadium_name,
        city_name,
        country_name

    from stadiums_unique

)

select * from final