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