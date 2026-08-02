@echo off
chcp 65001 >nul
setlocal EnableExtensions DisableDelayedExpansion

title Download de camadas ambientais - LabEvoFern
color 0B

set "REPO_URL=https://github.com/labevofern/Environmental-layers.git"
set "REPO_NAME=Environmental-layers"
set "DOWNLOAD_MODE="
set "MODE_LABEL="
set "SELECTED_FOLDER="
set "DEST="
set "TARGET_DIR="

for /F "delims=" %%E in ('echo prompt $E^| cmd') do set "ESC=%%E"
set "C_RESET=%ESC%[0m"
set "C_CYAN=%ESC%[96m"
set "C_GREEN=%ESC%[92m"
set "C_YELLOW=%ESC%[93m"
set "C_RED=%ESC%[91m"
set "C_WHITE=%ESC%[97m"

call :check_requirements
if errorlevel 1 goto :end_error

:main_menu
call :header
echo %C_WHITE%O que você deseja baixar?%C_RESET%
echo.
echo   %C_GREEN%[1]%C_RESET% Repositório completo ^(todas as camadas em alta resolução^)
echo   %C_GREEN%[2]%C_RESET% Somente uma pasta ^(economiza espaço e transferência^)
echo   %C_YELLOW%[3]%C_RESET% Sair
echo.
choice /C 123 /N /M "Escolha uma opção [1-3]: "
if errorlevel 3 goto :cancelled
if errorlevel 2 (
    set "DOWNLOAD_MODE=folder"
    set "MODE_LABEL=Somente uma pasta"
    goto :destination_menu
)
set "DOWNLOAD_MODE=full"
set "MODE_LABEL=Repositório completo"
goto :destination_menu

:destination_menu
call :header
echo %C_WHITE%Onde os arquivos devem ser salvos?%C_RESET%
echo.
echo   %C_GREEN%[1]%C_RESET% Downloads ^(padrão^)
echo   %C_GREEN%[2]%C_RESET% Escolher uma pasta em uma janela
echo   %C_GREEN%[3]%C_RESET% Digitar ou colar um caminho
echo   %C_YELLOW%[4]%C_RESET% Voltar
echo.
choice /C 1234 /N /M "Escolha uma opção [1-4]: "
if errorlevel 4 goto :main_menu
if errorlevel 3 goto :manual_destination
if errorlevel 2 goto :graphical_destination
set "DEST=%USERPROFILE%\Downloads"
goto :validate_destination

:graphical_destination
set "DEST="
for /F "usebackq delims=" %%I in (`powershell -NoProfile -STA -Command "Add-Type -AssemblyName System.Windows.Forms; $dialog = New-Object System.Windows.Forms.FolderBrowserDialog; $dialog.Description = 'Escolha onde salvar as camadas ambientais'; $dialog.ShowNewFolderButton = $true; if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { [Console]::Write($dialog.SelectedPath) }"`) do set "DEST=%%I"
if not defined DEST (
    echo.
    echo %C_YELLOW%[AVISO]%C_RESET% Nenhuma pasta foi escolhida.
    timeout /t 2 >nul
    goto :destination_menu
)
goto :validate_destination

:manual_destination
echo.
echo Você pode arrastar uma pasta do Explorador de Arquivos para esta janela.
set "DEST="
set /P "DEST=Digite ou cole o caminho completo: "
set "DEST=%DEST:"=%"
if not defined DEST (
    echo %C_RED%[ERRO]%C_RESET% O caminho não pode ficar vazio.
    pause
    goto :destination_menu
)
goto :validate_destination

:validate_destination
if not exist "%DEST%\" mkdir "%DEST%" >nul 2>&1
if not exist "%DEST%\" (
    echo.
    echo %C_RED%[ERRO]%C_RESET% Não foi possível criar ou acessar:
    echo %DEST%
    echo Verifique o caminho e as permissões da pasta.
    pause
    goto :destination_menu
)
for %%I in ("%DEST%") do set "DEST=%%~fI"
set "TARGET_DIR=%DEST%\%REPO_NAME%"
goto :prepare_target

:prepare_target
if not exist "%TARGET_DIR%" goto :confirm_download

call :header
echo %C_YELLOW%Já existe uma pasta com este nome:%C_RESET%
echo %TARGET_DIR%
echo.
echo   %C_GREEN%[N]%C_RESET% Salvar em uma nova pasta numerada ^(recomendado^)
echo   %C_YELLOW%[S]%C_RESET% Substituir a pasta existente
echo   %C_RED%[C]%C_RESET% Cancelar
echo.
choice /C NSC /N /M "Escolha [N/S/C]: "
if errorlevel 3 goto :cancelled
if errorlevel 2 goto :replace_target

set /A SUFFIX=1
:find_free_target
set "TARGET_DIR=%DEST%\%REPO_NAME%_novo_%SUFFIX%"
if exist "%TARGET_DIR%" (
    set /A SUFFIX+=1
    goto :find_free_target
)
goto :confirm_download

:replace_target
echo.
echo %C_RED%ATENÇÃO:%C_RESET% a pasta existente e todo o conteúdo dela serão apagados.
choice /C SN /N /M "Confirma a substituição? [S/N]: "
if errorlevel 2 goto :prepare_target
rd /S /Q "%TARGET_DIR%" >nul 2>&1
if exist "%TARGET_DIR%" (
    echo.
    echo %C_RED%[ERRO]%C_RESET% Não foi possível remover a pasta existente.
    echo Feche arquivos abertos nela ou escolha outro local.
    pause
    goto :prepare_target
)
goto :confirm_download

:confirm_download
call :header
echo %C_WHITE%Resumo do download%C_RESET%
echo.
echo   Tipo:    %MODE_LABEL%
echo   Origem:  %REPO_URL%
echo   Destino: %TARGET_DIR%
echo.
choice /C SN /N /M "Iniciar agora? [S/N]: "
if errorlevel 2 goto :main_menu

call :header
echo %C_CYAN%[1/3]%C_RESET% Baixando a estrutura do repositório...
set "GIT_LFS_SKIP_SMUDGE=1"
if /I "%DOWNLOAD_MODE%"=="folder" goto :clone_sparse

git clone --depth 1 "%REPO_URL%" "%TARGET_DIR%"
if errorlevel 1 goto :clone_failed
goto :after_clone

:clone_sparse
git clone --depth 1 --sparse "%REPO_URL%" "%TARGET_DIR%"
if errorlevel 1 goto :clone_failed

:after_clone
pushd "%TARGET_DIR%"
if errorlevel 1 goto :clone_failed
git lfs install --local >nul 2>&1
if errorlevel 1 goto :lfs_setup_failed

if /I "%DOWNLOAD_MODE%"=="folder" goto :select_folder
goto :download_lfs_full

:select_folder
echo.
echo %C_CYAN%[2/3]%C_RESET% Pastas disponíveis no repositório:
echo.
for /F "delims=" %%D in ('git ls-tree -d --name-only HEAD') do echo   - %%D
echo.
echo Digite o nome exatamente como aparece acima.
echo Para uma subpasta, use o formato Pasta/Subpasta.
echo Digite 0 para cancelar e voltar ao menu.

:folder_prompt
set "SELECTED_FOLDER="
set /P "SELECTED_FOLDER=Pasta desejada: "
set "SELECTED_FOLDER=%SELECTED_FOLDER:"=%"
set "SELECTED_FOLDER=%SELECTED_FOLDER:\=/%"
if "%SELECTED_FOLDER%"=="0" goto :cancel_after_clone
if not defined SELECTED_FOLDER (
    echo %C_RED%[ERRO]%C_RESET% Informe o nome de uma pasta.
    goto :folder_prompt
)

:trim_leading_slash
if "%SELECTED_FOLDER:~0,1%"=="/" (
    set "SELECTED_FOLDER=%SELECTED_FOLDER:~1%"
    goto :trim_leading_slash
)
:trim_trailing_slash
if "%SELECTED_FOLDER:~-1%"=="/" (
    set "SELECTED_FOLDER=%SELECTED_FOLDER:~0,-1%"
    goto :trim_trailing_slash
)
if not defined SELECTED_FOLDER (
    echo %C_RED%[ERRO]%C_RESET% Informe o nome de uma pasta.
    goto :folder_prompt
)
if not "%SELECTED_FOLDER:..=%"=="%SELECTED_FOLDER%" (
    echo %C_RED%[ERRO]%C_RESET% O caminho não pode conter "..".
    goto :folder_prompt
)

set "OBJECT_TYPE="
for /F "delims=" %%T in ('git cat-file -t "HEAD:%SELECTED_FOLDER%" 2^>nul') do set "OBJECT_TYPE=%%T"
if /I not "%OBJECT_TYPE%"=="tree" (
    echo %C_RED%[ERRO]%C_RESET% A pasta não foi encontrada. Confira a escrita e tente novamente.
    goto :folder_prompt
)

echo.
echo %C_CYAN%[2/3]%C_RESET% Preparando somente: %SELECTED_FOLDER%
git sparse-checkout set "%SELECTED_FOLDER%"
if errorlevel 1 goto :sparse_failed

set "GIT_LFS_SKIP_SMUDGE="
echo %C_CYAN%[3/3]%C_RESET% Baixando os arquivos LFS em alta resolução dessa pasta...
git -c lfs.concurrenttransfers=16 lfs pull --include="%SELECTED_FOLDER%/**" --exclude=""
if errorlevel 1 goto :lfs_failed
goto :download_success

:download_lfs_full
set "GIT_LFS_SKIP_SMUDGE="
echo.
echo %C_CYAN%[2/3]%C_RESET% Estrutura preparada.
echo %C_CYAN%[3/3]%C_RESET% Baixando todos os arquivos LFS em alta resolução...
git -c lfs.concurrenttransfers=16 lfs pull
if errorlevel 1 goto :lfs_failed
goto :download_success

:download_success
set "COMMIT_ID="
for /F "delims=" %%H in ('git rev-parse --short HEAD 2^>nul') do set "COMMIT_ID=%%H"
popd
call :header
echo %C_GREEN%[OK] Download concluído com sucesso.%C_RESET%
echo.
echo   Pasta salva em: %TARGET_DIR%
if defined SELECTED_FOLDER echo   Pasta selecionada: %SELECTED_FOLDER%
if defined COMMIT_ID echo   Versão do repositório: %COMMIT_ID%
echo.
echo Os arquivos .tif foram obtidos pelo Git LFS em alta resolução.
echo.
choice /C SN /N /M "Abrir a pasta agora? [S/N]: "
if errorlevel 2 goto :end_success
start "" explorer.exe "%TARGET_DIR%"
goto :end_success

:cancel_after_clone
set "GIT_LFS_SKIP_SMUDGE="
popd
rd /S /Q "%TARGET_DIR%" >nul 2>&1
goto :main_menu

:clone_failed
set "GIT_LFS_SKIP_SMUDGE="
if exist "%TARGET_DIR%" rd /S /Q "%TARGET_DIR%" >nul 2>&1
echo.
echo %C_RED%[ERRO]%C_RESET% Não foi possível clonar o repositório.
echo Verifique sua internet, o acesso ao GitHub e tente novamente.
pause
goto :end_error

:lfs_setup_failed
set "GIT_LFS_SKIP_SMUDGE="
popd
echo.
echo %C_RED%[ERRO]%C_RESET% O Git LFS não pôde ser configurado neste repositório.
echo A pasta foi mantida para diagnóstico: %TARGET_DIR%
pause
goto :end_error

:sparse_failed
set "GIT_LFS_SKIP_SMUDGE="
popd
echo.
echo %C_RED%[ERRO]%C_RESET% Não foi possível preparar o download seletivo.
echo Atualize o Git para uma versão recente e tente novamente.
echo A pasta foi mantida para diagnóstico: %TARGET_DIR%
pause
goto :end_error

:lfs_failed
set "GIT_LFS_SKIP_SMUDGE="
popd
echo.
echo %C_YELLOW%[AVISO]%C_RESET% A estrutura foi baixada, mas o download dos arquivos LFS falhou.
echo Verifique a conexão, o espaço livre e a cota do Git LFS.
echo A pasta foi mantida para permitir diagnóstico ou nova tentativa:
echo %TARGET_DIR%
pause
goto :end_error

:check_requirements
call :header
echo Verificando Git e Git LFS...
where git >nul 2>&1
if errorlevel 1 (
    echo.
    echo %C_RED%[ERRO]%C_RESET% Git não foi encontrado.
    echo Instale o Git para Windows e execute este arquivo novamente.
    echo https://git-scm.com/download/win
    pause
    exit /B 1
)
git lfs version >nul 2>&1
if errorlevel 1 (
    echo.
    echo %C_RED%[ERRO]%C_RESET% Git LFS não foi encontrado.
    echo Instale o Git LFS e execute este arquivo novamente.
    echo https://git-lfs.com/
    pause
    exit /B 1
)
exit /B 0

:header
cls
echo %C_CYAN%========================================================================%C_RESET%
echo %C_WHITE%  DOWNLOAD DE CAMADAS AMBIENTAIS EM ALTA RESOLUÇÃO - GIT LFS%C_RESET%
echo %C_CYAN%========================================================================%C_RESET%
echo   Laboratório de Evolução de Samambaias e Licófitas
echo   Correspondente - Niksoney A. Mendonça (niksoneyazevedo2017@gmail.com)
echo %C_CYAN%========================================================================%C_RESET%
echo.
exit /B 0

:cancelled
call :header
echo %C_YELLOW%Operação cancelada. Nenhum download foi iniciado.%C_RESET%
goto :end_success

:end_success
echo.
pause
endlocal
exit /B 0

:end_error
endlocal
exit /B 1
