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
            [Ss]* ) return 0;;
            [Nn]* ) return 1;;
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
    # Suporta, no máximo 254 opções.
    # Ex: opcoes=("Opção 1." "Opção 2."); menu_texto_simples "${opcoes[@]}"
    # Ex: menu_texto_simples "Opção 1." "Opção 2."
    
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