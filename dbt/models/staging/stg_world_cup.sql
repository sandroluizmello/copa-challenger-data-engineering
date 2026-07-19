with source_world_cup as (

    select * from {{ source('raw', 'world_cup') }}

),

renamed as (

    select
        cast(Year as json) as edition_year, -- Mantendo consistência de tipo para anos
        Host as host_country,
        Teams as total_teams,
        Champion as champion_country,
        `Runner-Up` as runner_up_country,
        TopScorrer as top_scorer_details,
        Attendance as total_attendance,
        AttendanceAvg as avg_attendance,
        Matches as total_matches
    from source_world_cup

)

select * from renamed