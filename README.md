# .dotfiles


# Dotfiles - My Dev Environment Setup  

![Dotfiles](https://img.shields.io/badge/Dotfiles-Automated-blue?style=flat-square&logo=linux) ![Stow](https://img.shields.io/badge/Managed%20with-Stow-green?style=flat-square)

Fast and versatile setup!!!
Welcome to my dotfiles repository! This setup manages my development environment efficiently using **GNU Stow**, allowing for modular and clean configuration management. 🚀

---

## 📂 Structure
Each directory inside `.dotfiles/` represents a category (e.g., `git`, `zsh`, `tmux`), and contains the corresponding configuration files.

```
~/.dotfiles/
├── git/
│   ├── .gitconfig
│   ├── .gitignore
├── zsh/
│   ├── .zshrc
│   ├── .oh-my-zsh/
│       ├── themes/
│       ├── plugins/
├── tmux/
│   ├── .tmux.conf
└── vim/
    ├── .config/vim/
        ├── init.vim
```

This ensures that subdirectories (e.g., `.oh-my-zsh`) are correctly symlinked into `~` instead of being placed inside `~/zsh/`.

---

## 🔧 Installation & Usage

### 1️⃣ Clone the Repository
```bash
git clone --recursive https://github.com/Kotmin/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles
```

### 2️⃣ Install GNU Stow (if not already installed)
```bash
# On Debian/Ubuntu
sudo apt install stow

# On macOS (Homebrew)
brew install stow
```

### 3️⃣ Symlink All Dotfiles
```bash
cd ~/.dotfiles && for dir in */; do stow -t ~ "$dir"; done
```

### 4️⃣ (Optional) Unstow Dotfiles
If you need to remove the symlinks:
```bash
cd ~/.dotfiles && for dir in */; do stow -D -t ~ "$dir"; done
```

---

## 🔥 Features
✅ **Modular & Clean** - Each tool has its own directory.  
✅ **Easily Portable** - Just clone & run `stow`.  
✅ **No Conflicts** - Stow ensures safe symlinking.  
✅ **Subdirectory Support** - Works with nested configs (e.g., `~/.config/nvim`).  
✅ **Automated Setup** - One-liner to install everything.  

---

## 🎯 Customization
Feel free to fork this repository and modify configurations to suit your needs. You can easily add more tools by creating new folders inside `.dotfiles/` and adding your configurations.

---

## 🛠 Troubleshooting
If a file already exists in `~` and prevents symlinking, move it first:
```bash
mv ~/.gitconfig ~/.dotfiles/git/.gitconfig
stow -t ~ git
```

For debugging Stow operations, use:
```bash
stow -nv -t ~ git  # Dry run, verbose mode
```

---

## 🤝 Contributions
Have a cool tweak? Feel free to submit a PR or open an issue!

---

## 📜 License
This project is licensed under the MIT License. See the `LICENSE` file for details.

---

🚀 **Happy coding!**


