#!/bin/bash
#set -x


#TODO detectar trilhas de audio do arquivo pela janela
#TODO empactar rnnoise junto de alguma forma
#TODO arquivo .desktop para atalho


function testdep {
	EXECPATH="$(which $1)"
	if [ ! -x "$EXECPATH" ]
	then
		sudo apt update
		sudo apt install -u $1
	fi
}

for DEPTEST in "ffmpeg yad expect"
do
	testdep $DEPTEST
done

AUDIO="TRUE"
VIDEO="FALSE"
AUDIOTRACK=1
OVERWRITE="FALSE"

function usage {
	echo "$0 [-h] -i INPUTFILE [-o OUTPUTFILE] [-a] [-v]"
	echo "	-a	Ignorar áudio (não remover ruído)."
	echo "	-v	Remover ruído do vídeo além do áudio."
}

while getopts "hi:av" ARG; do case $ARG in
    i)
      INPUTFILE="$OPTARG"
      ;;
    a)
      AUDIO="FALSE"
      ;;
    v)
      VIDEO="TRUE"
      ;;
    h)
      usage
      exit 0
      ;;
  esac
done

TMPDIR="./tmp$$"

function mktemp {
	if [[ ! -d $TMPDIR ]]
	then
		mkdir $TMPDIR 
	fi
}


function tryvideo {
	if [[ "$VIDEO" == "TRUE" ]]
	then
		ffmpeg -i "$INPUTFILE" -vf hqdn3d -c:v libx265 -an -crf 28 "$TMPDIR/$$.mp4"
		if [[ "$?" -ne 0 ]]
		then
			displayerror "Erro ao tentar remover ruído do vídeo."
		fi
	else
		ffmpeg -i "$INPUTFILE" -an -c:v copy "$TMPDIR/$$.mp4"
		if [[ "$?" -ne 0 ]]
		then
			displayerror "Erro ao tentar extrair o vídeo."
		fi
	fi
}

function tryaudio {
	ffmpeg -i "$INPUTFILE" -map $AUDIOTRACK:a:0 "$TMPDIR/$$.wav"
	if [[ "$?" -ne 0 ]]
	then
		displayerror "Erro extraindo áudio do vídeo selecionado.\nO número da trilha de áudio estava correto?"
	fi
	if [[ "$AUDIO" == "TRUE" ]]
	then
		expect -c "spawn rnnoise \"$TMPDIR/$$.wav\" \"$TMPDIR/$$.denoised.wav\"; expect \"exit.\"; send \n"
		mv $TMPDIR/$$.denoised.wav $TMPDIR/$$.wav
	fi
}

function remux {
	if [[ "$OVERWRITE" == "TRUE" ]]
	then
		ffmpeg -i "$TMPDIR/$$.mp4" -i "$TMPDIR/$$.wav" -y "${INPUTFILE%.*}".CLEAN.mp4
	else
		ffmpeg -i "$TMPDIR/$$.mp4" -i "$TMPDIR/$$.wav" -n "${INPUTFILE%.*}".CLEAN.mp4
	fi
	if [[ "$?" -ne 0 ]]
	then
		displayerror "Erro ao criar o novo arquivo com áudio e vídeo."
	fi
}

function cleanup {
	if [[ -d $TMPDIR ]]
	then
		rm -rf $TMPDIR 
	fi
}

function runvideo {
	if [[ "$RUNVIDEO" == "TRUE" ]]
	then
		if [[ -f "${INPUTFILE%.*}.CLEAN.mp4" ]]
		then
			xdg-open "${INPUTFILE%.*}.CLEAN.mp4"
		fi
	fi
}

function displaywindow {
	SELECTIONS=$(yad --border=15 --form --width="300" --height="50" --center --title "Removedor de Ruído" --text="As opções a seguir controlam de onde tentar retirar o ruído. Escolher a trilha de áudio pode ser útil para vídeos gravados no OBS. Selecionar a remoção de ruído pode causar demora e a imagem pode ficar \"estranha\". É necessário selecionar o vídeo a processar e então o botão \"Iniciar\"" --field="Processar áudio:CHK" --field="Trilha selecionada:NUM" --field="Processar vídeo:CHK" --field="Vídeo com ruído:FL" --field="Rodar novo vídeo no final:CHK" --button="Iniciar!gtk-ok" --button="Cancelar!gtk-close" true 1\!1..6 false false)
	if [[ $? -ne 0 ]]
	then
		exit 0
	fi
	AUDIO=$(echo $SELECTIONS | cut -d '|' -f1)
	AUDIOTRACK=$(( $(echo $SELECTIONS | cut -d '|' -f2) -1 ))
	VIDEO=$(echo $SELECTIONS | cut -d '|' -f3)
	INPUTFILE=$(echo $SELECTIONS | cut -d '|' -f4)
	RUNVIDEO=$(echo $SELECTIONS | cut -d '|' -f5)

	if [[ -z "$INPUTFILE" ]]
	then
		yad --title="Removedor de Ruído" --borders=15 --image=error --text="Você não selecionou nenhum vídeo para processar.\nTente novamente." --text-align=center --button=gtk-ok
		exit 1
	fi
}

function displayerror {
		yad --title="Removedor de Ruído" --borders=15 --image=error --text="$1" --text-align=center --button=gtk-ok
		cleanup
		exit 1
}

function displaydone {
		yad --title="Removedor de Ruído" --borders=15 --center --text="Concluído." --text-align=center --button=gtk-ok
		cleanup
		exit 1
}

function askoverwrite {
		if [[ -f "${INPUTFILE%.*}.CLEAN.mp4" ]]
		then
			yad --title="Removedor de Ruído" --borders=15 --image=error --center --text="Já existe um arquivo ${INPUTFILE%.*}.CLEAN.mp4.\nSobrescrever?" --text-align=center --button='Sim!gtk-yes:0' --button='Não!gtk-no:1'	
			if [[ $? -eq 0 ]]
			then
				OVERWRITE="TRUE"
			else
				exit 1
			fi
		fi
}

displaywindow
askoverwrite
mktemp
tryaudio | yad --title="Removedor de Ruído" --borders=15 --center --progress --pulsate --auto-close --progress-text="Trabalhando no som..." --no-buttons
tryvideo | yad --title="Removedor de Ruído" --borders=15 --center --progress --pulsate --auto-close --progress-text="Trabalhando no vídeo..." --no-buttons
remux | yad --title="Removedor de Ruído" --borders=15 --center --progress --pulsate --auto-close --progress-text="Criando novo arquivo..." --no-buttons
cleanup 
displaydone
runvideo


exit 0
