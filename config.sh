# ===== CONFIGURAÇÕES PADRÃO =====

# Partições existentes (dual boot)
BOOT="/dev/sda5"
SWAP="/dev/sda6"
ROOT="/dev/sda7"

# Idioma e região
TIMEZONE="America/Sao_Paulo"
LOCALE="pt_BR.UTF-8"
KEYMAP="br-abnt2"

# Pacotes base
PACOTES_BASE="base linux linux-firmware networkmanager vim sudo grub efibootmgr os-prober nano base-devel"

# Repositório dos dotfiles (altere para o seu)
DOTFILES_REPO="https://github.com/end-4/dots-hyprland.git"
