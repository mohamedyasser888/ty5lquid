-- Comprehensive Security Migration

-- 1. PROFILES
DROP POLICY IF EXISTS "Anyone can view profiles" ON profiles;
DROP POLICY IF EXISTS "Users can view all profiles" ON profiles;
DROP POLICY IF EXISTS "Authenticated users can view profiles" ON profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can delete their own profile" ON profiles;

CREATE POLICY "Authenticated users can view profiles"
  ON profiles FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can insert their own profile"
  ON profiles FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
  ON profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can delete their own profile"
  ON profiles FOR DELETE
  TO authenticated
  USING (auth.uid() = id);

-- Case-insensitive magical_name index
DROP INDEX IF EXISTS idx_profiles_magical_name_ci;
CREATE UNIQUE INDEX idx_profiles_magical_name_ci 
  ON profiles (LOWER(magical_name));

-- 2. ACHIEVEMENTS
DROP POLICY IF EXISTS "Anyone can view achievements" ON achievements;
DROP POLICY IF EXISTS "Authenticated users can view achievements" ON achievements;
DROP POLICY IF EXISTS "Authenticated users can insert achievements" ON achievements;
DROP POLICY IF EXISTS "Authenticated users can update achievements" ON achievements;

CREATE POLICY "Authenticated users can view achievements"
  ON achievements FOR SELECT
  TO authenticated
  USING (true);

-- 3. USER_ACHIEVEMENTS
DROP POLICY IF EXISTS "Users can view their own achievements" ON user_achievements;
DROP POLICY IF EXISTS "Users can insert their own achievements" ON user_achievements;
DROP POLICY IF EXISTS "Users can update their own achievements" ON user_achievements;

CREATE POLICY "Users can view their own achievements"
  ON user_achievements FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own achievements"
  ON user_achievements FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own achievements"
  ON user_achievements FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- 4. ROOMS
DROP POLICY IF EXISTS "Anyone can view rooms" ON rooms;
DROP POLICY IF EXISTS "Authenticated users can view rooms" ON rooms;
DROP POLICY IF EXISTS "Authenticated users can create rooms" ON rooms;
DROP POLICY IF EXISTS "Room creator can update their room" ON rooms;
DROP POLICY IF EXISTS "Room creator can delete their room" ON rooms;

CREATE POLICY "Authenticated users can view rooms"
  ON rooms FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can create rooms"
  ON rooms FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = creator_id);

CREATE POLICY "Room creator can update their room"
  ON rooms FOR UPDATE
  TO authenticated
  USING (auth.uid() = creator_id)
  WITH CHECK (auth.uid() = creator_id);

CREATE POLICY "Room creator can delete their room"
  ON rooms FOR DELETE
  TO authenticated
  USING (auth.uid() = creator_id);

-- 5. TEAMS
DROP POLICY IF EXISTS "Anyone can view teams" ON teams;
DROP POLICY IF EXISTS "Authenticated users can view teams" ON teams;
DROP POLICY IF EXISTS "Authenticated users can create teams" ON teams;
DROP POLICY IF EXISTS "Room creator can create teams" ON teams;
DROP POLICY IF EXISTS "Room participants can update teams" ON teams;
DROP POLICY IF EXISTS "Room creator can update teams" ON teams;
DROP POLICY IF EXISTS "Room creator and captains can update teams" ON teams;

CREATE POLICY "Authenticated users can view teams"
  ON teams FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Room creator can create teams"
  ON teams FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM rooms r WHERE r.id = teams.room_id AND r.creator_id = auth.uid()
    )
  );

CREATE POLICY "Room creator and captains can update teams"
  ON teams FOR UPDATE
  TO authenticated
  USING (
    captain_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM rooms r WHERE r.id = teams.room_id AND r.creator_id = auth.uid()
    )
  )
  WITH CHECK (
    captain_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM rooms r WHERE r.id = teams.room_id AND r.creator_id = auth.uid()
    )
  );

-- 6. TEAM_MEMBERS
DROP POLICY IF EXISTS "Users can view team members" ON team_members;
DROP POLICY IF EXISTS "Authenticated users can view team members" ON team_members;
DROP POLICY IF EXISTS "Users can insert their own team membership" ON team_members;
DROP POLICY IF EXISTS "Users can update their own team membership" ON team_members;
DROP POLICY IF EXISTS "Users can delete their own team membership" ON team_members;
DROP POLICY IF EXISTS "Captain can confirm team members" ON team_members;
DROP POLICY IF EXISTS "Room creator can manage team memberships" ON team_members;
DROP POLICY IF EXISTS "Captains can manage team memberships" ON team_members;

CREATE POLICY "Authenticated users can view team members"
  ON team_members FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can insert their own team membership"
  ON team_members FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own team membership"
  ON team_members FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (
    auth.uid() = user_id AND
    user_id = (SELECT user_id FROM team_members WHERE id = team_members.id) AND
    team_id = (SELECT team_id FROM team_members WHERE id = team_members.id)
  );

CREATE POLICY "Users can delete their own team membership"
  ON team_members FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Captains can manage team memberships"
  ON team_members FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM teams t
      WHERE t.id = team_members.team_id AND t.captain_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM teams t
      WHERE t.id = team_members.team_id AND t.captain_id = auth.uid()
    )
  );

-- 7. POSITION SECURITY FUNCTIONS & TRIGGERS
DROP TRIGGER IF EXISTS enforce_position_limits ON team_members;
DROP TRIGGER IF EXISTS enforce_team_capacity ON team_members;

CREATE OR REPLACE FUNCTION check_position_limits()
RETURNS TRIGGER AS $$
DECLARE
  position_count INTEGER;
  max_allowed INTEGER;
BEGIN
  SELECT COUNT(*) INTO position_count
  FROM team_members
  WHERE team_id = NEW.team_id
    AND "position" = NEW."position"
    AND id != COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::uuid);

  CASE NEW."position"
    WHEN 'keeper' THEN max_allowed := 1;
    WHEN 'seeker' THEN max_allowed := 1;
    WHEN 'beater' THEN max_allowed := 2;
    WHEN 'chaser' THEN max_allowed := 3;
    ELSE max_allowed := 0;
  END CASE;

  IF position_count >= max_allowed THEN
    RAISE EXCEPTION 'Maximum limit reached for position %', NEW."position";
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION check_team_capacity()
RETURNS TRIGGER AS $$
DECLARE
  team_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO team_count
  FROM team_members
  WHERE team_id = NEW.team_id
    AND id != COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::uuid);

  IF team_count >= 7 THEN
    RAISE EXCEPTION 'Team is already full';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER enforce_position_limits
  BEFORE INSERT OR UPDATE OF "position" ON team_members
  FOR EACH ROW
  EXECUTE FUNCTION check_position_limits();

CREATE TRIGGER enforce_team_capacity
  BEFORE INSERT ON team_members
  FOR EACH ROW
  EXECUTE FUNCTION check_team_capacity();

CREATE OR REPLACE FUNCTION prevent_unauthorized_confirm()
RETURNS TRIGGER AS 
DECLARE
  is_captain BOOLEAN;
BEGIN
  IF NEW.confirmed IS DISTINCT FROM OLD.confirmed THEN
    SELECT EXISTS (
      SELECT 1 FROM teams WHERE id = NEW.team_id AND captain_id = auth.uid()
    ) INTO is_captain;

    IF NOT is_captain THEN
      RAISE EXCEPTION 'Only the team captain can confirm members';
    END IF;
  END IF;
  RETURN NEW;
END;
 LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS check_confirm_auth ON team_members;
CREATE TRIGGER check_confirm_auth
  BEFORE UPDATE ON team_members
  FOR EACH ROW
  EXECUTE FUNCTION prevent_unauthorized_confirm();

-- 8. CAPTAIN SECURITY
CREATE OR REPLACE FUNCTION set_team_captain(team_id UUID, new_captain_id UUID)
RETURNS BOOLEAN AS 
DECLARE
  room_creator UUID;
  is_already_captain UUID;
BEGIN
  SELECT r.creator_id, t.captain_id INTO room_creator, is_already_captain
  FROM teams t
  JOIN rooms r ON r.id = t.room_id
  WHERE t.id = set_team_captain.team_id;

  IF room_creator != auth.uid() AND is_already_captain != auth.uid() THEN
    RETURN FALSE;
  END IF;

  UPDATE teams
  SET captain_id = set_team_captain.new_captain_id
  WHERE id = set_team_captain.team_id;

  RETURN TRUE;
END;
 LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION set_team_captain(UUID, UUID) TO authenticated;
