  -- =============================================================================
  -- GOALKEEPER LOCK: Database-level validation
  -- Prevents goalkeeper movement even if client-side checks are bypassed
  -- =============================================================================

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
    v_is_member BOOLEAN;
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

    -- Every caller must be a member of this room, including solo players.
    -- Solo mode removes the captain requirement, not room authorization.
    SELECT EXISTS (
      SELECT 1
      FROM team_members tm
      JOIN teams t ON t.id = tm.team_id
      WHERE t.room_id = v_room_id AND tm.user_id = auth.uid()
    ) INTO v_is_member;

    IF NOT v_is_member THEN
      RETURN jsonb_build_object('success', false, 'error', 'You are not a player in this room.');
    END IF;
    
    -- GOALKEEPER LOCK: Validate that no goalkeeper pieces are being moved
    -- Check if any piece with type='GK' has changed position
    SELECT game_state INTO v_state 
    FROM quidditch_game_states 
    WHERE room_id = v_room_id;
    
    IF v_state IS NOT NULL THEN
      -- Compare old and new piece positions
      DECLARE
        v_old_pieces JSONB;
        v_new_pieces JSONB;
        v_piece JSONB;
        v_old_piece JSONB;
      BEGIN
        v_old_pieces := v_state->'pieces';
        v_new_pieces := p_game_state->'pieces';
        
        -- Check each piece in new state
        FOR v_piece IN SELECT * FROM jsonb_array_elements(v_new_pieces)
        LOOP
          -- If it's a goalkeeper
          IF v_piece->>'type' = 'GK' THEN
            -- Find corresponding old piece
            SELECT p INTO v_old_piece 
            FROM jsonb_array_elements(v_old_pieces) p 
            WHERE p->>'id' = v_piece->>'id' 
            LIMIT 1;
            
            -- If goalkeeper exists in old state, check if position changed
            IF v_old_piece IS NOT NULL THEN
              IF (v_old_piece->>'col' != v_piece->>'col' OR 
                  v_old_piece->>'row' != v_piece->>'row') THEN
                -- Return rejection WITH current game state for immediate UI revert
                SELECT game_state, revision INTO v_state, v_revision
                FROM quidditch_game_states 
                WHERE room_id = v_room_id;
                
                RETURN jsonb_build_object(
                  'success', false, 
                  'error', 'Goalkeeper cannot be moved.',
                  'pieceId', v_piece->>'id',
                  'game_state', v_state || jsonb_build_object('revision', v_revision)
                );
              END IF;
            END IF;
          END IF;
        END LOOP;
      END;
    END IF;
    
    -- In SOLO mode, skip only the captain check (all players are captains).
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

  -- Reload PostgREST schema
  NOTIFY pgrst, 'reload schema';
