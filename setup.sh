#!/bin/bash
set -e
source config.sh

USUARIO="yuri"
SENHA="2002"
SENHA_ROOT="2002"
HOSTNAME="ARCHIE"

menu() {
    clear
    echo "=========================================="
    echo "   🌀 INSTALADOR AUTOMÁTICO ARCH LINUX"
    echo "=========================================="
    echo "1) Configurar usuário"
    echo "2) Preparar partições"
    echo "3) Instalar sistema base"
    echo "4) Configurar sistema"
    echo "5) Instalar Hyprland e Dotfiles"
    echo "6) Instalar tudo (automático)"
    echo "7) Sair"
    echo "=========================================="
    read -p "Escolha uma opção: " OP
    case $OP in
        2) preparar_particoes sleep 1; menu;;
        3) instalar_base sleep 1; menu;;
        4) configurar_sistema sleep 1; menu;;
        5) instalar_hyprland sleep 1; menu ;;
        6) tudo sleep 1; menu;;
        7) exit sleep 1; menu;;
        *) echo "Opção inválida!"; sleep 1; menu ;;
    esac
}


preparar_particoes() {
    echo ">> Ativando swap..."
    mkswap $SWAP
    swapon $SWAP

    echo ">> Formatando e montando partições..."
    mkfs.fat -F32 $BOOT
    mkfs.ext4 $ROOT
    mount $ROOT /mnt
    mkdir -p /mnt/boot/efi
    mount $BOOT /mnt/boot/efi
    echo "Partições montadas com sucesso!"
    read -p "Pressione ENTER para voltar ao menu"
}

instalar_base() {
    echo ">> Instalando sistema base..."
    pacstrap /mnt $PACOTES_BASE
    genfstab -U /mnt >> /mnt/etc/fstab
    echo "Base instalada com sucesso!"
    read -p "Pressione ENTER para voltar ao menu"
}

configurar_sistema() {
    echo ">> Entrando no chroot e configurando sistema..."
    arch-chroot /mnt /bin/bash <<EOF
set -e
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc
sed -i "s/#$LOCALE UTF-8/$LOCALE UTF-8/" /etc/locale.gen
locale-gen
echo "LANG=$LOCALE" > /etc/locale.conf
echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf
echo "$HOSTNAME" > /etc/hostname
systemctl enable NetworkManager

echo ">> Criando usuário e configurando senhas..."
echo "root:$SENHA_ROOT" | chpasswd
useradd -m -G wheel -s /bin/bash $USUARIO
echo "$USUARIO:$SENHA" | chpasswd
sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers

echo ">> Instalando bootloader (dual boot)..."
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=Arch
os-prober
grub-mkconfig -o /boot/grub/grub.cfg
EOF
    echo "Configuração concluída!"
    read -p "Pressione ENTER para voltar ao menu"
}

instalar_hyprland() {
    clear
    echo "=== INSTALAÇÃO DO HYPRLAND ==="
    echo "Escolha o driver da GPU:"
    echo "1) AMD"
    echo "2) NVIDIA"
    echo "3) Intel"
    read -p "Seleção: " GPU_OP

    case $GPU_OP in
        1) GPU_DRIVER="mesa vulkan-radeon" ;;
        2) GPU_DRIVER="nvidia nvidia-utils nvidia-settings" ;;
        3) GPU_DRIVER="mesa vulkan-intel" ;;
        *) echo "Opção inválida!"; sleep 1; instalar_hyprland; return ;;
    esac

    echo ">> Entrando no chroot e instalando Hyprland..."
    arch-chroot /mnt /bin/bash <<EOF
set -e
pacman -S --noconfirm $GPU_DRIVER

# Pacotes essenciais do Hyprland
pacman -S --noconfirm hyprland firefox neovim git unzip base-devel 

runuser -l $USUARIO -c "xdg-user-dirs-update"

echo ">> Clonando dotfiles..."
runuser -l $USUARIO -c "git clone $DOTFILES_REPO ~/dotfiles || true"

if [ -f "/home/$USUARIO/dotfiles/setup" ]; then
    echo ">> Executando setup..."
    chmod +x /home/$USUARIO/dotfiles/setup
    echo "$SENHA_ROOT" | sudo -S -u $USUARIO bash -c "cd ~/dotfiles && ./setup install"
else
    echo "⚠️  Nenhum arquivo 'setup' encontrado em ~/dotfiles"
fi
EOF

    echo "Hyprland instalado e configurado!"
    read -p "Pressione ENTER para voltar ao menu"
}

tudo() {
    configurar_usuario
    preparar_particoes
    instalar_base
    configurar_sistema
    instalar_hyprland
    echo "==============================="
    echo "✅ Instalação completa finalizada com Hyprland!"
    echo "==============================="
}

menu
