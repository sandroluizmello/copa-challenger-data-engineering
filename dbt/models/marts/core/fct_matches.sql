with stg_matches as (

    select * from {{ ref('stg_matches') }}

),

final as (

    select
        -- Primary Key
        match_id,

        -- Foreign Keys (para Dimensões)
        edition_year as world_cup_id,
        md5(trim(home_team_name)) as home_team_id,
        md5(trim(away_team_name)) as away_team_id,
        md5(trim(stadium_name)) as stadium_id,

        -- Contexto da Partida
        host_country,
        match_date,
        match_round,
        main_referee_name,
        match_officials_list,
        match_notes,

        -- Time Mandante (Resumo)
        trim(home_team_name) as home_team_name,
        home_team_score,
        home_team_xg,
        home_team_manager,
        home_team_captain,
        home_team_penalty_shootout_score,

        -- Time Visitante (Resumo)
        trim(away_team_name) as away_team_name,
        away_team_score,
        away_team_xg,
        away_team_manager,
        away_team_captain,
        away_team_penalty_shootout_score,

        -- Placar e Público
        final_score_text,
        match_attendance

    from stg_matches

)

select * from final