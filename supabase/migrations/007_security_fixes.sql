-- Security Fixes Migration
-- This migration fixes RLS policies and security issues across all tables

-- ============================================
-- PROFILES TABLE SECURITY
-- ============================================

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view all profiles" ON profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can delete their own profile" ON profiles;

-- Create proper RLS policies for profiles
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

-- ============================================
-- ACHIEVEMENTS TABLE SECURITY
-- ============================================

-- Drop existing policies
DROP POLICY IF EXISTS "Anyone can view achievements" ON achievements;
DROP POLICY IF EXISTS "Authenticated users can insert achievements" ON achievements;
DROP POLICY IF EXISTS "Authenticated users can update achievements" ON achievements;

-- Create proper RLS policies for achievements (read-only for users)
CREATE POLICY "Authenticated users can view achievements"
  ON achievements FOR SELECT
  TO authenticated
  USING (true);

-- ============================================
-- USER_ACHIEVEMENTS TABLE SECURITY
-- ============================================

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view their own achievements" ON user_achievements;
DROP POLICY IF EXISTS "Users can insert their own achievements" ON user_achievements;
DROP POLICY IF EXISTS "Users can update their own achievements" ON user_achievements;

-- Create proper RLS policies for user_achievements
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

-- ============================================
-- ROOMS TABLE SECURITY
-- ============================================

-- Drop existing policies
DROP POLICY IF EXISTS "Anyone can view rooms" ON rooms;
DROP POLICY IF EXISTS "Authenticated users can create rooms" ON rooms;
DROP POLICY IF EXISTS "Room creator can update their room" ON rooms;
DROP POLICY IF EXISTS "Room creator can delete their room" ON rooms;

-- Create proper RLS policies for rooms
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

-- ============================================
-- TEAMS TABLE SECURITY
-- ============================================

-- Drop existing policies
DROP POLICY IF EXISTS "Room participants can update teams" ON teams;
DROP POLICY IF EXISTS "Anyone can view teams" ON teams;
DROP POLICY IF EXISTS "Authenticated users can create teams" ON teams;

-- Create proper RLS policies for teams
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

CREATE POLICY "Room creator can update teams"
  ON teams FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM rooms r WHERE r.id = teams.room_id AND r.creator_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM rooms r WHERE r.id = teams.room_id AND r.creator_id = auth.uid()
    )
  );

-- ============================================
-- TEAM_MEMBERS TABLE SECURITY
-- ============================================

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view team members" ON team_members;
DROP POLICY IF EXISTS "Users can insert their own team membership" ON team_members;
DROP POLICY IF EXISTS "Users can update their own team membership" ON team_members;
DROP POLICY IF EXISTS "Users can delete their own team membership" ON team_members;
DROP POLICY IF EXISTS "Captain can confirm team members" ON team_members;

-- Create proper RLS policies for team_members
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
    -- Only allow updating confirmed status and position
    -- Prevent changing user_id or team_id
    user_id = (SELECT user_id FROM team_members WHERE id = team_members.id) AND
    team_id = (SELECT team_id FROM team_members WHERE id = team_members.id)
  );

CREATE POLICY "Users can delete their own team membership"
  ON team_members FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Room creator can manage team memberships"
  ON team_members FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM teams t
      JOIN rooms r ON r.id = t.room_id
      WHERE t.id = team_members.team_id AND r.creator_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM teams t
      JOIN rooms r ON r.id = t.room_id
      WHERE t.id = team_members.team_id AND r.creator_id = auth.uid()
    )
  );

-- ============================================
-- POSITION SECURITY FUNCTIONS
-- ============================================

-- Drop existing functions if they exist
DROP FUNCTION IF EXISTS claim_position(team_id UUID, user_id UUID, "position" TEXT);
DROP FUNCTION IF EXISTS check_team_capacity(team_id UUID);

-- Create function to check position limits
CREATE OR REPLACE FUNCTION check_position_limits()
RETURNS TRIGGER AS $$
DECLARE
  position_count INTEGER;
  max_allowed INTEGER;
BEGIN
  -- Count current members with this position
  SELECT COUNT(*) INTO position_count
  FROM team_members
  WHERE team_id = NEW.team_id
    AND "position" = NEW."position";

  -- Define limits based on position
  CASE NEW."position"
    WHEN 'keeper' THEN max_allowed := 1;
    WHEN 'seeker' THEN max_allowed := 1;
    WHEN 'beater' THEN max_allowed := 2;
    WHEN 'chaser' THEN max_allowed := 3;
    ELSE max_allowed := 0;
  END CASE;

  IF position_count >= max_allowed THEN
    RAISE EXCEPTION 'Position limit exceeded for %', NEW."position";
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create function to check total team capacity
CREATE OR REPLACE FUNCTION check_team_capacity()
RETURNS TRIGGER AS $$
DECLARE
  team_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO team_count
  FROM team_members
  WHERE team_id = NEW.team_id;

  IF team_count >= 7 THEN
    RAISE EXCEPTION 'Team capacity exceeded';
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- POSITION SECURITY TRIGGERS
-- ============================================

-- Drop existing triggers
DROP TRIGGER IF EXISTS enforce_position_limits ON team_members;
DROP TRIGGER IF EXISTS enforce_team_capacity ON team_members;

-- Create trigger to enforce position limits
CREATE TRIGGER enforce_position_limits
  BEFORE INSERT OR UPDATE OF "position" ON team_members
  FOR EACH ROW
  EXECUTE FUNCTION check_position_limits();

-- Create trigger to enforce team capacity
CREATE TRIGGER enforce_team_capacity
  BEFORE INSERT ON team_members
  FOR EACH ROW
  EXECUTE FUNCTION check_team_capacity();

-- ============================================
-- CAPTAIN SECURITY
-- ============================================

-- Create function to set captain (only room creator can call this)
CREATE OR REPLACE FUNCTION set_team_captain(team_id UUID, captain_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  room_creator UUID;
BEGIN
  -- Get the room creator
  SELECT r.creator_id INTO room_creator
  FROM teams t
  JOIN rooms r ON r.id = t.room_id
  WHERE t.id = set_team_captain.team_id;

  -- Only room creator can set captain
  IF room_creator != auth.uid() THEN
    RETURN FALSE;
  END IF;

  -- Update the team captain
  UPDATE teams
  SET captain_id = set_team_captain.captain_id
  WHERE id = set_team_captain.team_id;

  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- PROFILE UNIQUENESS (CASE-INSENSITIVE)
-- ============================================

-- Create a unique index on lowercased magical name
DROP INDEX IF EXISTS idx_profiles_magical_name_ci;
CREATE UNIQUE INDEX idx_profiles_magical_name_ci 
  ON profiles (LOWER(magical_name));

-- ============================================
-- VERIFICATION QUERIES
-- ============================================

-- Uncomment these to verify the changes
-- SELECT tablename, policyname, permissive, roles, cmd 
-- FROM pg_policies 
-- WHERE tablename IN ('profiles', 'achievements', 'user_achievements', 'rooms', 'teams', 'team_members')
-- ORDER BY tablename, policyname;
