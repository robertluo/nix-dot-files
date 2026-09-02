;;; init.el -*- lexical-binding: t; -*-

;; Module list for Doom, built by nix-doom-emacs-unstraightened.
;; This file is read at BUILD time: adding a module here means a rebuild
;; (`apply`), not a restart. Run `doom sync` never — Nix owns that step.

(doom! :completion
       vertico            ; the search engine of the future

       :ui
       doom               ; what makes DOOM look the way it does
       dashboard          ; a nifty splash screen for Emacs
       hl-todo            ; highlight TODO/FIXME/NOTE/DEPRECATED/HACK/REVIEW
       modeline           ; snazzy, Atom-inspired modeline, plus API
       nav-flash          ; blink cursor line after big motions
       ophints            ; highlight the region an operation acts on
       (popup +defaults)  ; tame sudden yet inevitable temporary windows
       vc-gutter          ; vcs diff in the fringe
       window-select      ; visually switch windows

       :editor
       (evil +everywhere) ; come to the dark side, we have cookies
       fold               ; (nigh) universal code folding
       snippets           ; my elves. They type so I don't have to

       :emacs
       dired              ; making dired pretty [functional]
       undo               ; persistent, smarter undo
       vc                 ; version-control and Emacs, sitting in a tree

       :term
       eshell             ; the elisp shell that works everywhere

       :checkers
       syntax             ; tasing you for every semicolon you forget

       :tools
       (eval +overlay)    ; run code, run (also, repls)
       lookup             ; navigate your code and its documentation
       (lsp +eglot)       ; M-x vscode
       magit              ; a git porcelain for Emacs

       :os
       (:if (featurep :system 'macos) macos)  ; improve compatibility with macOS

       :lang
       (clojure +lsp)     ; java with a lisp
       emacs-lisp         ; drown in parentheses
       markdown           ; writing docs for people to ignore
       (nix +lsp)         ; I hereby declare "nix geht mehr!"
       org                ; organize your plain life in plain text
       sh                 ; she sells {ba,z,fi}sh shells on the C xor

       :config
       (default +bindings +smartparens))
