;***********************************************************
;**                                                       **
;** Purpose: This routine allows the user to explode all   **
;**          blocks in the current drawing, including      **
;**          those that are not set as explodable.         **
;**                                                       **
;** Usage: Type "expl-p" to run the routine.               **
;**                                                       **
;***********************************************************

(defun c:expl-p ()
  ; Load the ActiveX Automation Library to work with VLA objects
  (vl-load-com)

  ; Get the active document
  (setq doc (vla-get-ActiveDocument (vlax-get-acad-object)))

  ; Loop through all the blocks in the current drawing
  (vlax-for block (vla-get-Blocks doc)
    ; Set the block as explodable if it is not already
    (if (not (vla-get-explodable block))
      (vla-put-explodable block :vlax-true)
    )
  )

  ; Function to explode blocks in a given space
  (defun explode-blocks-in-space (space)
    (vlax-for obj space
      (if (eq (vla-get-ObjectName obj) "AcDbBlockReference")
        (progn
          ; Explode the block reference
          (vl-cmdf "_.explode" (vlax-vla-object->ename obj))
        )
      )
    )
  )

  ; Explode blocks in model space
  (explode-blocks-in-space (vla-get-ModelSpace doc))

  ; Explode blocks in each paper space layout
  (vlax-for layout (vla-get-Layouts doc)
    (explode-blocks-in-space (vla-get-Block layout))
  )

  ; Return control to the command line
  (princ)
)
