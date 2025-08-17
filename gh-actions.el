;;; gh-actions.el --- GitHub Actions interface for Emacs -*- lexical-binding: t; -*-

;; Copyright (C) 2025

;; Author: Your Name <your.email@example.com>
;; Version: 0.1.0
;; Package-Requires: ((emacs "26.1") (transient "0.3.0") (request "0.3.0"))
;; Keywords: tools, vc, github, ci
;; URL: https://github.com/staticaland/emacs-github-actions

;;; Commentary:

;; A Magit-style interface for GitHub Actions workflows.
;; Browse workflows, view jobs, manage runs, and interact with GitHub Actions
;; directly from Emacs.

;;; Code:

(require 'transient)
(require 'request)
(require 'json)
(require 'url)

;;; Configuration

(defgroup gh-actions nil
  "GitHub Actions interface for Emacs."
  :group 'tools
  :prefix "gh-actions-")

(defcustom gh-actions-token nil
  "GitHub personal access token for API authentication."
  :type '(choice (const :tag "Use git credential or auth token" nil)
                 (string :tag "Personal access token"))
  :group 'gh-actions)

(defcustom gh-actions-api-base-url "https://api.github.com"
  "Base URL for GitHub API."
  :type 'string
  :group 'gh-actions)

;;; Authentication

(defvar gh-actions--token-cache nil
  "Cached GitHub token.")

(defun gh-actions--get-token ()
  "Get GitHub authentication token."
  (or gh-actions--token-cache
      gh-actions-token
      (setq gh-actions--token-cache
            (or (gh-actions--get-token-from-git-credential)
                (gh-actions--get-token-from-gh-cli)
                (read-passwd "GitHub token: ")))))

(defun gh-actions--get-token-from-git-credential ()
  "Try to get token from git credential helper."
  (when (executable-find "git")
    (with-temp-buffer
      (when (zerop (call-process "git" nil t nil
                                 "credential" "fill"))
        (goto-char (point-min))
        (when (re-search-forward "^password=\\(.+\\)$" nil t)
          (match-string 1))))))

(defun gh-actions--get-token-from-gh-cli ()
  "Try to get token from GitHub CLI."
  (when (executable-find "gh")
    (with-temp-buffer
      (when (zerop (call-process "gh" nil t nil "auth" "token"))
        (string-trim (buffer-string))))))

(defun gh-actions--get-repo-info ()
  "Get current repository owner and name."
  (when (executable-find "git")
    (let ((remote-url (with-temp-buffer
                        (when (zerop (call-process "git" nil t nil
                                                   "remote" "get-url" "origin"))
                          (string-trim (buffer-string))))))
      (when remote-url
        (when (string-match "github\\.com[:/]\\([^/]+\\)/\\([^/]+?\\)\\(?:\\.git\\)?$" remote-url)
          (cons (match-string 1 remote-url)
                (match-string 2 remote-url)))))))

;;; API Client

(defvar gh-actions--rate-limit-remaining nil
  "Remaining GitHub API rate limit.")

(defvar gh-actions--rate-limit-reset nil
  "GitHub API rate limit reset time.")

(defun gh-actions--check-rate-limit ()
  "Check if we're approaching rate limits."
  (when (and gh-actions--rate-limit-remaining
             (< gh-actions--rate-limit-remaining 10))
    (message "Warning: GitHub API rate limit low (%d remaining)" 
             gh-actions--rate-limit-remaining)))

(defun gh-actions--api-request (method endpoint &optional data)
  "Make a GitHub API request with error handling and rate limiting."
  (gh-actions--check-rate-limit)
  (let* ((url (concat gh-actions-api-base-url endpoint))
         (token (gh-actions--get-token))
         (headers `(("Authorization" . ,(format "token %s" token))
                   ("Accept" . "application/vnd.github.v3+json")
                   ("User-Agent" . "emacs-gh-actions")))
         (response-data nil)
         (response-error nil))
    (request url
      :type method
      :headers headers
      :data (when data (json-encode data))
      :parser 'json-read
      :sync t
      :success (cl-function
                (lambda (&key data response &allow-other-keys)
                  (setq response-data data)
                  (let ((headers (request-response-headers response)))
                    (when-let ((remaining (cdr (assoc "x-ratelimit-remaining" headers))))
                      (setq gh-actions--rate-limit-remaining (string-to-number remaining)))
                    (when-let ((reset (cdr (assoc "x-ratelimit-reset" headers))))
                      (setq gh-actions--rate-limit-reset (string-to-number reset))))))
      :error (cl-function
              (lambda (&key error-thrown response &allow-other-keys)
                (let ((status-code (when response (request-response-status-code response))))
                  (setq response-error
                        (cond
                         ((eq status-code 401) "GitHub API: Authentication failed. Check your token.")
                         ((eq status-code 403) "GitHub API: Forbidden. Check permissions or rate limits.")
                         ((eq status-code 404) "GitHub API: Resource not found.")
                         ((eq status-code 422) "GitHub API: Validation failed.")
                         (t (format "GitHub API request failed: %s" error-thrown))))))))
    (if response-error
        (error response-error)
      response-data)))

(defun gh-actions--get-workflows (owner repo)
  "Get workflows for a repository."
  (let ((response (gh-actions--api-request "GET" 
                                          (format "/repos/%s/%s/actions/workflows" owner repo))))
    (when response
      (alist-get 'workflows response))))

(defun gh-actions--get-workflow-runs (owner repo workflow-id)
  "Get runs for a specific workflow."
  (let ((response (gh-actions--api-request "GET"
                                          (format "/repos/%s/%s/actions/workflows/%s/runs" 
                                                  owner repo workflow-id))))
    (when response
      (alist-get 'workflow_runs response))))

;;; Buffer Management

(defvar gh-actions--current-owner nil
  "Current repository owner.")

(defvar gh-actions--current-repo nil
  "Current repository name.")

(defconst gh-actions-buffer-name "*GitHub Actions*"
  "Name of the GitHub Actions buffer.")

(defun gh-actions--get-buffer ()
  "Get or create the GitHub Actions buffer."
  (get-buffer-create gh-actions-buffer-name))

(defun gh-actions--refresh-buffer ()
  "Refresh the current buffer content."
  (when (and gh-actions--current-owner gh-actions--current-repo)
    (gh-actions--show-workflows gh-actions--current-owner gh-actions--current-repo)))

;;; Workflow Display

(defun gh-actions--format-workflow (workflow)
  "Format a workflow for display."
  (let* ((name (alist-get 'name workflow))
         (state (alist-get 'state workflow))
         (path (alist-get 'path workflow))
         (badge (cond
                 ((string= state "active") "●")
                 ((string= state "disabled") "○")
                 (t "?"))))
    (format "%s %s (%s)" badge name path)))

(defun gh-actions--show-workflows (owner repo)
  "Show workflows for the given repository."
  (setq gh-actions--current-owner owner
        gh-actions--current-repo repo)
  (let ((buffer (gh-actions--get-buffer))
        (workflows (condition-case err
                       (gh-actions--get-workflows owner repo)
                     (error
                      (message "Failed to fetch workflows: %s" (error-message-string err))
                      nil))))
    (with-current-buffer buffer
      (let ((inhibit-read-only t))
        (erase-buffer)
        (insert (format "GitHub Actions - %s/%s\n\n" owner repo))
        (if workflows
            (progn
              (insert "Workflows:\n")
              (dolist (workflow workflows)
                (insert (gh-actions--format-workflow workflow))
                (insert "\n")))
          (insert "No workflows found or failed to fetch workflows.\n"))
        (insert "\nPress 'r' to refresh, 'q' to quit\n"))
      (gh-actions-mode)
      (goto-char (point-min)))
    (pop-to-buffer buffer)))

;;; Major Mode

(defvar gh-actions-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "r") 'gh-actions--refresh-buffer)
    (define-key map (kbd "q") 'quit-window)
    (define-key map (kbd "g") 'gh-actions--refresh-buffer)
    map)
  "Keymap for `gh-actions-mode'.")

(define-derived-mode gh-actions-mode special-mode "GitHub Actions"
  "Major mode for GitHub Actions interface."
  :group 'gh-actions
  (setq buffer-read-only t)
  (setq truncate-lines t))

;;; Entry point

;;;###autoload
(defun gh-actions ()
  "Open GitHub Actions interface."
  (interactive)
  (let ((repo-info (gh-actions--get-repo-info)))
    (if repo-info
        (gh-actions--show-workflows (car repo-info) (cdr repo-info))
      (message "Not in a GitHub repository or unable to determine repository info"))))

(provide 'gh-actions)

;;; gh-actions.el ends here