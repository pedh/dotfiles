;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

(setq
  doom-theme 'doom-zenburn
  doom-font (font-spec :family "Monaco Nerd Font Mono" :size 14)
  doom-variable-pitch-font (font-spec :family "DejaVu Sans" :size 14)
  doom-big-font (font-spec :family "Monaco Nerd Font Mono" :size 20)
  doom-symbol-font (font-spec :family "Monaco Nerd Font Mono" :size 14)
  doom-serif-font (font-spec :family "DejaVu Serif" :size 14))

;; Change the dashboard banner
(defun my-dashboard-ascii-banner-fn ()
  (propertize
   (string-join
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
      "    #####                          #####")
    "\n")
   'face '+dashboard-banner))
(setq +dashboard-ascii-banner-fn #'my-dashboard-ascii-banner-fn)

;; Line numbers
(setq display-line-numbers-type t)

;; Org directory
(setq org-directory "~/notes/org/")

;; deft settings
(after! deft
  (setq
    deft-directory "~/notes/"
    deft-extensions '("txt" "md" "org")
    deft-recursive t))

;; org mode heading sizes in writeroom-mode
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

;; claude code settings
(use-package! claude-code-ide
  :bind ("C-c C-'" . claude-code-ide-menu)
  :config
  (claude-code-ide-emacs-tools-setup))

;; Frame sizing: maximized on launch, fullheight on subsequent frames
(add-to-list 'initial-frame-alist '(fullscreen . maximized))
(add-to-list 'default-frame-alist '(fullscreen . fullheight))

;; C-. as mark (C-SPC is taken by macOS input source switching)
(global-set-key (kbd "C-.") (kbd "C-SPC"))

;; M-RET for dumb-jump (complement to LSP go-to-definition)
(global-set-key (kbd "M-RET") 'dumb-jump-go)

;; Show fill column indicator
(global-display-fill-column-indicator-mode)

;; User identification
(setq user-mail-address "hcn518@gmail.com")
