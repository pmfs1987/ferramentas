#!/bin/bash

# Script que contém funções recorrentes utilizadas noutros scripts

function pergunta_sim_nao() {

    # Função de resposta a uma pergunta, com as opções de sim ou não.
    # Necessita de input da pergunta em formato string.
    # Devolve o estado 0 para sim e estado 1 para não.
    # Pode ser utilizado diretamente em testes de if (0 = true).
    # Ex: if pergunta_sim_nao "Pergunta?"; then echo "Respondeu sim"; else echo "Respondeu não"; fi
    # Pode também ser utilizado gravando, imediatamente a seguir ao uso da função, o valor contido em $? numa variável.

    while true; do
        echo -e "$1 [s/n]: "
        read pergunta_sim_nao_resposta
        case $pergunta_sim_nao_resposta in
            S|s ) return 0;;
            N|n ) return 1;;
            * ) echo "Opção errada. Selecione s ou n.";;
        esac
    done
}

function menu_texto_simples () {

    # Função que gera no terminal um menu de texto simples com as opções fornecidas, sem título.
    # Necessita de input de vários argumentos ou de um array, que serão as várias opções em formato string, exceto o 1º argumento ou elemento do array.
    # O 1º argumento (ou o 1º elemento do array) serve para escolher o tipo de menu.
    # Assim, é obrigatório que este seja ou 0 para menu principal (adicionar-se-á a opção "Sair" ou 1 para menu intermédio (opção "Voltar ao menu anterior").
    # Quando o 1º argumento (ou o 1º elemento do array) seja diferente de 0 e de 1 a função termina com o valor de 0 (return 0).
    # O código expõe as opções com um número e abrir parêntese (ex: 1) Opção 1.).
    # Devolve o estado correspondente ao índice de cada opção + 1, que pode ser usado em condições if.
    # Pode ser utilizado gravando, imediatamente a seguir ao uso da função, o valor contido em $? numa variável.
    # Suporta, no máximo 254 opções.
    # Ex: opcoes=(0 "Opção 1." "Opção 2."); menu_texto_simples "${opcoes[@]}"
    # Ex: menu_texto_simples 1 "Opção 1." "Opção 2."
    
    menu_texto_simples_opcoes=("$@")
    if [ "$menu_texto_simples_opcoes" = 0 ]
    then
        menu_texto_simples_opcao_saida="Sair."
    elif [ "$menu_texto_simples_opcoes" = 1 ]
    then
        menu_texto_simples_opcao_saida="Voltar ao menu anterior."
    else
        echo "Erro na função menu_text_simples: o 1º argumento tem de ser 0 ou 1."
        return 0
    fi
    unset menu_texto_simples_opcoes[0]
    PS3="Escolha um número correspondente à opção (1-$((${#menu_texto_simples_opcoes[@]}+1))): "
    select menu_texto_simples_opcao in "${menu_texto_simples_opcoes[@]}" "$menu_texto_simples_opcao_saida"
    do
        case "$menu_texto_simples_opcao" in
            "$menu_texto_simples_opcao_saida")
                break;;
            *)
                for menu_texto_simples_indice in "${!menu_texto_simples_opcoes[@]}"
                do
                    [ "${menu_texto_simples_opcoes[menu_texto_simples_indice]}" = "$menu_texto_simples_opcao" ] && return $((menu_texto_simples_indice+1))
                done
                echo "Opção errada. Escolha entre 1 e $((${#menu_texto_simples_opcoes[@]}+1))"
                ;;
        esac
    done
}

function gestao_repositorio_obtem_token () {
    
    # Função que pede input ao utilizador e verifica se o input fornecido é um personal token válido de um utilizador do GitHub.
    # A função preenche a variável gestao_repositorio_token, usada noutras funções.
    # A função devolve estado 0 quando deteta um personal token válido (e é guardado na variável gestao_repositorio_token).

    unset gestao_repositorio_token
    echo -e "Para continuar é necessário introduzir um personal token do GitHub."
    while true
    do
        read -p "Personal token: " gestao_repositorio_token
        gestao_repositorio_obtem_token_codigo=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: token $gestao_repositorio_token" https://api.github.com/user)
        [ $gestao_repositorio_obtem_token_codigo = 200 ] && return 0
        echo "Token inválido."
    done
}

function gestao_repositorio_verifica_publicidade () {

    # Função que verifica se um repositório é público na respetiva lista de um utilizador no GitHub.
    # Necessita dos seguintes argumentos:
    #   1º argumento - nome do utilizador no GitHub;
    #   2º argumento - nome do repositório no GitHub.
    # Devolve os seguintes estados:
    #   estado 0 quando o repositório é público (isto é, quando se encontra na lista de repositórios públicos);
    #   estado 1 quando não encontra qualquer lista de repositórios públicos (por exemplo, porque o nome do utilizador está errado);
    #   estado 2 quando o repositório é privado ou não existe (isto é, quando não encontra o repositório na referida lista).
    # Pode ser utilizado gravando, imediatamente a seguir ao uso da função, o valor contido em $? numa variável.

    gestao_repositorio_verifica_publicidade_repositorios=($(curl -s https://api.github.com/users/"$1"/repos | grep -Po " {4}\"name\": \"\K[^\"]+(?=\",)")) 
    [ ${#gestao_repositorio_verifica_publicidade_repositorios[@]} = 0 ] && return 1
    for gestao_repositorio_verifica_publicidade_repositorio in ${gestao_repositorio_verifica_publicidade_repositorios[@]}
    do
        [ $gestao_repositorio_verifica_publicidade_repositorio = "$2" ] && return 0
    done
    return 2
}

function gestao_repositorio_verifica_versao () {

    # Função que verifica se um repositório presente no computador está na última versão disponível no GitHub.
    # Utiliza a função gestao_repositorio_verifica_publicidade.
    # Utiliza a função gestao_repositorio_obtem_token (no caso do repositório ser privado).
    # Pressupõe que o repositório já está presente localmente.
    # Pressupõe que o conjunto dos scripts está localizado em "$HOME/Scripts/"
    # Pressupõe que, sem uso do git, as versões instaladas dos repositórios estejam escritas no ficheiro "$HOME/Scripts/.versões/nome_do_repositorio_no_GitHub".
    # Necessita dos seguintes argumentos:
    #   1º argumento - nome do utilizador no GitHub;
    #   2º argumento - nome do repositório no GitHub;
    #   3º argumento - nome da pasta onde o repositório está localmente.
    # Devolve os seguintes estados:
    #   estado 0 quando a versão do repositório no GitHub é igual ou inferior à versão do repositório local.
    #   estado 1 nos seguintes erros:
    #       - o repositório não tem versão de release;
    #       - erro na função gestao_repositorio_verifica_publicidade (estado dessa função != 0 e != 2);
    #       - erros desconhecidos (quando não consegue registar na variável gestao_repositorio_verifica_versao_local a versão local do repositório);
    #   estado 2 quando a versão do repositório no GitHub é superior à versão do repositório local.
    #   estado 3 quando o repositório não está presente em "$HOME/Scripts/nome do repositório".
    #   estado 4 quando não existe nem a pasta .git nem o ficheiro com a versão ("$HOME/Scripts/.versões/nome_do_repositório_no_repositório_no_GitHub")
    # Pode ser utilizado gravando, imediatamente a seguir ao uso da função, o valor contido em $? numa variável.

    unset gestao_repositorio_verifica_versao_local
    unset gestao_repositorio_verifica_versao_github
    gestao_repositorio_verifica_publicidade "$1" "$2"
    gestao_repositorio_verifica_versao_resultado=$?
    if [ $gestao_repositorio_verifica_versao_resultado = 0 ] # quando o repositório é público
    then
        gestao_repositorio_verifica_versao_github=$(curl -s https://api.github.com/repos/"$1"/"$2"/releases/latest | grep -Po " {2}\"tag_name\": \"\K[^\"]+(?=\",)")
    elif [ $gestao_repositorio_verifica_versao_resultado = 2 ] # quando o repositório não é público
    then
        [ -z "$gestao_repositorio_token" ] && gestao_repositorio_obtem_token
        gestao_repositorio_verifica_versao_github=$(curl -sH "Authorization: token $gestao_repositorio_token" https://api.github.com/repos/"$1"/"$2"/releases/latest | grep -Po " {2}\"tag_name\": \"\K[^\"]+(?=\",)")
    fi
    [ -z "$gestao_repositorio_verifica_versao_github" ] && return 1
    if [ -d "$HOME/Scripts/$3" ]
    then
        if [ -d "$HOME/Scripts/$3/.git" ]
        then
            gestao_repositorio_verifica_versao_caminho=$(pwd)
            cd "$HOME/Scripts/$3"
            gestao_repositorio_verifica_versao_local=$(git describe --tags | grep -oP "\d+\.\d+\.\d+(?=-)?")
            cd "$gestao_repositorio_verifica_versao_caminho"
        else
            [ -f "$HOME/Scripts/.versões/$2" ] && gestao_repositorio_verifica_versao_local=$(cat "$HOME/Scripts/.versões/$2") || return 4
        fi
    else
        return 3
    fi
    [ -z "$gestao_repositorio_verifica_versao_local" ] && return 1
    gestao_repositorio_verifica_versao_temporario=$IFS
    IFS='.'
    read -r -a gestao_repositorio_verifica_versao_github_numeros <<< $gestao_repositorio_verifica_versao_github
    read -r -a gestao_repositorio_verifica_versao_local_numeros <<< $gestao_repositorio_verifica_versao_local
    IFS=$gestao_repositorio_verifica_versao_temporario
    for gestao_repositorio_verifica_versao_iteracao in "${!gestao_repositorio_verifica_versao_github_numeros[@]}"
    do
        [ ${gestao_repositorio_verifica_versao_github_numeros[$gestao_repositorio_verifica_versao_iteracao]} -gt ${gestao_repositorio_verifica_versao_local_numeros[gestao_repositorio_verifica_versao_iteracao]} ] && return 2
    done
    return 0
}

function gestao_repositorio_instala () {

    # Função que transfere do GitHub e move um repositório para $HOME/Scripts/pasta e regista a versão correspondente em $HOME/Scripts/.versões/nome_do_repositório_no_GitHub.
    # Utiliza a função gestao_repositorio_verifica_publicidade.
    # Utiliza a função gestao_repositorio_obtem_token.
    # Pressupõe que o conjunto dos scripts está localizado em "$HOME/Scripts/"
    # Pressupõe que, sem uso do git, as versões instaladas dos repositórios estejam escritas no ficheiro "$HOME/Scripts/.versões/nome_do_repositorio_no_GitHub".
    # Necessita dos seguintes argumentos:
    #   1º argumento - nome do utilizador no GitHub;
    #   2º argumento - nome do repositório no GitHub;
    #   3º argumento - nome da pasta onde o repositório será instalado localmente.
    # Devolve os seguintes estados:
    #   estado 0 quando a instalação é bem sucedida.
    #   estado 1 quando há falhas na instalação.
    #   estado 3 quando no caminho de instalação corresponde um acompanhamento do git (ou seja, quando existe a pasta .git no referido caminho).
     
    [ -d "$HOME/Scripts/$3/.git" ] && return 3
    gestao_repositorio_verifica_publicidade "$1" "$2"
    gestao_repositorio_instala_resultado=$?
    if [ $gestao_repositorio_instala_resultado = 0 ] # quando o repositório é público
    then
        gestao_repositorio_instala_url=$(curl -s "https://api.github.com/repos/$1/$2/releases/latest" | grep -Po " {2}\"tarball_url\": \"\K[^\"]+(?=\",)")
        curl -LJO "$gestao_repositorio_instala_url"
    elif [ $gestao_repositorio_instala_resultado = 2 ] # quando o repositório não é público
    then
        [ -z "$gestao_repositorio_token" ] && gestao_repositorio_obtem_token
        gestao_repositorio_instala_url=$(curl -sH "Authorization: token $gestao_repositorio_token" "https://api.github.com/repos/$1/$2/releases/latest" | grep -Po " {2}\"tarball_url\": \"\K[^\"]+(?=\",)")
        curl -LJOH "Authorization: token $gestao_repositorio_token" "$gestao_repositorio_instala_url"
    else
        return 1
    fi
    gestao_repositorio_instala_versao=$(echo "$gestao_repositorio_instala_url" | grep -Po "tarball/\K[\d\.]+(?=$)")
    tar -xf "${1}-${2}-${gestao_repositorio_instala_versao}*.tar.gz"
    rm "${1}-${2}-${gestao_repositorio_instala_versao}*.tar.gz"
    mv "${1}-${2}-*/" "$3"
    if [ -d "$HOME/Scripts/" ]
    then
        [ -d "$HOME/Scripts/$3" ] && rm -r "$HOME/Scripts/$3"
    else
        mkdir "$HOME/Scripts"
    fi
    mv "$3" "$HOME/Scripts/"
    [ -d "$HOME/Scripts/.versões" ] || mkdir "$HOME/Scripts/.versões"
    echo "$gestao_repositorio_instala_versao" > "$HOME/Scripts/.versões/$2"
}
