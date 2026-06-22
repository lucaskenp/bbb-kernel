#!/bin/bash
# Build do kernel Linux para BeagleBone Black (AM335x)
#
# Uso standalone (fora do Buildroot):
#   ./build.sh
#   ./build.sh menuconfig
#   ./build.sh clean
#
# Dentro do container Docker (bbb-embedded-linux):
#   O Buildroot usa LINUX_OVERRIDE_SRCDIR e chama make diretamente.
#   Este script é apenas para desenvolvimento/debug isolado.
#
# Cross compiler necessário:
#   sudo apt install gcc-arm-linux-gnueabihf  (Ubuntu/Debian)
#   OU usar o toolchain do Buildroot após um build:
#     export CROSS_COMPILE=/workspace/project/output_kernel/host/bin/arm-buildroot-linux-gnueabi-

set -e

ARCH=arm
CROSS_COMPILE="${CROSS_COMPILE:-arm-linux-gnueabihf-}"
JOBS="${JOBS:-$(nproc)}"

# Usar defconfig customizada se existir, senão usar omap2plus como base
if [ -f "arch/arm/configs/bbb_defconfig" ]; then
    DEFCONFIG=bbb_defconfig
else
    DEFCONFIG=omap2plus_defconfig
    echo "AVISO: arch/arm/configs/bbb_defconfig não encontrada, usando $DEFCONFIG como base"
fi

if ! command -v "${CROSS_COMPILE}gcc" &>/dev/null; then
    echo "ERRO: cross compiler não encontrado: ${CROSS_COMPILE}gcc"
    echo ""
    echo "Instale com:"
    echo "  sudo apt install gcc-arm-linux-gnueabihf"
    echo ""
    echo "Ou use o toolchain do Buildroot:"
    echo "  export CROSS_COMPILE=/workspace/project/output_kernel/host/bin/arm-buildroot-linux-gnueabi-"
    exit 1
fi

export ARCH CROSS_COMPILE

case "${1:-build}" in
    build)
        echo "==> Configurando com $DEFCONFIG..."
        make "$DEFCONFIG"
        echo "==> Compilando com $JOBS jobs..."
        make -j"$JOBS" zImage dtbs modules
        echo ""
        echo "==> Artefatos gerados:"
        ls -lh arch/arm/boot/zImage
        ls -lh arch/arm/boot/dts/am335x-boneblack.dtb 2>/dev/null || true
        ;;
    menuconfig)
        make "$DEFCONFIG"
        make menuconfig
        make savedefconfig DEFCONFIG=arch/arm/configs/bbb_defconfig
        echo "==> bbb_defconfig atualizado"
        ;;
    saveconfig)
        make savedefconfig DEFCONFIG=arch/arm/configs/bbb_defconfig
        echo "==> bbb_defconfig salvo"
        ;;
    clean)
        make distclean
        ;;
    *)
        echo "Uso: $0 [build|menuconfig|saveconfig|clean]"
        exit 1
        ;;
esac
