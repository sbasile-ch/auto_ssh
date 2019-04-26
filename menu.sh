#!/bin/bash
#SERVICES=(CHD WBCK XML EWF CHCC)
SERVICES=(c:CHD w:WBCK x:XML e:EWF)

EWF_BOX=(e:ewflive__ewfweb.v4 e:bewfbeplive__chl-prod-bep e:ewflive__ewftux1)
XML_BOX=(x:xmllive__mlweb.v4 x:xmllive__xmltux. x:Xmlbeplive__chl-prod-bep.)
CHD_BOX=(c:chd3live chdweb.v4  c:chd3beplive__chdtux.)
WBCK_BOX=(w:wcklive__wck.web7 w:wckbeplive__wck2tux.)

select service in ${SERVICES[*]}
do
    category=${service/:?*/}
    service=${service/[^:]*:/}
	select box in ${CHD_BOX[*]}; do break;  done
	#case $service in
	#	CHD)
	#		select box in ${CHD_BOX[*]}; do break;  done
    #        break;;
	#	WBCK)
	#		select box in ${WBCK_BOX[*]}; do break;  done
    #        break;;
	#	XML)
	#		select box in ${XML_BOX[*]}; do break;  done
    #        break;;
	#	EWF)
	#		select box in ${EWF_BOX[*]}; do break;  done
    #        break;;
	#	*)
	#		echo "Invalid option."
    #        exit
	#esac
done
read -p "Box num: " box_num
box=${box/:?*/}
echo $service
echo $box
echo $box_num
#${HOME}/auto_ssh/assh -- -mp $service $box $box_num
