with source_fifa_ranking as (

    select * from {{ source('raw', 'fifa_ranking') }}

),

renamed as (

    select
        team as team_name,
        team_code,
        association as continental_federation,
        cast(`rank` as signed) as fifa_rank,
        cast(previous_rank as signed) as previous_fifa_rank,
        cast(points as decimal(6,2)) as total_points,
        cast(previous_points as decimal(6,2)) as previous_total_points
    from source_fifa_ranking

)

select * from renamed