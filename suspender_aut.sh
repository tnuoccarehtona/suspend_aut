#!/bin/bash

if [ -r /etc/default/suspender_aut ]; then
	. /etc/default/suspender_aut
fi

if [ -z "$LOCKER_APP" ] || [ -z "$LOCKER_COMMAND" ] || [ -z "$SUSPEND_COMMAND" ];then
	LOCKER_APP="/usr/bin/gnome-screensaver"
	APP_ARGS=
	LOCKER_COMMAND="/usr/bin/gnome-screensaver-command -a"
	SUSPEND_COMMAND="dbus-send --system --print-reply  --dest=\"org.freedesktop.UPower\" /org/freedesktop/UPower org.freedesktop.UPower.Suspend"
	echo ADVERTENCIA: USANDO COMANDOS DE LOCKER POR DEFECTO
fi

tiempo_espera= activacion= powerofftime= antikiller=
killnow=0

ayuda()
{
echo uso: suspender_aut.sh [OPCIONES]
echo "-h Ayuda"
echo "-t Numero. Demora en minutos para activar la autosuspension y/o ${LOCKER_APP##*/}, puedes colocar 0 para desactivar la demora."
echo "-a Numero:"
echo " 0 Desactiva xautolock, ignorando completamente a ${LOCKER_APP##*/}"
echo " 1 desactiva xautolock y ${LOCKER_APP##*/}"
echo " 2 desactiva xautolock y activa ${LOCKER_APP##*/}"
echo " 3 desactiva ${LOCKER_APP##*/} y activa xautolock con autosuspension"
echo " 4 activa xautolock con bloqueo de pantalla y autosuspension"
echo " 5 activa xautolock con solo bloqueo de pantalla"
echo " 6 activa xautolock con autosuspension ignorando completamente a ${LOCKER_APP##*/}"
echo "-p Numero. Demora en minutos para apagar la pantalla. Puede Colocar cero para prevenir el apagado de la pantalla. Coloque \"s\" para dejar el ajuste anterior o el del sistema o Coloque \"d\" para desactivar las Opciones de energia."
echo "-k Detener xautolock (pero no ${LOCKER_APP##*/})"
}
execxautolock()
{
if [ -n "$SUSPEND_COMMAND" ]; then
	if [ "$1" != "0" ]; then
		xautolock -time $1 -detectsleep -locker "$SUSPEND_COMMAND"  &
	else
		echo "Advertencia: El valor del tiempo de espera es 0 !!"
		echo "Xautolock desactivado !!"
	fi
else
	echo La variable SUSPEND_COMMAND no tiene ningun valor.
fi
}
execxautolockandlocker()
{
if [ -n "$SUSPEND_COMMAND" ]; then
	if [ "$1" != "0" ]; then
		xautolock -time $1 -detectsleep -locker "$LOCKER_COMMAND ; sleep 4 ; $SUSPEND_COMMAND"  &
	else
		echo "Advertencia: El valor del tiempo de espera es 0 !!"
		echo "Xautolock desactivado !!"
	fi
else
	echo La variable SUSPEND_COMMAND no tiene ningun valor.
fi
}
execxautolockwosuspend()
{
if [ "$1" != "0" ]; then
	xautolock -time $1 -detectsleep -locker "$LOCKER_COMMAND"  &
else
	echo "Advertencia: El valor del tiempo de espera es 0 !!"
	echo "Xautolock desactivado !!"
fi
}
screensaverdisabled()
{
if [ -n "$LOCKER_APP" ]; then
	killall -9 ${LOCKER_APP##*/} 2>/dev/null
else
	echo La variable LOCKER_APP no tiene ningun valor.
fi
}
screensaverenabled()
{
if [ -n "$LOCKER_APP" ]; then
	if ! pidof $LOCKER_APP >/dev/null ;then   
		$LOCKER_APP $APP_ARGS 2>/dev/null&
	fi
else
	echo La variable LOCKER_APP no tiene ningun valor.
fi
}
xsetpoweroff()
{
xset +dpms
xset dpms 0 0 0
xset dpms 0 0 $(($1 * 60)) &
}

while getopts khp:a:t: opt; do
  case $opt in
  a)
      if [ "$OPTARG" -ge "0" ] && [ "$OPTARG" -le "6" ] 2>/dev/null; then
	mkdir ~/.suspender_aut 2>/dev/null
	echo $OPTARG > ~/.suspender_aut/.activation_status
      else
	echo -a solo acepta 0 , 1 , 2 , 3 , 4 , 5 o 6
        exit 1
      fi
      ;;
  t)
      if [ "$OPTARG" -gt -1 ] 2>/dev/null; then
	mkdir ~/.suspender_aut 2>/dev/null
	echo $OPTARG > ~/.suspender_aut/.idle_time
      else
	echo -t solo acepta cero o numeros positivos
        exit 1
      fi
      ;;
  h)
	ayuda
	exit 0
      ;;
  p)
      if [ "$OPTARG" == "s" ]  || [ "$OPTARG" == "d" ] || [ "$OPTARG" -gt -1 ]  2>/dev/null; then
  	mkdir ~/.suspender_aut 2>/dev/null
	echo $OPTARG > ~/.suspender_aut/.poweroff_time
      else
	echo -p solo acepta 0 , numeros positivos, s o d
        exit 1
      fi
      ;;
  k)  
	killnow=1
      ;;
  ?)
	ayuda     
	exit 1
      ;;
 esac
done


if [ -n "$1" ] && [[ "$1" != -* ]]; then
ayuda
exit 1
fi

if [ "$#" -eq 0 ] || [ "$killnow" == "1" ] ; then
	echo procesando cambios
	killall -9 xautolock  2>/dev/null
	activacion=$(head -c -1 ~/.suspender_aut/.activation_status 2>/dev/null)
	tiempo_espera=$(head -c -1 ~/.suspender_aut/.idle_time 2>/dev/null)
	powerofftime=$(head -c -1 ~/.suspender_aut/.poweroff_time 2>/dev/null)

	if [ -z "$activacion" ]; then 
		activacion=4
	fi

	if [ -z "$tiempo_espera" ]; then 
		tiempo_espera=5
	fi

	if [ -z "$powerofftime" ]; then 
		powerofftime=s
	fi

	if [ "$killnow" == "1" ]; then 

		exit 0
	fi

	case $activacion in
	
		0) 
		;;

		1)
		screensaverdisabled  
		;;

		2)
		screensaverenabled
		;;

		3) 
		screensaverdisabled
		execxautolock $tiempo_espera
		;;

		4)  
		screensaverenabled
		execxautolockandlocker $tiempo_espera
		;;

 		5)
		screensaverenabled
		execxautolockwosuspend $tiempo_espera
		;;

 		6)
		execxautolock $tiempo_espera
		;;

 		?)  
		;;

	esac
        
	case $powerofftime in
	
		s)  
		;;

 		d)  
		xset -dpms
		;;

 		?)
		xsetpoweroff $powerofftime
		;;

	esac

else

	$0 &
	sleep 3
	exit 0

fi

