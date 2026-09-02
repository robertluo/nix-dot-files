;;; packages.el -*- lexical-binding: t; -*-

;; Extra packages beyond what the modules in init.el pull in.
;; Unstraightened resolves these at build time from Doom's pins, so any
;; change here needs `apply`, not `doom sync`.
;;
;;   (package! some-package)
;;   (package! another :recipe (:host github :repo "user/repo"))
;;   (unpin! pinned-package)
