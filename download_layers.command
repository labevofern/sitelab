#!/bin/bash

# Download de camadas ambientais com Git LFS para macOS.
# Laboratório de Evolução de Samambaias e Licófitas
# Correspondente - Niksoney A. Mendonça (niksoneyazevedo2017@gmail.com)

set -u

REPO_URL="https://github.com/labevofern/Environmental-layers.git"
REPO_NAME="Environmental-layers"
START_DIR="$(pwd -P)"
DOWNLOAD_MODE=""
MODE_LABEL=""
SELECTED_FOLDER=""
DEST=""
TARGET_DIR=""

if [ -t 1 ]; then
    C_RESET="$(printf '\033[0m')"
    C_CYAN="$(printf '\033[96m')"
    C_GREEN="$(printf '\033[92m')"
    C_YELLOW="$(printf '\033[93m')"
    C_RED="$(printf '\033[91m')"
    C_WHITE="$(printf '\033[97m')"
else
    C_RESET=""
    C_CYAN=""
    C_GREEN=""
    C_YELLOW=""
    C_RED=""
    C_WHITE=""
fi

header() {
    clear 2>/dev/null || true
    printf '%s\n' "${C_CYAN}======================================================================${C_RESET}"
    printf '%s\n' "${C_WHITE}  DOWNLOAD DE CAMADAS AMBIENTAIS EM ALTA RESOLUÇÃO - GIT LFS${C_RESET}"
    printf '%s\n' "${C_CYAN}======================================================================${C_RESET}"
    printf '%s\n' "  Laboratório de Evolução de Samambaias e Licófitas"
    printf '%s\n' "  Correspondente - Niksoney A. Mendonça"
    printf '%s\n\n' "${C_CYAN}======================================================================${C_RESET}"
}

pause_terminal() {
    printf '\nPressione Enter para fechar...'
    IFS= read -r _pause_value || true
}

fail_and_exit() {
    printf '\n%s[ERRO]%s %s\n' "$C_RED" "$C_RESET" "$1"
    pause_terminal
    exit 1
}

clean_typed_path() {
    CLEANED_PATH="$1"
    CLEANED_PATH="${CLEANED_PATH#\"}"
    CLEANED_PATH="${CLEANED_PATH%\"}"
    CLEANED_PATH="${CLEANED_PATH#\'}"
    CLEANED_PATH="${CLEANED_PATH%\'}"
    CLEANED_PATH="${CLEANED_PATH//\\ / }"
    case "$CLEANED_PATH" in
        "~") CLEANED_PATH="$HOME" ;;
        \~/*) CLEANED_PATH="$HOME/${CLEANED_PATH#\~/}" ;;
    esac
}

check_requirements() {
    header
    printf '%s\n' "Verificando Git e Git LFS..."

    if ! command -v git >/dev/null 2>&1; then
        printf '\n%s[AVISO]%s Git não foi encontrado.\n' "$C_YELLOW" "$C_RESET"
        printf '%s\n' "O macOS abrirá o instalador oficial das Ferramentas de Linha de Comando, que incluem o Git."
        printf 'Deseja abrir o instalador agora? [S/n]: '
        IFS= read -r INSTALL_GIT_OPTION
        case "$INSTALL_GIT_OPTION" in
            ""|s|S)
                xcode-select --install >/dev/null 2>&1 || true
                printf '%s\n' "Conclua a instalação do macOS e depois abra este arquivo novamente."
                ;;
            *)
                printf '%s\n' "Instalação manual: https://git-scm.com/download/mac"
                ;;
        esac
        pause_terminal
        exit 1
    fi

    if ! git lfs version >/dev/null 2>&1; then
        printf '\n%s[AVISO]%s Git LFS não foi encontrado.\n' "$C_YELLOW" "$C_RESET"
        if command -v brew >/dev/null 2>&1; then
            printf 'Deseja baixar e instalar o Git LFS com Homebrew agora? [S/n]: '
            IFS= read -r INSTALL_LFS_OPTION
            case "$INSTALL_LFS_OPTION" in
                ""|s|S)
                    if ! brew install git-lfs; then
                        fail_and_exit "A instalação do Git LFS falhou. Instale manualmente em https://git-lfs.com/"
                    fi
                    ;;
                *)
                    printf '%s\n' "Instalação manual: brew install git-lfs ou https://git-lfs.com/"
                    pause_terminal
                    exit 1
                    ;;
            esac
        else
            printf '%s\n' "O Homebrew não está instalado. A página oficial do Git LFS será aberta."
            open "https://git-lfs.com/" >/dev/null 2>&1 || true
            printf '%s\n' "Instale o Git LFS e depois abra este arquivo novamente."
            pause_terminal
            exit 1
        fi
    fi

    if ! git lfs install >/dev/null 2>&1; then
        fail_and_exit "O Git LFS foi encontrado, mas não pôde ser ativado. Tente executar: git lfs install"
    fi
}

choose_mode() {
    while :; do
        header
        printf '%s\n\n' "${C_WHITE}O que você deseja baixar?${C_RESET}"
        printf '  %s[1]%s Repositório completo (todas as camadas em alta resolução)\n' "$C_GREEN" "$C_RESET"
        printf '  %s[2]%s Somente uma pasta (economiza espaço e transferência)\n' "$C_GREEN" "$C_RESET"
        printf '  %s[3]%s Sair\n\n' "$C_YELLOW" "$C_RESET"
        printf 'Escolha uma opção [1-3]: '
        IFS= read -r MODE_OPTION

        case "$MODE_OPTION" in
            1)
                DOWNLOAD_MODE="full"
                MODE_LABEL="Repositório completo"
                return
                ;;
            2)
                DOWNLOAD_MODE="folder"
                MODE_LABEL="Somente uma pasta"
                return
                ;;
            3)
                header
                printf '%s\n' "${C_YELLOW}Operação cancelada. Nenhum download foi iniciado.${C_RESET}"
                pause_terminal
                exit 0
                ;;
            *)
                printf '%s\n' "${C_RED}Opção inválida.${C_RESET}"
                sleep 1
                ;;
        esac
    done
}

choose_destination() {
    while :; do
        header
        printf '%s\n\n' "${C_WHITE}Onde os arquivos devem ser salvos?${C_RESET}"
        printf '  %s[1]%s Downloads (padrão)\n' "$C_GREEN" "$C_RESET"
        printf '  %s[2]%s Escolher uma pasta no Finder\n' "$C_GREEN" "$C_RESET"
        printf '  %s[3]%s Digitar ou colar um caminho\n' "$C_GREEN" "$C_RESET"
        printf '  %s[4]%s Voltar\n\n' "$C_YELLOW" "$C_RESET"
        printf 'Escolha uma opção [1-4]: '
        IFS= read -r DEST_OPTION

        case "$DEST_OPTION" in
            1)
                DEST="$HOME/Downloads"
                break
                ;;
            2)
                if PICKED_DEST="$(osascript -e 'POSIX path of (choose folder with prompt "Escolha onde salvar as camadas ambientais")' 2>/dev/null)"; then
                    DEST="${PICKED_DEST%/}"
                    break
                fi
                printf '%s\n' "${C_YELLOW}Nenhuma pasta foi escolhida.${C_RESET}"
                sleep 1
                ;;
            3)
                printf '\nDigite ou arraste uma pasta do Finder para esta janela: '
                IFS= read -r DEST_INPUT
                clean_typed_path "$DEST_INPUT"
                DEST="$CLEANED_PATH"
                if [ -n "$DEST" ]; then
                    break
                fi
                printf '%s\n' "${C_RED}O caminho não pode ficar vazio.${C_RESET}"
                sleep 1
                ;;
            4)
                choose_mode
                ;;
            *)
                printf '%s\n' "${C_RED}Opção inválida.${C_RESET}"
                sleep 1
                ;;
        esac
    done

    if ! mkdir -p "$DEST" 2>/dev/null; then
        fail_and_exit "Não foi possível criar ou acessar: $DEST"
    fi
    if [ ! -w "$DEST" ]; then
        fail_and_exit "Sem permissão para gravar em: $DEST"
    fi

    DEST="$(cd "$DEST" && pwd -P)"
    TARGET_DIR="$DEST/$REPO_NAME"
}

prepare_target() {
    if [ ! -e "$TARGET_DIR" ]; then
        return
    fi

    while [ -e "$TARGET_DIR" ]; do
        header
        printf '%s\n' "${C_YELLOW}Já existe uma pasta com este nome:${C_RESET}"
        printf '%s\n\n' "$TARGET_DIR"
        printf '  %s[1]%s Salvar em uma nova pasta numerada (recomendado)\n' "$C_GREEN" "$C_RESET"
        printf '  %s[2]%s Substituir a pasta existente\n' "$C_YELLOW" "$C_RESET"
        printf '  %s[3]%s Cancelar\n\n' "$C_RED" "$C_RESET"
        printf 'Escolha uma opção [1-3]: '
        IFS= read -r TARGET_OPTION

        case "$TARGET_OPTION" in
            1)
                suffix=1
                TARGET_DIR="$DEST/${REPO_NAME}_novo_${suffix}"
                while [ -e "$TARGET_DIR" ]; do
                    suffix=$((suffix + 1))
                    TARGET_DIR="$DEST/${REPO_NAME}_novo_${suffix}"
                done
                return
                ;;
            2)
                printf '\n%sATENÇÃO:%s todo o conteúdo da pasta existente será apagado.\n' "$C_RED" "$C_RESET"
                printf 'Digite SUBSTITUIR para confirmar: '
                IFS= read -r CONFIRM_REPLACE
                if [ "$CONFIRM_REPLACE" = "SUBSTITUIR" ]; then
                    if ! rm -rf "$TARGET_DIR"; then
                        fail_and_exit "Não foi possível remover a pasta existente."
                    fi
                    return
                fi
                printf '%s\n' "${C_YELLOW}Substituição não confirmada.${C_RESET}"
                sleep 1
                ;;
            3)
                header
                printf '%s\n' "${C_YELLOW}Operação cancelada. Nenhum download foi iniciado.${C_RESET}"
                pause_terminal
                exit 0
                ;;
            *)
                printf '%s\n' "${C_RED}Opção inválida.${C_RESET}"
                sleep 1
                ;;
        esac
    done
}

confirm_download() {
    header
    printf '%s\n\n' "${C_WHITE}Resumo do download${C_RESET}"
    printf '  Tipo:    %s\n' "$MODE_LABEL"
    printf '  Origem:  %s\n' "$REPO_URL"
    printf '  Destino: %s\n\n' "$TARGET_DIR"
    printf 'Iniciar agora? [S/n]: '
    IFS= read -r CONFIRM_START
    case "$CONFIRM_START" in
        ""|s|S) ;;
        *)
            header
            printf '%s\n' "${C_YELLOW}Operação cancelada. Nenhum download foi iniciado.${C_RESET}"
            pause_terminal
            exit 0
            ;;
    esac
}

clone_repository() {
    header
    printf '%s\n' "${C_CYAN}[1/3]${C_RESET} Baixando a estrutura do repositório..."
    export GIT_LFS_SKIP_SMUDGE=1

    if [ "$DOWNLOAD_MODE" = "folder" ]; then
        if ! git clone --depth 1 --sparse "$REPO_URL" "$TARGET_DIR"; then
            unset GIT_LFS_SKIP_SMUDGE
            rm -rf "$TARGET_DIR"
            fail_and_exit "Não foi possível clonar o repositório. Verifique sua internet e o acesso ao GitHub."
        fi
    else
        if ! git clone --depth 1 "$REPO_URL" "$TARGET_DIR"; then
            unset GIT_LFS_SKIP_SMUDGE
            rm -rf "$TARGET_DIR"
            fail_and_exit "Não foi possível clonar o repositório. Verifique sua internet e o acesso ao GitHub."
        fi
    fi

    if ! cd "$TARGET_DIR"; then
        unset GIT_LFS_SKIP_SMUDGE
        fail_and_exit "Não foi possível acessar a pasta clonada."
    fi
    if ! git lfs install --local >/dev/null 2>&1; then
        unset GIT_LFS_SKIP_SMUDGE
        cd "$START_DIR" || true
        fail_and_exit "O Git LFS não pôde ser configurado no repositório. A pasta foi mantida: $TARGET_DIR"
    fi
}

select_folder() {
    printf '\n%s[2/3]%s Pastas disponíveis no repositório:\n\n' "$C_CYAN" "$C_RESET"
    git ls-tree -d --name-only HEAD | sed 's/^/  - /'
    printf '\n%s\n' "Digite o nome exatamente como aparece acima."
    printf '%s\n' "Para uma subpasta, use o formato Pasta/Subpasta."
    printf '%s\n\n' "Digite 0 para cancelar e voltar."

    while :; do
        printf 'Pasta desejada: '
        IFS= read -r SELECTED_FOLDER
        clean_typed_path "$SELECTED_FOLDER"
        SELECTED_FOLDER="$CLEANED_PATH"
        SELECTED_FOLDER="${SELECTED_FOLDER//\\//}"

        if [ "$SELECTED_FOLDER" = "0" ]; then
            unset GIT_LFS_SKIP_SMUDGE
            cd "$START_DIR" || true
            rm -rf "$TARGET_DIR"
            header
            printf '%s\n' "${C_YELLOW}Operação cancelada. Nenhum arquivo foi mantido.${C_RESET}"
            pause_terminal
            exit 0
        fi

        while [ "${SELECTED_FOLDER#/}" != "$SELECTED_FOLDER" ]; do
            SELECTED_FOLDER="${SELECTED_FOLDER#/}"
        done
        while [ -n "$SELECTED_FOLDER" ] && [ "${SELECTED_FOLDER%/}" != "$SELECTED_FOLDER" ]; do
            SELECTED_FOLDER="${SELECTED_FOLDER%/}"
        done

        if [ -z "$SELECTED_FOLDER" ]; then
            printf '%s\n' "${C_RED}[ERRO]${C_RESET} Informe o nome de uma pasta."
            continue
        fi
        case "/$SELECTED_FOLDER/" in
            */../*)
                printf '%s\n' "${C_RED}[ERRO]${C_RESET} O caminho não pode conter '..'."
                continue
                ;;
        esac

        OBJECT_TYPE="$(git cat-file -t "HEAD:$SELECTED_FOLDER" 2>/dev/null || true)"
        if [ "$OBJECT_TYPE" != "tree" ]; then
            printf '%s\n' "${C_RED}[ERRO]${C_RESET} A pasta não foi encontrada. Confira a escrita."
            continue
        fi
        break
    done

    printf '\n%s[2/3]%s Preparando somente: %s\n' "$C_CYAN" "$C_RESET" "$SELECTED_FOLDER"
    if ! git sparse-checkout set "$SELECTED_FOLDER"; then
        unset GIT_LFS_SKIP_SMUDGE
        cd "$START_DIR" || true
        fail_and_exit "Não foi possível preparar o download seletivo. Atualize o Git e tente novamente."
    fi
}

download_lfs_files() {
    unset GIT_LFS_SKIP_SMUDGE
    if [ "$DOWNLOAD_MODE" = "folder" ]; then
        printf '%s[3/3]%s Baixando os arquivos LFS em alta resolução dessa pasta...\n' "$C_CYAN" "$C_RESET"
        if ! git -c lfs.concurrenttransfers=4 lfs pull --include="$SELECTED_FOLDER/**" --exclude=""; then
            cd "$START_DIR" || true
            fail_and_exit "O download LFS falhou. Verifique a conexão, o espaço livre e a cota do Git LFS. A pasta foi mantida: $TARGET_DIR"
        fi
    else
        printf '\n%s[2/3]%s Estrutura preparada.\n' "$C_CYAN" "$C_RESET"
        printf '%s[3/3]%s Baixando todos os arquivos LFS em alta resolução...\n' "$C_CYAN" "$C_RESET"
        if ! git -c lfs.concurrenttransfers=4 lfs pull; then
            cd "$START_DIR" || true
            fail_and_exit "O download LFS falhou. Verifique a conexão, o espaço livre e a cota do Git LFS. A pasta foi mantida: $TARGET_DIR"
        fi
    fi
}

show_success() {
    COMMIT_ID="$(git rev-parse --short HEAD 2>/dev/null || true)"
    cd "$START_DIR" || true
    header
    printf '%s\n\n' "${C_GREEN}[OK] Download concluído com sucesso.${C_RESET}"
    printf '  Pasta salva em: %s\n' "$TARGET_DIR"
    if [ -n "$SELECTED_FOLDER" ]; then
        printf '  Pasta selecionada: %s\n' "$SELECTED_FOLDER"
    fi
    if [ -n "$COMMIT_ID" ]; then
        printf '  Versão do repositório: %s\n' "$COMMIT_ID"
    fi
    printf '\n%s\n\n' "Os arquivos .tif foram obtidos pelo Git LFS em alta resolução."
    printf 'Abrir a pasta no Finder agora? [S/n]: '
    IFS= read -r OPEN_OPTION
    case "$OPEN_OPTION" in
        ""|s|S) open "$TARGET_DIR" ;;
    esac
    pause_terminal
}

trap 'unset GIT_LFS_SKIP_SMUDGE 2>/dev/null || true' EXIT

check_requirements
choose_mode
choose_destination
prepare_target
confirm_download
clone_repository
if [ "$DOWNLOAD_MODE" = "folder" ]; then
    select_folder
fi
download_lfs_files
show_success
exit 0
