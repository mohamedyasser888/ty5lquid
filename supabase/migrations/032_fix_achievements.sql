-- Fix achievement functions

CREATE OR REPLACE FUNCTION unlock_achievement(p_user_id UUID, p_name TEXT)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO user_achievements (user_id, achievement_id)
  SELECT p_user_id, id
  FROM achievements
  WHERE name = p_name
  ON CONFLICT (user_id, achievement_id) DO NOTHING;
END;
$$;

CREATE OR REPLACE FUNCTION evaluate_game_achievements(p_user_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_matches_played INTEGER;
  v_matches_won INTEGER;
  v_total_score INTEGER;
  v_total_saves INTEGER;
  v_has_snitch BOOLEAN;
  v_perfect_games INTEGER;
BEGIN
  -- Count matches played
  SELECT COUNT(*) INTO v_matches_played
  FROM match_results mr
  JOIN rooms r ON r.id = mr.room_id
  JOIN teams t ON t.room_id = r.id
  JOIN team_members tm ON tm.team_id = t.id
  WHERE tm.user_id = p_user_id;

  IF v_matches_played >= 1 THEN
    PERFORM unlock_achievement(p_user_id, 'First Flight');
  END IF;

  -- Count wins
  SELECT COUNT(*) INTO v_matches_won
  FROM match_results mr
  JOIN rooms r ON r.id = mr.room_id
  JOIN teams t ON t.room_id = r.id AND t.team_number = mr.winner_team
  JOIN team_members tm ON tm.team_id = t.id
  WHERE tm.user_id = p_user_id;

  IF v_matches_won >= 1 THEN
    PERFORM unlock_achievement(p_user_id, 'First Victory');
  END IF;
  IF v_matches_won >= 10 THEN
    PERFORM unlock_achievement(p_user_id, 'Victory Streak');
  END IF;

  -- Total score across all matches
  SELECT COALESCE(SUM(
    CASE WHEN t.team_number = 1 THEN mr.team1_score ELSE mr.team2_score END
  ), 0) INTO v_total_score
  FROM match_results mr
  JOIN rooms r ON r.id = mr.room_id
  JOIN teams t ON t.room_id = r.id
  JOIN team_members tm ON tm.team_id = t.id
  WHERE tm.user_id = p_user_id;

  IF v_total_score >= 100 THEN
    PERFORM unlock_achievement(p_user_id, 'Century Scorer');
  END IF;

  -- Total saves
  SELECT COALESCE(SUM(
    CASE WHEN t.team_number = 1 THEN mr.team1_saves ELSE mr.team2_saves END
  ), 0) INTO v_total_saves
  FROM match_results mr
  JOIN rooms r ON r.id = mr.room_id
  JOIN teams t ON t.room_id = r.id
  JOIN team_members tm ON tm.team_id = t.id
  WHERE tm.user_id = p_user_id;

  IF v_total_saves >= 10 THEN
    PERFORM unlock_achievement(p_user_id, 'Guardian');
  END IF;

  -- Check if user caught snitch
  SELECT EXISTS (
    SELECT 1 FROM match_results mr
    JOIN rooms r ON r.id = mr.room_id
    JOIN teams t ON t.room_id = r.id AND t.team_number = mr.snitch_team
    JOIN team_members tm ON tm.team_id = t.id
    WHERE tm.user_id = p_user_id
  ) INTO v_has_snitch;

  IF v_has_snitch THEN
    PERFORM unlock_achievement(p_user_id, 'Snitch Catcher');
  END IF;

  -- Perfect games (won with 100+ score)
  SELECT COUNT(*) INTO v_perfect_games
  FROM match_results mr
  JOIN rooms r ON r.id = mr.room_id
  JOIN teams t ON t.room_id = r.id AND t.team_number = mr.winner_team
  JOIN team_members tm ON tm.team_id = t.id
  WHERE tm.user_id = p_user_id
    AND (
      (t.team_number = 1 AND mr.team1_score >= 100) OR
      (t.team_number = 2 AND mr.team2_score >= 100)
    );

  IF v_perfect_games >= 1 THEN
    PERFORM unlock_achievement(p_user_id, 'Perfect Match');
  END IF;

  -- Legendary: 10 wins + 100 score + snitch + 10 saves
  IF v_matches_won >= 10 AND v_total_score >= 100 AND v_has_snitch AND v_total_saves >= 10 THEN
    PERFORM unlock_achievement(p_user_id, 'Legendary Wizard');
  END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION unlock_achievement(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION evaluate_game_achievements(UUID) TO authenticated;

NOTIFY pgrst, 'reload schema';
