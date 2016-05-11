;;; fluentd-mode.el --- Major mode for fluentd configuration file -*- lexical-binding: t; -*-

;; Copyright (C) 2016 by Syohei YOSHIDA

;; Author: Syohei YOSHIDA <syohex@gmail.com>
;; URL: https://github.com/syohex/emacs-fluentd-mode
;; Version: 0.01
;; Package-Requires: ((emacs "24") (cl-lib "0.5"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Major mode for fluentd configuration file

;;; Code:

(require 'cl-lib)

(defgroup fluentd nil
  "Major mode for fluentd configuration file."
  :group 'languages)

(defcustom fluentd-indent-level 2
  "Indent level."
  :type 'integer)

(defconst fluentd--tag-regexp
  "^\\s-*\\(</?[^ \t\r\n>]+\\)\\(?:\\s-+\\([^>]+\\)\\)?\\(>\\)")

(defconst fluentd--parameter-regexp
  "\\([[:word:]_]+\\)\\s-+\\(.+\\)$")

(defface fluentd-tag
  '((t (:inherit font-lock-keyword-face)))
  "Face of TAG")

(defface fluentd-tag-parameter
  '((t (:inherit font-lock-type-face)))
  "Face of tag parameter")

(defface fluentd-parameter-name
  '((t (:inherit font-lock-variable-name-face)))
  "Face of parameter name")

(defface fluentd-parameter-value
  '((t (:inherit font-lock-constant-face)))
  "Face of parameter value")

(defvar fluentd-font-lock-keywords
  `((,fluentd--tag-regexp (1 'fluentd-tag)
                          (2 'fluentd-tag-parameter nil t)
                          (3 'fluentd-tag nil t))
    (,fluentd--parameter-regexp (1 'fluentd-parameter-name)
                                (2 'fluentd-parameter-value))))

(defun fluentd--open-tag-line-p ()
  (save-excursion
    (back-to-indentation)
    (looking-at-p "<[^/][^ \t\r\n>]*")))

(defun fluentd--close-tag-line-p ()
  (save-excursion
    (back-to-indentation)
    (looking-at-p "</[^>]+>")))

(defun fluentd--retrieve-close-tag-name ()
  (save-excursion
    (back-to-indentation)
    (looking-at "</\\([^>]+\\)>")
    (match-string-no-properties 1)))

(defun fluentd--already-closed-p (tagname curpoint)
  (save-excursion
    (let ((close-tag (format "</%s>" tagname))
          (curline (line-number-at-pos curpoint)))
      (when (search-forward close-tag curpoint t)
        (< (line-number-at-pos) curline)))))

(defun fluentd--search-open-tag-indentation ()
  (save-excursion
    (let ((open-tag "<\\([^/][^ \t\r\n>]+\\)\\(?:\\s-+\\([^>]+\\)\\)?\\(>\\)")
          (curpoint (point)))
      (cond ((fluentd--close-tag-line-p)
             (let* ((tagname (fluentd--retrieve-close-tag-name))
                    (open-tag1 (format "^\\s-*<%s\\(?:\\s-\\|>\\)" tagname)))
               (if (not (re-search-backward open-tag1 nil t))
                   (error "open-tag not found")
                 (current-indentation))))
            (t
             (let (finish)
               (while (and (not finish) (re-search-backward open-tag nil t))
                 (let ((tagname (match-string-no-properties 1)))
                   (unless (fluentd--already-closed-p tagname curpoint)
                     (setq finish t))))
               (if (not finish)
                   0
                 (+ (current-indentation) fluentd-indent-level))))))))

(defun fluentd--search-close-tag ()
  (let ((close-tag "</\\([^/]+\\)>")
        (cur-line-end (line-end-position)))
    (save-excursion
      (if (re-search-forward open-tag nil t)
          (let ((open-tag (concat "<" (match-string-no-properties 1) 2)))
            (match-string-no-properties 1))
        (let* ((indentation (current-indentation))
               (tagname (match-string-no-properties 1))
               (close-tag (format "</%s>" tagname)))
          (if (re-search-forward close-tag cur-line-end t)
              indentation
            (+ indentation fluentd-indent-level)))))))

(defun fluentd-indent-line ()
  "Indent current line as fluentd configuration."
  (interactive)
  (let ((indent-size (fluentd--search-open-tag-indentation)))
    (back-to-indentation)
    (when (/= (current-indentation) indent-size)
      (save-excursion
        (delete-region (line-beginning-position) (point))
        (indent-to indent-size)))
    (when (< (current-column) (current-indentation))
      (back-to-indentation))))

(defvar fluentd-mode-syntax-table
  (let ((table (make-syntax-table)))
    (modify-syntax-entry ?#  "< b" table)
    (modify-syntax-entry ?\n "> b" table)
    (modify-syntax-entry ?<  "(>"  table)
    (modify-syntax-entry ?>  ")<"  table)
    table))

;;;###autoload
(define-derived-mode fluentd-mode fundamental-mode "Fluentd"
  "Major mode for editing fluentd configuration file."
  (setq font-lock-defaults '((fluentd-font-lock-keywords)))

  ;; indentation
  (make-local-variable 'fluentd-indent-level)
  (set (make-local-variable 'indent-line-function) 'fluentd-indent-line)

  (set (make-local-variable 'comment-start) "#"))

;;;###autoload
(add-to-list 'auto-mode-alist '("fluentd?.conf\\'" . fluentd-mode))

(provide 'fluentd-mode)

;;; fluentd-mode.el ends here
