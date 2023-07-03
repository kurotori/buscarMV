#!/bin/bash
clear

source ./funciones.sh

### Variables Auxiliares
error=0
interf_red=""
usuario="$USER"
id_usuario="$UID"


#### Funciones Auxiliares ####
#---Formatos del texto
BLACK=$(tput setaf 0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
LIME_YELLOW=$(tput setaf 190)
POWDER_BLUE=$(tput setaf 153)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)
BRIGHT=$(tput bold)
NORMAL=$(tput sgr0)	
BLINK=$(tput blink)
REVERSE=$(tput smso)
UNDERLINE=$(tput smul)

#----


#----
opciones=100
#TODO: Completar el bucle principal para permitir selección de opciones
# y permitir la recuperación de un sistema previo.
while [ "$opciones" -eq 100 ]; do
    banner
    printf "%1s\n" "${LIME_YELLOW}            Elija una opción:${NORMAL}"
    printf "%1s\n" "${BRIGHT}------------------------------------------------${NORMAL}"
    echo ""
    printf "%1s\n" "${LIME_YELLOW}            1- Configurar un equipo nuevo${NORMAL}"
    printf "%1s\n" "${LIME_YELLOW}            2- Restaurar un equipo desde el Servidor${NORMAL}"
    printf "%1s\n" "${LIME_YELLOW}            3- Salir${NORMAL}"
    read -r opciones

    case "${opciones}" in
        1)
            
            paquetes=("nmap" "cifs-utils" "rsync" "cairosvg")
            for i in "${!paquetes[@]}"
            do
                banner
                printf "%1s\n" "${LIME_YELLOW}            Chequeando software necesario${NORMAL}"
                printf "%1s\n" "${BRIGHT}------------------------------------------------${NORMAL}"
                echo ""
                num=$((i+1))
                printf "%1s\n" "      $num - ${BRIGHT}${paquetes[$i]}${NORMAL}"
                echo ""
                sudo apt -y install "${paquetes[$i]}"
                sleep 1
            done

            banner
            printf "%1s\n" "${LIME_YELLOW}            Configurando el sistema ${NORMAL}"
            printf "%1s\n" "${BRIGHT}------------------------------------------------${NORMAL}"
            echo ""
            echo "  1 - Creando carpetas auxiliares"

            echo "  Carpeta $ruta_local/config..."
            if [ ! -d config ]
            then
                mkdir config
            fi
            echo "...Listo"

            echo "  Carpeta $ruta_local/datos..."
            if [ ! -d datos ]
            then
                mkdir datos
            fi
            echo "...Listo"

            sleep 1
            echo "      ... Listo"
            echo ""
            echo "  2 - Generando ID Única del Sistema"
            if [ ! -a config/ID.txt ]
            then
                touch config/ID.txt
                uuid=$(uuidgen)
                uuid=${uuid^^}
                echo "$uuid" > config/ID.txt
            fi
            sleep 1
            echo "      ... Listo"
            sleep 1

            seleccion=100

            while [ "$seleccion" -eq 100 ]; do
                banner
                echo "  3 - Registrando equipo con el servidor de respaldos"
                echo ""

                echo "      Por favor indique la interfáz de red a usar:"

                #Obteniendo interfaces de red
                interfaces=()
                for dato in $(ip address | grep "^[0-9].*" | cut -d ":" -f 2)
                do 
                    interfaces+=("$dato")
                done

                #Listando interfaces de red
                for i in "${!interfaces[@]}"
                do
                    num=$((i+1))
                    echo "            $num - ${interfaces[$i]}"
                done

                num_interfaces=${#interfaces[@]}

                echo ""
                read -r seleccion
                seleccion=$((seleccion-1))

                case  1:${seleccion:--} in
                    (1:*[!0-9]*|1:0*[89]*)
                    ! echo "      ${seleccion} no es un valor válido"; seleccion=100
                    ;;
                    ($((seleccion<=num_interfaces))*)
                        item=${interfaces[$seleccion]}
                        #echo "Seleccionó $item"
                        
                    ;;
                    ($((seleccion>num_interfaces))*)
                        echo "      ${seleccion} no es un valor válido"
                        seleccion=100
                    ;;
                esac
                #sleep 2

            

                echo "${interfaces[$seleccion]}" > config/interfaz.txt
                interf_red=${interfaces[$seleccion]}

                #printf "%1s\n" "      Se ha seleccionado la interfáz:  ${BRIGHT}${interfaces[$seleccion]}${NORMAL}"
                
            done

            banner
            printf "%1s\n" "      Se ha seleccionado la interfáz:  ${BRIGHT}${interf_red}${NORMAL}"

            #rango=$(ip a show ${interfaces[$seleccion]})
            #echo "dato red: ${dato}"
            echo ""
            echo "      Obteniendo parámetros de la red con la interfáz seleccionada..."
            rango=$(rango_red "$interf_red")
            sleep 2
            echo "      ...Listo."
            echo ""

            printf "%1s\n" "      Rango de red:  ${BRIGHT}${rango}${NORMAL}"

            sleep 2
            echo ""
            printf "%1s\n" "     ${YELLOW}Por favor indique la dirección MAC del servidor de respaldos:${NORMAL}"
            # echo "      Por favor indique la dirección MAC del servidor de respaldos:"
            echo "      (formato: xx:xx:xx:xx:xx:xx)"
            echo ""

            read -r mac_disp
            echo "$mac_disp" > config/macServidor.txt
            echo ""

            printf "%1s\n" "      Ubicando al servidor  ${BRIGHT}${mac_disp}${NORMAL} en la red..."
            echo ""
            echo "      Escaneando la red en busca del servidor."
            buscar_h "$rango" "$mac_disp" & PID=$! #simulate a long process
            echo "      Por favor espere..."
            printf "      "
            # While process is running...
            while kill -0 $PID 2> /dev/null; do 
                printf  "▓"
                sleep 1
            done
            printf ""

            echo "    ...Escaneo Completo"
            #Código de animación de espera tomado del usuario cosbor11 de stackoverflow.com
            #Obtenido de https://stackoverflow.com/questions/12498304/using-bash-to-display-a-progress-indicator
            sleep 2

            banner
            ip_servidor=$(cat config/ip_servidor.txt)
            echo ""
            printf "%1s\n" "      IP del servidor:  ${BRIGHT}${ip_servidor}${NORMAL}"

            echo ""
            echo "      Accediendo a la carpeta de respaldos del servidor..."

            id=$(cat config/ID.txt)
            #echo "usuario actual: $USER"
            #sudo mount -t cifs //"${ip_servidor}"/respaldos /media/"$usuario"/servidorR
            dirRespaldo="smb://${ip_servidor}/respaldos"

            gio mount -a "$dirRespaldo"    #smb://"${ip_servidor}"/respaldos
            sleep 1
            echo "      ... Listo"

            echo ""
            echo "      Registrando PC en el servidor..."
            # --> Revisar este artículo: https://askubuntu.com/questions/1021643/how-to-specify-a-password-when-mounting-a-smb-share-with-gio

            gio mkdir "$dirRespaldo"/"${id}"
            gio mkdir "$dirRespaldo"/"${id}"/config
            gio mkdir "$dirRespaldo"/"${id}"/datos
            gio mkdir "$dirRespaldo"/"${id}"/registro


            sleep 1
            echo "      ... Listo"

            # Creación de ID imprimible
            touch "$ruta_local/config/ID.svg"
            cat encabezado_ID.txt > "$ruta_local/config/ID.svg"
            echo "${id}" >> "$ruta_local/config/ID.svg"
            cat final_ID.txt >> "$ruta_local/config/ID.svg"
            #mogrify -format png -- ID.svg
            cairosvg -f pdf -o "$ruta_local/config/ID.pdf" "$ruta_local/config/ID.svg"

            banner
            printf "%1s\n" "      ID:  ${BRIGHT}${id}${NORMAL}"
            echo "      ID imprimible creada"
            printf "%1s\n" "${LIME_YELLOW}            ATENCION:${NORMAL}"
            printf "%1s\n" "${LIME_YELLOW}            IMPRIMA el documento que aparecerá en pantalla. ${NORMAL}"
            printf "%1s\n" "${LIME_YELLOW}            Esa es la ID que permitirá restaurar el Sistema. ${NORMAL}"
            espere
            xdg-open "$ruta_local/config/ID.pdf"

            banner
            printf "%1s\n" "${YELLOW}            Creando subrutina de respaldo${NORMAL}"
            echo "00 23 * * 5 $ruta_local/autorespaldo.sh" > cronrespaldo
            crontab cronrespaldo


            # Configuración de archivos no incluídos
            excluidos="*.exe\n,*.mp*\n,*.iso\n,*.aac\n,*.avi\n,*.mkv"
            opcion=100

            while [ "$opcion" -eq 100 ]; do

                banner
                printf "%1s\n" "${BRIGHT}            Tipos de archivos exluidos del respaldo:${NORMAL}"
                echo "      "
                
                echo -e "${excluidos}"
                printf "%1s\n" "${BRIGHT}            ¿Desea modificar la lista? ${NORMAL}"
                printf "%1s\n" "${BRIGHT}            1 - Añadir un tipo a la lista ${NORMAL}"
                printf "%1s\n" "${BRIGHT}            2 - Quitar todos los tipos de la lista ${NORMAL}"
                printf "%1s\n" "${BRIGHT}            3 - Guardar la lista ${NORMAL}"
                
                read -r opcion
                case "${opcion}" in
                    1)
                        printf "%1s\n" "${BRIGHT}            Tipo de archivo a excluir (solo la extensión, sin puntos ni símbolos): ${NORMAL}"
                        read -r tipo
                        if [ $(echo "$tipo"|grep -c -e "[\*\.]") -gt 0 ]
                        then
                            echo "Valor no válido. Intente nuevamente"
                        else
                            excluidos="$excluidos\n*.$tipo"
                            echo "Se agregó el tipo *.${tipo} a la lista de archivos excluidos"
                            espere
                        fi
                        espere
                        opcion=100
                    ;;
                    2)
                        excluidos=""
                        opcion=100
                    ;;
                    3)
                        
                        echo -e "${excluidos}" > "$ruta_local/config/excluidos.txt"
                        #Se agrega esta línea al archivo de excluidos para evitar que se respalde la carpeta de cache del usuario
                        echo ".cache/" >> "$ruta_local/config/excluidos.txt"

                        echo "            Archivos excluidos configurados"

                        #Respaldo de la configuración de archivos excluidos en el servidor de respaldo
                        gio copy "$ruta_local"/config/excluidos.txt "$dirRespaldo"/"${id}"/config/excluidos.txt
                        espere
                    ;;
                    *)
                        echo "OPCIÓN NO VÁLIDA"
                        espere
                    ;;
                esac
                
            done

            #Finalizar la configuración y realizar el primer respaldo
            # Desmontado de unidad remota
            gio mount -u "$dirRespaldo"
            bash "$ruta_local"/autorespaldo.sh

            banner
            printf "%1s\n" "${BRIGHT}            La configuración del sistema se completó con éxito${NORMAL}"
            echo "      "
            espere
        ;;
        2)
            
        ;;
        3)
            opciones=1
        ;;
        *)
            echo "Opción No Válida"
            opciones=100
            espere
        ;;
    esac
    

done

