-- Restore the position-claim RPC removed by migration 007 and remove the old
-- one-player-per-position constraint, which made a 7-player team impossible.
ALTER TABLE team_members
  DROP CONSTRAINT IF EXISTS unique_position_per_team;

CREATE OR REPLACE FUNCTION enforce_team_position_limits()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
DECLARE
  v_limit INTEGER;
BEGIN
  v_limit := CASE NEW.position
    WHEN 'keeper' THEN 1
    WHEN 'chaser' THEN 3
    WHEN 'beater' THEN 2
    WHEN 'seeker' THEN 1
    ELSE 0
  END;

  IF v_limit = 0 OR (
    SELECT COUNT(*) FROM team_members
    WHERE team_id = NEW.team_id
      AND position = NEW.position
      AND id <> COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::uuid)
  ) >= v_limit THEN
    RAISE EXCEPTION 'Position % is full', NEW.position;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS enforce_position_limits ON team_members;
CREATE TRIGGER enforce_position_limits
  BEFORE INSERT OR UPDATE OF "position" ON team_members
  FOR EACH ROW EXECUTE FUNCTION enforce_team_position_limits();

-- The legacy RPC returned JSON. PostgreSQL cannot change a function return
-- type through CREATE OR REPLACE, so remove that exact signature first.
DROP FUNCTION IF EXISTS claim_position(UUID, UUID, TEXT);

CREATE OR REPLACE FUNCTION claim_position(
  p_team_id UUID,
  p_user_id UUID,
  p_position TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_room_id UUID;
  v_status TEXT;
BEGIN
  IF p_user_id IS DISTINCT FROM auth.uid() THEN
    RETURN jsonb_build_object('success', false, 'error', 'You may only claim a position for yourself');
  END IF;
  SELECT t.room_id, r.status INTO v_room_id, v_status
  FROM teams t JOIN rooms r ON r.id = t.room_id WHERE t.id = p_team_id;
  IF v_room_id IS NULL OR v_status <> 'waiting' THEN
    RETURN jsonb_build_object('success', false, 'error', 'This room is no longer accepting players');
  END IF;
  IF EXISTS (
    SELECT 1 FROM team_members tm JOIN teams t ON t.id = tm.team_id
    WHERE t.room_id = v_room_id AND tm.user_id = auth.uid()
  ) THEN
    RETURN jsonb_build_object('success', false, 'error', 'You are already in this room');
  END IF;
  IF (SELECT COUNT(*) FROM team_members WHERE team_id = p_team_id) >= 7 THEN
    RETURN jsonb_build_object('success', false, 'error', 'That team is full');
  END IF;
  INSERT INTO team_members (team_id, user_id, position, confirmed)
  VALUES (p_team_id, auth.uid(), p_position, true);
  RETURN jsonb_build_object('success', true);
EXCEPTION WHEN unique_violation OR check_violation OR raise_exception THEN
  RETURN jsonb_build_object('success', false, 'error', 'That position is no longer available');
END;
$$;

GRANT EXECUTE ON FUNCTION claim_position(UUID, UUID, TEXT) TO authenticated;
NOTIFY pgrst, 'reload schema';
