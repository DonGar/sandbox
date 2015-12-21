
;; Saves the emacs desktop on a per-sandbox bases.

;; Enter M-x desktop (with directory ~), to save a desktop the first time.
;; automatic after that.

(setq desktop-dirname "~"
      desktop-base-file-name (concat ".emacs.desktop." (getenv "SANDBOX"))
      desktop-base-lock-name (concat desktop-base-file-name ".lock")
      desktop-load-locked-desktop nil
      desktop-save 'if-exists)
(desktop-save-mode 1)
