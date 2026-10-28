-- Remove obsolete RPC overloads left by early manual migrations.
-- The application uses only:
--   save_quidditch_game_state(TEXT, JSONB, INTEGER)
--   record_match_result(TEXT, INTEGER, INTEGER, INTEGER, INTEGER, INTEGER, INTEGER)
-- The historical overloads can route calls to older logic or make manual
-- schema updates appear duplicated.

DROP FUNCTION IF EXISTS public.save_quidditch_game_state(TEXT, JSONB);
DROP FUNCTION IF EXISTS public.record_match_result(TEXT, INTEGER, INTEGER, INTEGER, INTEGER, INTEGER);

NOTIFY pgrst, 'reload schema';
