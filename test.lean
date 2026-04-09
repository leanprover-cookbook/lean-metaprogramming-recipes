/-- 
Spawns multiple asynchronous tasks and prints their Thread IDs. 
All will share the same PID but likely report distinct TIDs.
-/
def showMultiThreadInfo : IO Unit := do
  let pid ← IO.Process.getPID
  IO.println s!"Main Process PID: {pid}"

  let tasks ← (List.range 4).mapM fun i => 
    IO.asTask (do
      let tid ← IO.getTID
      IO.println s!"Task {i} running on TID: {tid} (PID: {pid})"
    )

  -- Wait for all tasks to complete
  for t in tasks do
    let _ ← IO.wait t

#eval showMultiThreadInfo
