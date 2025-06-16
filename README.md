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


## Base command set
```bash
ssh-keygen -t ed25519 -C "70173732+Kotmin@users.noreply.github.com"
# use rsa instead if not supported
sudo apt update
sudo apt upgrade

sudo apt install -y git
sudo apt install -y curl
sudo apt install -y vim

#  curl -fsSL https://get.docker.com -o get-docker.sh
#  sudo sh get-docker.sh

curl -fsSL https://get.docker.com | sh
sudo systemctl enable --now docker

docker --version
sudo usermod -aG docker $USER
newgrp docker

## DOCKER COMPOSE
sudo curl -SL "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

## gpu support section if needed!!!

sudo systemctl restart docker


# k8n
ARCH=$(uname -m)
if [[ "$ARCH" == "x86_64" ]]; then ARCH="amd64"; elif [[ "$ARCH" == "aarch64" ]]; then ARCH="arm64"; fi

# something is wrong with this chain of commands, one by one works fine
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/$(uname -s | tr '[:upper:]' '[:lower:]')/$ARCH/kubectl" && \
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/$(uname -s | tr '[:upper:]' '[:lower:]')/$ARCH/kubectl.sha256" && \
echo "$(cat kubectl.sha256)" kubectl | sha256sum --check --status && \
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && \
rm -f kubectl kubectl.sha256 && \
kubectl version --client || { echo "❌ Checksum failed! Cleaning up."; rm -f kubectl kubectl.sha256; exit 1; }
# https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/


# TerraForm

TF_VERSION=$(curl -sL https://api.github.com/repos/hashicorp/terraform/releases/latest | jq -r .tag_name | sed 's/v//') && \
ARCH=$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/') && \
OS=$(uname -s | tr '[:upper:]' '[:lower:]') && \
curl -LO "https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_${OS}_${ARCH}.zip" && \
curl -LO "https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_SHA256SUMS" && \
grep "terraform_${TF_VERSION}_${OS}_${ARCH}.zip" terraform_${TF_VERSION}_SHA256SUMS | sha256sum --check --status && \
unzip terraform_${TF_VERSION}_${OS}_${ARCH}.zip && \
sudo mv terraform /usr/local/bin/ && \
rm -f terraform_${TF_VERSION}_${OS}_${ARCH}.zip terraform_${TF_VERSION}_SHA256SUMS && \
terraform -version || { echo "❌ Checksum failed! Cleaning up."; rm -f terraform_${TF_VERSION}_${OS}_${ARCH}.zip terraform_${TF_VERSION}_SHA256SUMS; exit 1; }

# cp key if present
cat ~/.ssh/id_ed25519.pub | clip
ssh -T git@github.com


```


---

## 📜 License
This project is licensed under the MIT License. See the `LICENSE` file for details.

---

🚀 **Happy coding!**


