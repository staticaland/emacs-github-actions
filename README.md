# GitHub Actions for Emacs

A Magit-style interface for GitHub Actions workflows in Emacs. Browse workflows, view jobs, manage runs, and interact with GitHub Actions directly from your editor.

## Features

### Current (MVP)

- Browse GitHub Actions workflows for the current repository
- Basic workflow listing with status indicators
- Authentication via GitHub CLI, git credential helper, or personal access token
- Simple refresh and navigation interface

### Planned

- View workflow runs and job details
- Real-time status updates for running workflows
- Re-run failed workflows and jobs
- Transient command interface (Magit-style)
- Log viewing with syntax highlighting
- Workflow triggering and cancellation

## Installation

### Doom Emacs

Add the following to your `packages.el` file:

```elisp
(package! gh-actions
  :recipe (:host github :repo "staticaland/emacs-github-actions"))
```

Then add this to your `config.el`:

````elisp
(use-package! gh-actions
  :commands (gh-actions)
  :config
  ;; Optional: Set your GitHub token (alternatively use gh CLI or git credential helper)
  ;; (setq gh-actions-token "your_personal_access_token_here")
  )

After adding these configurations:

1. Run `doom sync` to install the package
2. Restart Emacs or run `doom/reload`

### Manual Installation

1. Clone this repository:

   ```bash
   git clone https://github.com/staticaland/emacs-github-actions.git
````

2. Add the directory to your load path in your Emacs configuration:
   ```elisp
   (add-to-list 'load-path "/path/to/emacs-github-actions")
   (require 'gh-actions)
   ```

## Usage

### Authentication

The package supports three authentication methods (tried in order):

1. **GitHub CLI**: If you have `gh` CLI installed and authenticated
2. **Git credential helper**: Uses your git credentials for GitHub
3. **Personal Access Token**: Set `gh-actions-token` variable or enter when prompted

For the token method, create a [Personal Access Token](https://github.com/settings/tokens) with `repo` and `actions:read` scopes.

### Commands

- `M-x gh-actions` - Open the GitHub Actions interface for the current repository

### Key Bindings

In the GitHub Actions buffer:

- `r` or `g` - Refresh workflows
- `q` - Quit and close buffer

### Key Bindings (Optional)

You can add a global key binding:

```elisp
(global-set-key (kbd "C-c g a") 'gh-actions)
```

## Development Roadmap

This package is under active development. The current implementation provides:

- GitHub API integration with proper authentication
- Basic workflow listing and display
- Error handling and rate limiting
- Extensible buffer management system

### Upcoming Features (in order of priority):

1. **Workflow runs view** - See runs for each workflow with status and timing
2. **Job details** - Drill down into individual jobs and steps
3. **Transient interface** - Magit-style command menus
4. **Log viewing** - View job logs with syntax highlighting
5. **Workflow control** - Re-run, cancel, and trigger workflows
6. **Real-time updates** - Auto-refresh for running workflows

## License

This project is in the public domain.
