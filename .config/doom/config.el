;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;;; Identity

(setq user-mail-address "hcn518@gmail.com")

;;; Appearance

(setq
  doom-theme 'doom-zenburn
  doom-font (font-spec :family "Monaco Nerd Font Mono" :size 14)
  doom-variable-pitch-font (font-spec :family "DejaVu Sans" :size 14)
  doom-big-font (font-spec :family "Monaco Nerd Font Mono" :size 20)
  doom-symbol-font (font-spec :family "Monaco Nerd Font Mono" :size 14)
  doom-serif-font (font-spec :family "DejaVu Serif" :size 14))

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

(setq display-line-numbers-type t)
(global-display-fill-column-indicator-mode)

;;; Org and notes

(setq org-directory "~/notes/org/")

(after! deft
  (setq
    deft-directory "~/notes/"
    deft-extensions '("txt" "md" "org")
    deft-recursive t))

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

(after! org-roam
  (setq!
    org-roam-dailies-directory "journals/"
    org-roam-capture-templates
    '(("d" "default" plain
       "%?" :target
       (file+head "pages/${slug}.org" "#+title: ${title}\n")
       :unnarrowed t))))

;;; Coding tools

(setq +terraform-runner "tofu")

(after! python
  (set-formatter! 'ruff :modes '(python-mode python-ts-mode)))

(defconst my-homebrew-plantuml-jar
  "/opt/homebrew/opt/plantuml/libexec/plantuml.jar")

(after! plantuml-mode
  (when (file-exists-p my-homebrew-plantuml-jar)
    (setq plantuml-jar-path my-homebrew-plantuml-jar
          plantuml-default-exec-mode 'jar)))

(after! ob-plantuml
  (when (file-exists-p my-homebrew-plantuml-jar)
    (setq org-plantuml-jar-path my-homebrew-plantuml-jar)))

;;; AI integrations

(use-package! claude-code-ide
  :bind ("C-c C-'" . claude-code-ide-menu)
  :config
  (claude-code-ide-emacs-tools-setup))

;;; Window and keybindings

(add-to-list 'initial-frame-alist '(fullscreen . maximized))
(add-to-list 'default-frame-alist '(fullscreen . fullheight))

(global-set-key (kbd "C-.") (kbd "C-SPC"))
(global-set-key (kbd "M-RET") 'dumb-jump-go)
