;;; hello-world.el --- A simple hello world package for Emacs -*- lexical-binding: t; -*-

;; Copyright (C) 2025

;; Author: Your Name <your.email@example.com>
;; Version: 0.1.0
;; Package-Requires: ((emacs "24.3"))
;; Keywords: convenience
;; URL: https://github.com/staticaland/emacs-github-actions

;;; Commentary:

;; A simple hello world package that demonstrates basic Emacs Lisp functionality.
;; Provides a command to display "Hello, World!" in the minibuffer.

;;; Code:

;;;###autoload
(defun hello-world ()
  "Display a friendly greeting in the minibuffer."
  (interactive)
  (message "Hello, World! Welcome to Emacs!"))

;;;###autoload
(defun hello-world-insert ()
  "Insert 'Hello, World!' at point."
  (interactive)
  (insert "Hello, World!"))

(provide 'hello-world)

;;; hello-world.el ends here