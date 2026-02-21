;; extends

;; Highlight custom region markers like // region and // endregion
(
 (comment) @region.marker
  (#match? @region.marker "region")
)

(
 (comment) @region.marker
  (#match? @region.marker "endregion")
)
