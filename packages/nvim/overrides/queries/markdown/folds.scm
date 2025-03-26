;; unconditional folding -- ALWAYS consider headers
 ;; foldable
 ([
   (section)
 ] @fold
   (#trim! @fold))


 ;; fold nested lists with at least 3 items
 ([
   (list_item
     (list
       (list_item) (list_item) (list_item) (_)*))
 ] @fold
   (#trim! @fold))

 ;; fold code blocks of 100+ characters
 ([
   (fenced_code_block)
   (indented_code_block)
 ] @fold
   (#trim! @fold)
   (#match? @fold ".{100}"))


 ;; the default folds.scm has this, but I never want to fold lists in the root
 ;; of a section
 ;;(section
 ;;  (list) @fold
 ;;  (#trim! @fold))
