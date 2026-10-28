-- Make the coin flip authoritative for the whole room.
-- The first successful caller chooses the starter; every later browser reuses it.

CREATE OR REPLACE FUNCTION public.begin_quidditch_match(p_room_code TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_room public.rooms%ROWTYPE;
  v_starting_team INTEGER;
  v_wheel_angle NUMERIC;
BEGIN
  SELECT * INTO v_room
  FROM public.rooms
  WHERE room_code = upper(trim(p_room_code))
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Room not found');
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.team_members tm
    JOIN public.teams t ON t.id = tm.team_id
    WHERE t.room_id = v_room.id AND tm.user_id = auth.uid()
  ) THEN
    RETURN jsonb_build_object('success', false, 'error', 'Only match players may start a match');
  END IF;

  IF v_room.status = 'finished' THEN
    RETURN jsonb_build_object('success', false, 'error', 'This match has finished');
  END IF;

  -- If another browser already started this room, never flip again.
  IF v_room.status = 'playing' AND v_room.starting_team IN (1, 2) THEN
    RETURN jsonb_build_object(
      'success', true,
      'starting_team', v_room.starting_team,
      'wheel_angle', v_room.starting_wheel_angle,
      'already_started', true
    );
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.teams
    WHERE room_id = v_room.id AND ready = false
  ) THEN
    RETURN jsonb_build_object('success', false, 'error', 'Both teams must be ready first');
  END IF;

  v_starting_team := CASE WHEN random() < 0.5 THEN 1 ELSE 2 END;
  -- Team 1 = Purple, Team 2 = Yellow.
  v_wheel_angle := 4320 + CASE WHEN v_starting_team = 1 THEN 270 ELSE 90 END;

  UPDATE public.rooms
  SET starting_team = v_starting_team,
      starting_wheel_angle = v_wheel_angle,
      match_started_at = COALESCE(match_started_at, timezone('utc', now())),
      status = 'playing',
      updated_at = timezone('utc', now())
  WHERE id = v_room.id;

  RETURN jsonb_build_object(
    'success', true,
    'starting_team', v_starting_team,
    'wheel_angle', v_wheel_angle,
    'already_started', false
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.begin_quidditch_match(TEXT) TO authenticated;
NOTIFY pgrst, 'reload schema';
