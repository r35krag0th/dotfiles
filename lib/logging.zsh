blank_line() {
	echo ""
}

log() {
	echo -e "\033[1;32m[$1]\033[0m $2"
}

step_line() {
	log "${1}" "\033[33m> \033[0m${2}"
}


