(defun c:move2origin ()
  (setq pt (getpoint "\nSelect point to move to origin: ")) ; Prompt the user to select a point
  (if pt
    (command "move" "all" "" pt "0,0,0")
    (princ "\nNo point selected.")
  )
  (princ) ; Exit quietly
)
