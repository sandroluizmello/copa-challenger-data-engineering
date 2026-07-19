with source_matches as (

    select * from {{ source('raw', 'matches') }}

),

renamed as (

    select
        -- Chaves e Identificadores Gerados
        md5(concat(coalesce(Date, ''), coalesce(home_team, ''), coalesce(away_team, ''))) as match_id,
        cast(Year as signed) as edition_year,
        Host as host_country,
        
        -- Informações Espaço-Temporais
        cast(Date as datetime) as match_timestamp,
        Round as match_round,
        Venue as stadium_name,
        Officials as match_officials_list,
        Referee as main_referee_name,
        Notes as match_notes,

        -- Informações Placar Geral
        Score as final_score_text,

        -- Bloco Seleção Mandante (Home Team)
        home_team as home_team_name,
        cast(home_score as signed) as home_team_score,
        cast(home_xg as decimal(4,2)) as home_team_xg,
        home_manager as home_team_manager,
        home_captain as home_team_captain,
        home_penalty as home_team_penalty_shootout_score,
        home_goal as home_team_goals_summary,
        home_goal_long as home_team_goals_timeline,
        home_own_goal as home_team_own_goals,
        home_penalty_goal as home_team_penalty_goals,
        home_substitute_in_long as home_team_substitutions,
        
        -- Cartões Mandante
        home_red_card as home_team_red_cards,
        home_yellow_red_card as home_team_second_yellow_cards,
        home_yellow_card_long as home_team_yellow_cards_timeline,
        
        -- Erros de Pênalti Mandante
        home_penalty_miss_long as home_team_penalty_misses_timeline,
        home_penalty_shootout_goal_long as home_team_shootout_goals_timeline,
        home_penalty_shootout_miss_long as home_team_shootout_misses_timeline,

        -- Bloco Seleção Visitante (Away Team)
        away_team as away_team_name,
        cast(away_score as signed) as away_team_score,
        cast(away_xg as decimal(4,2)) as away_team_xg,
        away_manager as away_team_manager,
        away_captain as away_team_captain,
        away_penalty as away_team_penalty_shootout_score,
        away_goal as away_team_goals_summary,
        away_goal_long as away_team_goals_timeline,
        away_own_goal as away_team_own_goals,
        away_penalty_goal as away_team_penalty_goals,
        away_substitute_in_long as away_team_substitutions,
        
        -- Cartões Visitante
        away_red_card as away_team_red_cards,
        away_yellow_red_card as away_team_second_yellow_cards,
        away_yellow_card_long as away_team_yellow_cards_timeline,
        
        -- Erros de Pênalti Visitante
        away_penalty_miss_long as away_team_penalty_misses_timeline,
        away_penalty_shootout_goal_long as away_team_shootout_goals_timeline,
        away_penalty_shootout_miss_long as away_team_shootout_misses_timeline,

        -- Métricas Gerais do Evento
        cast(Attendance as signed) as match_attendance

    from source_matches

)

select * from renamed