-- Verify the function has solo mode check
SELECT 
  routine_name,
  CASE 
    WHEN routine_definition LIKE '%solo%' THEN 'HAS SOLO MODE CHECK ✓'
    ELSE 'MISSING SOLO MODE CHECK ✗'
  END as status
FROM information_schema.routines 
WHERE routine_name = 'move_piece_captain_only';
