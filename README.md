# Hello World Emacs Package

A simple "Hello, World!" package for Emacs that demonstrates basic package structure and functionality.

## Features

- `hello-world`: Display a greeting message in the minibuffer
- `hello-world-insert`: Insert "Hello, World!" at the current cursor position

## Installation

### Doom Emacs

Add the following to your `packages.el` file:

```elisp
(package! hello-world
  :recipe (:host github :repo "staticaland/emacs-github-actions"))
```

Then add this to your `config.el`:

```elisp
(use-package! hello-world
  :commands (hello-world hello-world-insert))
```

After adding these configurations:

1. Run `doom sync` to install the package
2. Restart Emacs or run `doom/reload`

### Manual Installation

1. Clone this repository:

   ```bash
   git clone https://github.com/staticaland/emacs-github-actions.git
   ```

2. Add the directory to your load path in your Emacs configuration:
   ```elisp
   (add-to-list 'load-path "/path/to/emacs-github-actions")
   (require 'hello-world)
   ```

## Usage

Once installed, you can use the following commands:

- `M-x hello-world` - Displays "Hello, World! Welcome to Emacs!" in the minibuffer
- `M-x hello-world-insert` - Inserts "Hello, World!" at the current cursor position

### Key Bindings (Optional)

You can add custom key bindings in your configuration:

```elisp
(global-set-key (kbd "C-c h w") 'hello-world)
(global-set-key (kbd "C-c h i") 'hello-world-insert)
```

## Development

This package serves as a simple example of Emacs package structure. The main file `hello-world.el` includes:

- Proper package headers with metadata
- Autoload cookies for functions
- Interactive commands
- Documentation strings

## License

This project is in the public domain.
