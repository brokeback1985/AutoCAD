(defun c:TidyUp ()
  ;; Function to show an alert box and exit if cancelled
  (defun show-alert-and-exit (message)
    (initget "OK Cancel")
    (setq response (getkword (strcat message "\n[OK/Cancel]")))
    (if (not (= response "OK"))
      (exit)
    )
  )

  ;; Step 1: Initial Confirmation Pop-Up with Cancel Option
  (show-alert-and-exit 
    "Have you:\n\n- Saved the DWG before running Script?\n- Turned on all layers.\n- Zoomed to extents.\n- Deleted anything out of scope of the site.\n- Checked the CAD aligns to the project's coordinates.\n- IMPORTANT-Check all viewports on paper spaces are closed (if not ALL content will be deleted).\n\nClick OK to proceed."
  )

  ;; Step 2: Operation Description Pop-Up with Cancel Option
  (show-alert-and-exit 
    "This script will:\n\n- Explode blocks (x5 for any nested blocks).\n- Delete all hatch patterns.\n- Remove all current paper space content.\n- Audit the DWG for any errors.\n- Purge unused items.\n\nThis will optimise the DWG for linking into Revit.\nIf the above is acceptable, click OK. If not, click Cancel."
  )

  ;; Step 3: Close all viewports on all layout tabs
  (princ "\nClosing all viewports on all layout tabs...")
  (foreach lay (layoutlist)
    (command "._-LAYOUT" "_SET" lay)
    (setq ss (ssget "X" '((0 . "VIEWPORT"))))
    (if ss
      (command "._ERASE" ss "")
    )
  )

  ;; Step 4: Delete All Paper Space Tabs Except Layout1
  (princ "\nDeleting paper space tabs...")
  (foreach lay (layoutlist)
    (if (/= lay "Layout1")
      (command "._-LAYOUT" "_DELETE" lay)
    )
  )

  ;; Step 5: Select All Content in Layout1 and Delete
  (princ "\nSelecting and deleting all content in Layout1...")
  (command "._-LAYOUT" "_SET" "Layout1")
  (setq ss (ssget "X"))
  (if ss
    (command "._ERASE" ss "")
    (princ "\nNo content found in Layout1.")
  )

  ;; Step 6: Switch to Model Space and Delete All Hatch Patterns
  (command "._LAYOUT" "_SET" "Model")
  (princ "\nSwitching to model space and deleting hatch patterns...")

  ;; Make sure all layers are on and thawed
  (command "._-LAYER" "_THAW" "*" "_ON" "*" "")

  ;; Zoom to extents to ensure all hatches are in view
  (command "._ZOOM" "_EXTENTS")

  ;; Step 7: Explode All Blocks in Model Space
  (defun explode-all-blocks ()
    (setq count 5)
    (while (> count 0)
      ;; Select all block references in model space
      (setq ss (ssget "X" '((0 . "INSERT") (410 . "Model"))))
      ;; If there are block references selected
      (if ss
        (progn
          ;; Loop through each block reference
          (repeat (setq blk (sslength ss))
            ;; Get the entity name of the block
            (setq en (ssname ss (setq blk (1- blk))))
            ;; Attempt to explode the block reference
            (if (vl-catch-all-error-p (vl-catch-all-apply 'vl-cmdf (list "_.explode" en)))
              (princ (strcat "\nFailed to explode: " (vl-prin1-to-string en)))
            )
          )
          ;; Decrease the count
          (setq count (1- count))
        )
        ;; If no block references are found, exit the loop
        (setq count 0)
      )
    )
    ;; Inform the user that the process is complete
    (princ "\nBlocks have been exploded up to 5 times.")
  )

  (princ "\nExploding block references...")
  (explode-all-blocks)

  ;; Step 8: Delete all hatch patterns in model space
  (princ "\nDeleting hatch patterns...")
  (setq ss (ssget "X" '((0 . "HATCH") (410 . "Model")))) ; Select only hatch patterns in model space
  (if ss
    (command "._ERASE" ss "")
    (princ "\nNo hatch patterns found.")
  )

  ;; Step 9: Remove all Xrefs
  (princ "\nRemoving all Xrefs...")
  (command "._XREF" "_DETACH" "*" "") ; Detach all Xrefs

  ;; Step 10: Run Audit Command
  (princ "\nRunning audit command...")
  (command "._AUDIT" "Y")

  ;; Step 11: Run Purge Command 3 Times
  (princ "\nRunning purge command...")
  (repeat 3
    (command "._-PURGE" "ALL" "*" "No")
  )

  ;; Step 12: Final Reminder for Saving File
  (alert 
    "The DWG is now optimised for Revit linking!\n- Hide any layers you do not want to see.\n- Detach any X-refs you don't need.\n- Save the tidied file in the required location.\n\nIf you did not want to tidy the file, undo / do not save."
  )
  (princ)
)
