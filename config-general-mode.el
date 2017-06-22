;;; config-general-mode.el --- Config::General config file mode

;; Copyright (C) 2016-2017, T.v.Dein <tlinden@cpan.org>

;; This file is NOT part of Emacs.

;; This  program is  free  software; you  can  redistribute it  and/or
;; modify it  under the  terms of  the GNU  General Public  License as
;; published by the Free Software  Foundation; either version 2 of the
;; License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT  ANY  WARRANTY;  without   even  the  implied  warranty  of
;; MERCHANTABILITY or FITNESS  FOR A PARTICULAR PURPOSE.   See the GNU
;; General Public License for more details.

;; You should have  received a copy of the GNU  General Public License
;; along  with  this program;  if  not,  write  to the  Free  Software
;; Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
;; USA

;; Version: 0.01
;; Author: T.v.Dein <tlinden@cpan.org>
;; Keywords: config
;; URL: https://github.com/tlinden/config-general-mode
;; License: GNU General Public License >= 2

;;; Commentary:

;;(add-hook 'cg-mode-hook 'electric-indent-mode)

;;; Install:
;;; Customize:

;;; Code:

;;;; Dependencies

(require 'sh-script)
(require 'cc-mode)

;;;; Customizables

;; our group
(defgroup config-general nil
  "Config::General config file mode."
  :prefix "config-general-"
  :group 'conf)

(defgroup config-general-faces nil
  "Config::General config file mode faces."
  :prefix "config-general-"
  :group 'faces)

;; vars
(defcustom config-general-electric-return t
  "Enable electric return and follow include files."
  :group 'config-general
  :type 'boolean)

;; faces
(defface config-general-file-face
   '((t (:inherit link)))
  "face for include files"
  :group 'config-general-faces)

(defface config-general-constant-face
  '((t (:inherit font-lock-constant-face)))
  "face for include files"
  :group 'config-general-faces)

(defface config-general-special-char-face
  '((t (:inherit font-lock-regexp-grouping-backslash)))
  "face for special characters like < or |"
  :group 'config-general-faces)

(defface config-general-keyword-face
  '((t (:inherit font-lock-keyword-face))) ;; maybe type?
  "face for special keywords like include"
  :group 'config-general-faces)

(defface config-general-blockname-face
  '((t (:inherit font-lock-function-name-face)))
  "face for block names"
  :group 'config-general-faces)

(defface config-general-variable-name-face
  '((t (:inherit font-lock-variable-name-face)))
  "face for variable name definitions"
  :group 'config-general-faces)

(defface config-general-interpolating-variable-face
  '((t (:inherit font-lock-constant-face)))
  "face for variable name definitions"
  :group 'config-general-faces)

(defface config-general-escape-char-face
  '((t (:inherit font-lock-warning-face)))
  "face for escape chars"
  :group 'config-general-faces)


;;;; Global Vars
(defconst config-general-mode-version "0.01" "Config::General mode version")

(defvar config-general-font-lock-keywords nil
  "Keywords to highlight in CG mode.")

(defvar config-general-mode-abbrev-table nil)

(defvar config-general-imenu-expression
  '(
    ("Blocks"  "^ *<\\([a-zA-Z0-9]+.*\\)>" 1 ))
  "Imenu generic expression for Config:General mode.  See `imenu-generic-expression'.")

;;;; Public Functions

(defun config-general-reload()
  (interactive)
  (fundamental-mode)
  (config-general-mode))

(defun config-general-align-vars (beg end)
  (interactive "r")
  (align-regexp beg end "\\(\\s-*\\)=" 1 1 nil))

(defun config-general-do-electric-return ()
  (interactive)
  (if (eq config-general-electric-return t)
      (if (eq (get-text-property (point)'face) 'config-general-file-face)
          (find-file-at-point)
        (config-general-open-line-below))
    (newline)))

(defun config-general-open-line-below ()
  (interactive)
  (end-of-line)
  (newline-and-indent))


;;;; Internal Functions

(defun config-general--fl-beg-eof (limit)
  (re-search-forward "<<\\([A-Z0-9]+\\)\n" limit t))

(defun config-general--fl-end-eof (limit)
  (re-search-forward "^\\([A-Z0-9]+\\)\n" limit t))

(defun config-general--init-syntax ()
  ;; we need our own syntax table for mixed C++ and Shell comment support
  (set-syntax-table
        (let ((st (make-syntax-table)))
          (modify-syntax-entry ?\/ ". 14n" st)
          (modify-syntax-entry ?\* ". 23n" st)
          (modify-syntax-entry ?# "<" st)
          (modify-syntax-entry ?\n ">" st)
          (modify-syntax-entry ?\\ "\\" st)
          (modify-syntax-entry ?$ "'" st)
          (modify-syntax-entry ?\' "\"\"") ;; make ' electric too
          (modify-syntax-entry ?< ".")
          (modify-syntax-entry ?> ".")
          st)))

(defun config-general--init-font-lock ()
    ;; better suited to configs
  (setq config-general-font-lock-keywords
        '(
          ;; <>
          ("\\([<>|]+\\)" 1 'config-general-special-char-face)
          
          ;; <<include ...>>
          ("^[ \t]*<<\\(include\\) [ \t]*\\(.+?\\)>>*"
           (1 'config-general-constant-face)
           (2 'config-general-file-face)) ;; FIXME: turn into real link property!

          ;; include ...
          ("^[ \t]*\\(include\\) [ \t]*\\(.*\\)"
           (1 'config-general-constant-face)
           (2 'config-general-file-face))
          
          ;; <block ..>
          ("^\s*</*\\(.+\\)>" 1 'config-general-blockname-face)

          ;; variable definitions
          ;; FIXME: add support for -SplitPolicy and -SplitDelimiter and make
          ;; the = a customizable variable, if possible
          ("^[ \t]*\\(.+?\\)[ \t]*="
           (1 'config-general-variable-name-face))
          
          ;; interpolating variables
          ("\\$\\({#?\\)?\\([[:alpha:]_][[:alnum:]_]*\\|[-#?@!]\\)"
           (2 'config-general-interpolating-variable-face))

          ;; escape char
          ("\\(\\\\\\)" (1 'config-general-escape-char-face))

          ))
        
  (set (make-local-variable 'font-lock-defaults)
       '(config-general-font-lock-keywords nil t nil nil))

  (font-lock-add-keywords nil
                          '((config-general--fl-beg-eof . 'config-general-constant-face)
                            (config-general--fl-end-eof . 'config-general-constant-face))))

(defun config-general--init-minors ()
  ;; enable simple outlining
  (setq outline-heading-alist '(("##" . 1)
                                ("###" . 2)
                                ("####" . 3)
                                ("#####" . 4)))
  (outline-minor-mode t)
  ;; from shell-script-mode, turn << into here-doc
  (sh-electric-here-document-mode 1)
  ;; Inserting a brace or quote automatically inserts the matching pair
  (electric-pair-mode t))

;;;###autoload
(defvar config-general-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c C-7") 'sh-backslash-region) ;; for latin keyboards 
    (define-key map (kbd "C-c C-/") 'sh-backslash-region)
    (define-key map (kbd "C-c C-0") 'config-general-align-vars) ;; for latin keyboards
    (define-key map (kbd "C-c C-=") 'config-general-align-vars)
    (define-key map (kbd "C-c C-f") 'find-file-at-point) ;; FIXME: change to [follow-link]
    (define-key map (kbd "<C-return>")   'config-general-do-electric-return)
    (define-key map [remap delete-backward-char] 'backward-delete-char-untabify)
    map)
  "Keymap used in Config::General mode."
  )

;;;###autoload
(define-derived-mode config-general-mode conf-mode "config-general"
  "Config::General config file mode.
\\{config-general-mode-map}"

  ;; prepare clean startup
  (kill-all-local-variables)

  ;; support for 'comment-region et al
  (setq-local comment-start "# ")
  (setq-local comment-end "")

  ;; we don't need a complicated indent strategy, relative is totally ok
  (setq-local indent-line-function #'indent-relative)

  ;; initialize mode
  (config-general--init-font-lock)
  (config-general--init-minors)
  (config-general--init-syntax)
  
  ;; load keymap
  (use-local-map config-general-mode-map)

  ;; de-activate some (for C::G) senseless bindings
  (local-unset-key (kbd "C-c C-c"))
  (local-unset-key (kbd "C-c C-j"))
  (local-unset-key (kbd "C-c C-p"))
  (local-unset-key (kbd "C-c C-u"))
  (local-unset-key (kbd "C-c C-w"))
  (local-unset-key (kbd "C-c C-x"))
  (local-unset-key (kbd "C-c :"))

  ;; imenu
  (make-local-variable 'imenu-generic-expression)
  (setq imenu-generic-expression config-general-imenu-expression)
  (setq imenu-case-fold-search nil)
  (require 'imenu)

  ;; make us known correctly
  (setq major-mode 'config-general-mode)
  (setq mode-name "C::G")

  ;; eval hooks, if any
  (run-mode-hooks 'config-general-mode-hooks))



;; done
(provide 'config-general-mode)

;;; config-general-mode.el ends here
