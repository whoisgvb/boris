#!/usr/bin/env bash

# Autor Gustavo Vilela #
# Escrito em 07 - 2020 #
# gvbsec arrob@ protonmail.com #



# SCRIPT PRA AUTOMATIZAR AS PARTES CHATAS ZZZ Testado no Kali Linux =)
# USO $ ./script.sh     <dominio>   <caminho_saida>
# EX sudo  ./script.sh google.com /home/gvb/Documents/


# VERIFICACOES #
[ -z $1 ]                           && echo "Primeiro parametro vazio, saindo ..." && exit 1;
[ -z "$(ping $1 -c1) 2>/dev/null" ] && echo -e "o dominio $1 não responde =(" && exit 1;
[ -z $2 ]                           && echo "Segundo parametro está vazio, saindo ..." && exit 1;
[ ! -x $(which git) ]               && sudo apt-install git -y
[ ! -x $(which seclists) ]          && git clone https://github.com/danielmiessler/SecLists.git
[ ! -x $(which gobuster) ]          && sudo apt-get install gobuster -y
[ ! -x $(which wfuzz) ]             && sudo apt-get install wfuzz -y
[ ! -x $(which nikto) ]             && sudo apt-get install nikto -y
[ ! -x $(which wpscan) ]            && git clone https://github.com/wpscanteam/wpscan.git
[ ! -x $(which theharvester) ]      && sudo apt-get install theharvester

VERSAO="v.1"
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
NC='\033[0m'
BD='\033[36;1;5m'

dom="$1"
dir="$2$1"
ip="$(dig +short $1 | head -1)"
PL="$(sleep 0.3 && echo -e '\n\n')"


# Verificação para executar com SUDO
if [ $(whoami) != 'root' ]; then
	echo -e "${RED}Executa novamente o '$(basename $0)' com sudo :P${NC}"
	exit 1;
fi

# Verificação para criação do diretório
if [ -d "$dir" ]; then
  echo -e "${YELLOW}Diretório '$1' já existe em '$2'${NC}"
  echo -e "${YELLOW}Não é aconselhável colocar novas saidas sobre os mesmos arquivos${NC}"
  exit 1;
else
  mkdir "$dir"
fi

banner(){
echo -e "${RED}"
echo -e "██████╗  ██████╗ ██████╗ ██╗███████╗"
echo -e "██╔══██╗██╔═══██╗██╔══██╗██║██╔════╝"
echo -e "██████╔╝██║   ██║██████╔╝██║███████╗"
echo -e "██╔══██╗██║   ██║██╔══██╗██║╚════██║"
echo -e "██████╔╝╚██████╔╝██║  ██║██║███████║"
echo -e "╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚═╝╚══════╝"
echo -e "${NC}# Written with love ♥ by GVB | ${BD}$VERSAO${NC} #"

}

checaOS(){
  ttl="$(cat $dir/ping.txt | grep ttl | head -1 | cut -d " " -f 7 | cut -d "=" -f 2)"
  if [ "$ttl" -eq 256 ] || [ "$ttl" -eq 255 ] || [ "$ttl" -eq 254 ]; then
        echo "Provavelmente o ambiente roda OpenBSD/Cisco/Oracle" >> "$dir"/ping.txt
  elif [ "$ttl" -eq 128 ] || [ "$ttl" -eq 127 ]; then
        echo "Provavelmente o ambiente roda Windows" >> "$dir"/ping.txt
  elif [ "$ttl" -eq 64 ] || [ "$ttl" -eq 63 ]; then
        echo "Provavelmente o ambiente roda Linux" >> "$dir"/ping.txt
  else
        echo "Não consegui identificar o sistema através do TTL Sr. =(" >> "$dir"/ping.txt
  fi
  
}

scanlight(){
  # Execução das ferramentas básicas
  echo -e "${GREEN}[ + ] Executando HOST >${NC}\n"
  host $dom | tee "$dir"/host.txt
  sleep 0.5
  host -aCdilrTvVw $dom >> "$dir"/host.txt
  echo "$PL"

  echo -e "${GREEN}[ + ] Executando TRACEROUTE >${NC}\n"
  traceroute "$ip" | tee "$dir"/traceroute.txt
  echo "$PL"

  echo -e "${GREEN}[ + ] Executando PING >${NC}\n"
  ping "$dom" -c 1 -W 3| tee "$dir"/ping.txt
  checaOS
  echo "$PL"

  echo -e "${GREEN}[ + ] Executando NSLOOKUP >${NC}\n"
  nslookup "$dom" | tee $dir/nslookup.txt
  echo "$PL"


  echo -e "${GREEN}[ + ] Executando WHOIS >${NC}\n"
  whois $dom | tee "$dir"/whois.txt
  echo "$PL"

  echo -e "${GREEN}[ + ] Executando DIG >${NC}\n"
  dig $dom +cmd | tee "$dir"/dig.txt
  echo "$PL"

  echo -e "${GREEN}[ + ] Executando NMAP nas 1000 portas comuns >${NC}\n"
  nmap --top-ports 1000 -Pn $ip -T3 -oG "$dir"/nmap_grep_top1000.txt -oX "$dir"/nmap_xml_top1000.txt | tee "$dir"/nmap_top1000.txt
  echo "$PL"

  # echo -e "${GREEN}[ + ] Executando THE DNS ENUM >${NC}\n"
  # dnsenum $dom --enum --noreverse | tee "$dir"/dnsenum.txt
  # echo "$PL"

}

scanfat(){
  # Execução das ferramentas intrusivas
  echo -e "${GREEN}[ + ] Executando THE HARVESTER >${NC}\n"
  theHarvester -d $dom -s -n -c -b all | tee "$dir"/theharvester.txt
  echo "$PL"

  echo -e "${GREEN}[ + ] Executando NMAP em todas as portas >${NC}\n"
  nmap -sC -p- -Pn $ip -T3 -oG "$dir"/nmap_grep_full.txt -oX "$dir"/nmap_xml_full.txt | tee "$dir"/nmap_full.txt

  echo -e "${GREEN}[ + ] Executando GO BUSTER >${NC}\n"
  gobuster dns -d "$dom" -w /usr/share/wordlists/dirb/common.txt --wildcard | tee "$dir"/gobuster.txt
  echo "$PL"

  echo -e "${GREEN}[ + ] Executando WFUZZ >${NC}\n"
  wfuzz -w /usr/share/seclists/Discovery/Web-Content/common.txt -u https://"$dom"/FUZZ --hc 404,301 | tee "$dir"/wfuzz.txt
  echo "$PL"

  echo -e "${GREEN}[ + ] Executando NIKTO >${NC}\n"
  nikto -host https://"$dom" -C all | tee "$dir"/nikto.txt
  echo "$PL"

}

scanwordpress(){
  # Execução das ferramentas para Wordpress
  req="$(curl -s https://'$dom' | egrep -i '(wp-content|wordpress)')"
  if [ "$req" ]; then
    echo -e "${GREEN}[ + ]  Wordpress foi encontrado!${NC}\n"
    sleep 0.3
    echo -e "${GREEN}[ + ] Executando WPSCAN >${NC}\n"
    wpscan  --url "$dom" | tee "$dir"/wpscan.txt
     echo "$PL"
    
    echo -e "${GREEN}[ + ] Executando WFUZZ para diretórios do Wordpress >${NC}\n"
    wfuzz -w /usr/share/seclists/Discovery/Web-Content/CMS/wordpress.fuzz.txt -u https://"$dom"/FUZZ --hc 404,301 | tee "$dir"/wfuzz_wordpress.txt
    echo "$PL"

  fi
}



# Verificação das opções
banner
#        ------------------------------------
echo     ""
echo     "**** ****** Escolha uma ****** ****"
echo -ne " 1- Scan LIGHT | 2- Scan INTRUSIVO:  "
read op

case "$op" in
  1) 
  scanlight
  scanwordpress
  echo -e "${GREEN}[ + ] Scan light completo *_*${NC}\n";;
  2)
  scanlight
  scanfat
  scanwordpress
  echo -e "${GREEN}[ + ] Scan intrusivo completo *_*{$NC}\n";;
  *) 
  echo -e "${RED}OPÇÃO INVÁLIDA! ! ! Escolha novamente!${NC}\n"
  [ ! "$(ls -A $dir)" ] && rm -Rf "$dir"
  exit 1;;
esac


for i in $(ls "$dir"/*.txt); 
do
 tam="$(stat -c%s $i)"
 if [ "$tam" -eq 0 ]; then
 echo -e "Arquivo '$i' está vazio =(\nTente rodar o comando manualmente depois =)"
 fi
done




