#!/usr/bin/env bash

trap 'get_term' WINCH
trap 'restore_term' SIGINT EXIT

get_term() {
	read -r lines cols < <(stty size)
	half_cols=$((cols / 2))
	half_lines=$((lines / 2))
	escape_char=$(printf "\u1b")
}

setup_term() {
	printf '\e[?1049h'
	printf '\e[?25l'
}

restore_term() {
	printf '\e[?25h'
	printf '\e[?1049l'
}


box() {
	topl=$1
	topc=$2
	botl=$3
	botc=$4
	width=$(( botc - topc ))
	height=$(( botl - topl))
	printf '\e['$topl';'$topc'H'
	printf '┏%-*s┓' "$(( width - 1 ))" | sed 's/ /━/g'
	for i in $(seq 1 $height);
	do
		printf '\e['$((topl+i))';'$topc'H'
		printf '┃%-*s┃' "$(( width - 1 ))"
	done
	printf '\e['$botl';'$topc'H'
	printf '┗%-*s┛' "$(( width - 1 ))" | sed 's/ /━/g'
}

list() {
	items=("$@")
	top=0
	current=0
	getting=1

	while [[ $getting -eq 1 ]];
	do
		screen=$(
		box 1 1 $lines $cols

		for item in $(seq 0 $((lines - 3 )));
		do
			printf '\e['$((item+2))';2H'
			printf "${items[$((item+top))]}"
		done

		printf '\e['$(($((current+2))-top))';2H'
		printf '\e[30m\e[47m'"${items[$current]}"'%-*s\e[0m' "$(( $(( cols - 2 )) - ${#items[$current]} ))"
		)

		echo "$screen" # Printing it all at once reduces jitteryness

		read -rsn1 mode
		if [[ "$mode" == "$escape_char" ]];
		then
			read -rsn2 mode
		fi
		case "$mode" in
			'[A') ((current-=1)) ;;
			'[B') ((current+=1)) ;;
			'q'|'Q') getting=0 ;;
			'') selected="${items[$current]}" && getting=0;;
		esac
		if [[ $current -le 0 ]]; then current=0; fi
		if [[ $current -ge $(( ${#items[@]} - 1 )) ]]; then current=$(( ${#items[@]} - 1 )); fi
		if [[ $((current-$((lines-3)))) -ge 0 ]]; then top=$((current-$((lines-3)))); fi
	done
}

dual_list() {
	items=("$@")
	p1_items=()
	p2_items=()
	for i in $(seq 0 2 ${#items[@]});
	do
		p1_items+=("${items[$i]}")
	done
	for i in $(seq 1 2 ${#items[@]});
	do
		p2_items+=("${items[$i]}")
	done

	top=0
	current=0
	getting=1

	while [[ $getting -eq 1 ]];
	do
		screen=$(

		# Panel 1
		box 1 1 $lines $half_cols

		for item in $(seq 0 $((lines - 3 )));
		do
			printf '\e['$((item+2))';2H'
			printf "${p1_items[$((item+top))]}"
		done

		printf '\e['$(($((current+2))-top))';2H'
		printf '\e[30m\e[47m'"${p1_items[$current]}"'%-*s\e[0m' "$(( $(( half_cols - 2 )) - ${#p1_items[$current]} ))"

		box 1 $((half_cols+1)) $lines $cols
		count=0
		while IFS= read -r line;
		do
			printf '\e['$((count+2))';'$((half_cols+2))'H'
			printf "$line"
			((count++))
		done <<<$(printf "${p2_items[$current]}" | fold -s -w "$((half_cols-2))")

		)

		echo "$screen" # Printing it all at once reduces jitteryness

		read -rsn1 mode
		if [[ "$mode" == "$escape_char" ]];
		then
			read -rsn2 mode
		fi
		case "$mode" in
			'[A') ((current-=1)) ;;
			'[B') ((current+=1)) ;;
			'q'|'Q') getting=0 ;;
			'') selected="${p1_items[$current]}" && getting=0;;
		esac
		if [[ $current -le 0 ]]; then current=0; fi
		if [[ $current -ge $(( ${#p1_items[@]} - 1 )) ]]; then current=$(( ${#p1_items[@]} - 1 )); fi
		if [[ $((current-$((lines-3)))) -ge 0 ]]; then top=$((current-$((lines-3)))); fi
	done
}

ask_text() {
	ask="$*"
	box 1 1 $lines $cols
	box $(($half_lines-1)) $((half_cols-20)) $((half_lines+1)) $((half_cols+20))
	printf '\e['$((half_lines-1))';'$((half_cols-19))'H'
	printf "$ask"
	printf '\e['$half_lines';'$((half_cols-19))'H'
        printf '\e[?25h'
        read selected
        printf '\e[?25l'
}

ask_silent() {
	ask="$*"
	box 1 1 $lines $cols
	box $(($half_lines-1)) $((half_cols-20)) $((half_lines+1)) $((half_cols+20))
	printf '\e['$((half_lines-1))';'$((half_cols-19))'H'
	printf "$ask"
	printf '\e['$half_lines';'$((half_cols-19))'H'
        printf '\e[?25h'
	selected=''
	while IFS= read -r -s -n1 char; do
	if [[ -z $char ]]; then
		break
	elif [[ "$char" == '' ]]; then
		selected="${selected:0:$((${#selected}-1))}"
	else
		selected+=$char
	fi
	printf '\e['$half_lines';'$((half_cols-19))'H'
	printf "%*s" "${#selected}" | tr ' ' '*'
	done
        printf '\e[?25l'
}

show_text() {
	show=$(echo "$*" | fold -s -w 38)
	box 1 1 $lines $cols
	show_line=$(echo "$show" | wc -l)
	box $((half_lines-1-show_line)) $((half_cols-20)) $((half_lines+1+show_lines)) $((half_cols+20))
	count=0
	while IFS= read -r line;
	do
		printf '\e['$((half_lines+count-show_line))';'$((half_cols-19))'H'
		printf "$line"
		((count++))
	done <<<"$show"
	read -rsn1
}

get_term
