;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
;; (setq user-full-name "John Doe"
;;       user-mail-address "john@doe.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-unicode-font' -- for unicode glyphs
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
;;(setq doom-font (font-spec :family "Fira Code" :size 12 :weight 'semi-light)
;;      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq
  doom-theme 'doom-zenburn
  doom-font (font-spec :family "Monaco" :size 14)
  doom-variable-pitch-font (font-spec :family "DejaVu Sans" :size 14)
  doom-big-font (font-spec :family "Monaco" :size 20)
  doom-symbol-font (font-spec :family "MesloLGS Nerd Font" :size 14)
  doom-serif-font (font-spec :family "DejaVu Serif" :size 14))

;; Change the doom dashboard banner
(defun doom-dashboard-draw-ascii-emacs-banner-fn ()
  (let* ((banner
          '("                 ######      ###        "
            "                   #####      ####      "
            "  ######             ####      ##       "
            "    #####             ###########       "
            "    ########## ###  ############        "
            "  ############ ############             "
            "#######         ####    ###             "
            "       ######   ####     ###  ###       "
            "   #######      ############  ####      "
            "     ### ####   #################       "
            "    ########    ####   ###  ####        "
            "    ####   ##   ####   ###  ####     #  "
            "     #  ####### #### ##### ######   ##  "
            "   ####### #### ###  #######   ### #### "
            "  ######   ### ##               ####### "
            "   ###########                   ###### "
            "    #####                          #####"))
         (longest-line (apply #'max (mapcar #'length banner))))
    (put-text-property
     (point)
     (dolist (line banner (point))
       (insert (+doom-dashboard--center
                +doom-dashboard--width
                (concat
                 line (make-string (max 0 (- longest-line (length line)))
                                   32)))
               "\n"))
     'face 'doom-dashboard-banner)))
(setq +doom-dashboard-ascii-banner-fn #'doom-dashboard-draw-ascii-emacs-banner-fn)

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/notes/org/")

;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `after!' block, otherwise Doom's defaults may override your settings. E.g.
;;
;;   (after! PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look up their documentation).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.

;; deft settings
(after! deft
  (setq
    deft-directory "~/notes/"
    deft-extensions '("txt" "md" "org")
    deft-recursive t))

;; minimap settings
(minimap-mode 1)

;; org mode settings
(defun my-org-faces ()
  (if writeroom-mode
    (progn
      (set-face-attribute 'org-document-title nil :height 2.0)
      (set-face-attribute 'org-level-1 nil :height 1.75)
      (set-face-attribute 'org-level-2 nil :height 1.5)
      (set-face-attribute 'org-level-3 nil :height 1.25)
      (set-face-attribute 'org-level-4 nil :height 1.1))
    (progn
      (set-face-attribute 'org-document-title nil :height 1.0)
      (set-face-attribute 'org-level-1 nil :height 1.0)
      (set-face-attribute 'org-level-2 nil :height 1.0)
      (set-face-attribute 'org-level-3 nil :height 1.0)
      (set-face-attribute 'org-level-4 nil :height 1.0))))
(add-hook 'writeroom-mode-hook #'my-org-faces)

;; org-roam settings
(after! org-roam
  (setq!
    org-roam-dailies-directory "journals/"
    org-roam-capture-templates
    '(("d" "default" plain
       "%?" :target
       (file+head "pages/${slug}.org" "#+title: ${title}\n")
       :unnarrowed t))))

;; codeium settings
(defun my/codeium-enable()
  "Enable codeium"
  (interactive)
  (add-to-list 'completion-at-point-functions #'codeium-completion-at-point))

(use-package! codeium
  :hook ((prog-mode eglot-managed-mode) . my/codeium-enable)
  :config
  (setq codeium-api-enabled
        (lambda (api)
          (memq api '(GetCompletions Heartbeat CancelRequest GetAuthToken RegisterUser auth-redirect AcceptCompletion))))
  (defun my-codeium/document/text ()
    (buffer-substring-no-properties (max (- (point) 3000) (point-min)) (min (+ (point) 1000) (point-max))))
  (defun my-codeium/document/cursor_offset ()
    (codeium-utf8-byte-length
     (buffer-substring-no-properties (max (- (point) 3000) (point-min)) (point))))
  (setq codeium/document/text 'my-codeium/document/text)
  (setq codeium/document/cursor_offset 'my-codeium/document/cursor_offset))

;; circe settings
(after! circe
  (set-irc-server! "chat.freenode.net"
    `(:tls t
      :port 6697
      :nick "pedh"
      :sasl-username ,(+pass-get-user   "irc/freenode")
      :sasl-password (lambda (&rest _) (+pass-get-secret "irc/freenode"))
      :channels ("#emacs" "#linux" "#python"))))

;; other settings
;; 1. create a maximized initial frame
;; 2. create fullheight (but not fullwidth) frames on every subsequent frame
(add-to-list 'initial-frame-alist '(fullscreen . maximized))
(add-to-list 'default-frame-alist '(fullscreen . fullheight))

;; replace c-spc with c-., since c-spc is already binding to switching input
;; source under macos.
(global-set-key (kbd "C-.") (kbd "C-SPC"))

;; use dump jump to jump to definition, as the complement of lsp.
(global-set-key (kbd "M-RET") 'dumb-jump-go)

;; enable global display fill column indicator mode, to display the fill column
;; indicator.
(global-display-fill-column-indicator-mode)

;; enable native pixel line scrolling.
(when (fboundp 'pixel-scroll-precision-mode)
  (progn
    (setq pixel-scroll-precision-interpolate-page t)
    (setq pixel-scroll-precision-large-scroll-height 40.0)
    (setq pixel-scroll-precision-interpolation-factor 30.0)
    (pixel-scroll-precision-mode t)))

;; set user identification.
(setq user-mail-address "hcn518@gmail.com")
