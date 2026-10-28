-- Fix missing move_piece_captain_only function
-- Run this in Supabase SQL Editor or via CLI

CREATE OR REPLACE FUNCTION move_piece_captain_only(
  p_room_code TEXT,
  p_expected_revision INTEGER,
  p_game_state JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_room rooms%ROWTYPE;
  v_room_id UUID;
  v_team_id UUID;
  v_captain_id UUID;
  v_state JSONB;
  v_revision INTEGER;
BEGIN
  -- Look up the room
  SELECT * INTO v_room FROM rooms WHERE room_code = upper(trim(p_room_code));
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Room not found.');
  END IF;
  IF v_room.status <> 'playing' THEN
    RETURN jsonb_build_object('success', false, 'error', 'Match is not active.');
  END IF;
  v_room_id := v_room.id;
  
  -- In SOLO mode, skip captain check (all players are captains)
  IF v_room.mode <> 'solo' THEN
    -- Verify the caller is a captain of one of the teams in this room
    SELECT t.id, t.captain_id INTO v_team_id, v_captain_id
    FROM teams t
    JOIN team_members tm ON tm.team_id = t.id
    WHERE t.room_id = v_room_id AND tm.user_id = auth.uid()
    LIMIT 1;
    
    IF v_team_id IS NULL THEN
      RETURN jsonb_build_object('success', false, 'error', 'You are not a player in this room.');
    END IF;
    IF v_captain_id IS DISTINCT FROM auth.uid() THEN
      RETURN jsonb_build_object('success', false, 'error', 'Only the team captain can move pieces.');
    END IF;
  END IF;
  
  -- Optimistic concurrency update
  SELECT game_state, revision INTO v_state, v_revision
  FROM quidditch_game_states WHERE room_id = v_room_id FOR UPDATE;
  
  IF v_revision IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Game state unavailable.');
  END IF;
  
  IF v_revision <> p_expected_revision THEN
    RETURN jsonb_build_object(
      'success', false,
      'conflict', true,
      'game_state', v_state || jsonb_build_object('revision', v_revision)
    );
  END IF;
  
  UPDATE quidditch_game_states
  SET
    game_state = p_game_state - 'revision',
    revision   = revision + 1,
    updated_at = timezone('utc', now())
  WHERE room_id = v_room_id;
  
  RETURN jsonb_build_object('success', true, 'revision', v_revision + 1);
END;
$$;

GRANT EXECUTE ON FUNCTION move_piece_captain_only(TEXT, INTEGER, JSONB) TO authenticated;

-- Reload PostgREST schema
NOTIFY pgrst, 'reload schema';
