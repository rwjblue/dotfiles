;; unconditional folding -- ALWAYS consider headers
;; foldable
([
  (section)
] @fold
  (#trim! @fold))

;; folding only if the content is "long enough"
([
  (fenced_code_block)
  (indented_code_block)
  (list_item
    (list))
] @fold
  (#trim! @fold))


;; the default folds.scm has this, but I never want to fold lists in the root
;; of a section
;;(section
;;  (list) @fold
;;  (#trim! @fold))


