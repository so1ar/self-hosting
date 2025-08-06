#!/bin/bash

########## CONFIGURATIONS ##########
# Host on which qBittorrent runs
qbt_host="http://qbittorrent"
# Port -> the same port that is inside qBittorrent option -> Web UI -> Web User Interface
qbt_port="8080"
# Username to access to Web UI
qbt_username="admin"
# Password to access to Web UI
qbt_password="adminadmin"

# If true (lowercase) the script will inject trackers inside private torrent too (not a good idea)
ignore_private=false

# If true (lowercase) the script will remove all existing trackers before inject the new one, this functionality will works only for public trackers
clean_existing_trackers=false

# Configure here your trackers list
declare -a live_trackers_list_urls=(
	"https://bitbucket.org/xiu2/trackerslistcollection/raw/master/best.txt"
	)
########## CONFIGURATIONS ##########

jq_executable="$(command -v jq)"
curl_executable="$(command -v curl)"
auto_tor_grab=0
test_in_progress=0
applytheforce=0
all_torrent=0
emptycategory=0

if [[ -z $jq_executable ]]; then
	echo -e "\n\e[0;91;1mFail on jq. Aborting.\n\e[0m"
	echo "You can find it here: https://stedolan.github.io/jq/"
	echo "Or you can install it with -> sudo apt install jq"
	exit 1
fi

if [[ -z $curl_executable ]]; then
	echo -e "\n\e[0;91;1mFail on curl. Aborting.\n\e[0m"
	echo "You can install it with -> sudo apt install curl"
	exit 2
fi

if [[ $qbt_host == "https://"* ]]; then
	curl_executable="${curl_executable} --insecure"
fi

version="v3.16"

STATIC_TRACKERS_LIST=$(
    cat <<'EOL'
http://0123456789nonexistent.com:80/announce
http://1337.abcvg.info:80/announce
http://bt.okmp3.ru:2710/announce
http://ipv4.rer.lol:2710/announce
http://ipv6.rer.lol:6969/announce
http://nyaa.tracker.wf:7777/announce
http://shubt.net:2710/announce
http://taciturn-shadow.spb.ru:6969/announce
http://tk.greedland.net:80/announce
http://torrentsmd.com:8080/announce
http://tracker.beeimg.com:6969/announce
http://tracker.bt4g.com:2095/announce
http://tracker.ipv6tracker.ru:80/announce
http://tracker.mywaifu.best:6969/announce
http://tracker.netmap.top:6969/announce
http://tracker.privateseedbox.xyz:2710/announce
http://tracker.renfei.net:8080/announce
http://www.all4nothin.net:80/announce.php
http://www.wareztorrent.com:80/announce
https://1337.abcvg.info:443/announce
https://opentracker.8880085.xyz:443/announce
https://pybittrack.retiolus.net:443/announce
https://t.213891.xyz:443/announce
https://tr.abiir.top:443/announce
https://tr.abir.ga:443/announce
https://tr.nyacat.pw:443/announce
https://tracker.aburaya.live:443/announce
https://tracker.expli.top:443/announce
https://tracker.foreverpirates.co:443/announce
https://tracker.jdx3.org:443/announce
https://tracker.kuroy.me:443/announce
https://tracker.moeblog.cn:443/announce
https://tracker.yemekyedim.com:443/announce
https://tracker.zhuqiy.top:443/announce
https://tracker1.520.jp:443/announce
udp://1c.premierzal.ru:6969/announce
udp://bt.ktrackers.com:6666/announce
udp://d40969.acod.regrucolo.ru:6969/announce
udp://evan.im:6969/announce
udp://exodus.desync.com:6969/announce
udp://extracker.dahrkael.net:6969/announce
udp://martin-gebhardt.eu:25/announce
udp://open.demonii.com:1337/announce
udp://open.stealth.si:80/announce
udp://open.tracker.cl:1337/announce
udp://opentor.org:2710/announce
udp://opentracker.io:6969/announce
udp://p4p.arenabg.com:1337/announce
udp://retracker.hotplug.ru:2710/announce
udp://retracker.lanta.me:2710/announce
udp://retracker01-msk-virt.corbina.net:80/announce
udp://tracker-udp.gbitt.info:80/announce
udp://tracker.bitcoinindia.space:6969/announce
udp://tracker.bittor.pw:1337/announce
udp://tracker.dler.com:6969/announce
udp://tracker.dler.org:6969/announce
udp://tracker.filemail.com:6969/announce
udp://tracker.fnix.net:6969/announce
udp://tracker.gigantino.net:6969/announce
udp://tracker.gmi.gd:6969/announce
udp://tracker.hifimarket.in:2710/announce
udp://tracker.hifitechindia.com:6969/announce
udp://tracker.opentrackr.org:1337/announce
udp://tracker.plx.im:6969/announce
udp://tracker.qu.ax:6969/announce
udp://tracker.rescuecrew7.com:1337/announce
udp://tracker.skillindia.site:6969/announce
udp://tracker.skyts.net:6969/announce
udp://tracker.srv00.com:6969/announce
udp://tracker.theoks.net:6969/announce
udp://tracker.therarbg.to:6969/announce
udp://tracker.torrent.eu.org:451/announce
udp://tracker.torrust-demo.com:6969/announce
udp://tracker.tryhackx.org:6969/announce
udp://tracker.tvunderground.org.ru:3218/announce
udp://tracker.valete.tf:9999/announce
udp://tracker.yume-hatsuyuki.moe:6969/announce
udp://tracker2.dler.org:80/announce
udp://ttk2.nbaonlineservice.com:6969/announce
udp://udp.tracker.projectk.org:23333/announce
udp://www.torrent.eu.org:451/announce
wss://tracker.openwebtorrent.com:443/announce
EOL
)

########## FUNCTIONS ##########
generate_trackers_list () {
    # If trackers_list is already populated, do nothing and return
    if [[ -n "$trackers_list" ]]; then
        echo "Trackers list already populated. Skipping generation."
        return
    fi

    trackers_list="" # Local variable for dynamic trackers
    all_failed=true  # Assume that all URLs fail

    # 1. Check if the list of URLs is empty
    if [[ ${#live_trackers_list_urls[@]} -eq 0 ]]; then
        echo "No live tracker URLs provided. Using the static list."
        trackers_list="$STATIC_TRACKERS_LIST"
        return
    fi

    # 2. Attempts to download trackers from each URL
    for url in "${live_trackers_list_urls[@]}"; do
        echo "Fetching trackers from: $url"
        # Download data, silently
        new_trackers=$($curl_executable -sS "$url")
        if [[ $? -eq 0 && -n "$new_trackers" ]]; then
            # If the download was successful, add the new trackers to trackers_list
            trackers_list+="$new_trackers"$'\n'
            all_failed=false # At least one URL worked
        else
            # If the download fails, report the error but continue
            echo "Warning: Failed to fetch trackers from $url"
        fi
    done

    # 3. Check if all downloads have failed
    if [[ "$all_failed" == true ]]; then
        echo "All live tracker URLs failed. Using the static list."
        trackers_list="$STATIC_TRACKERS_LIST"
    fi
}

inject_trackers () {
	echo -ne "\e[0;36;1mInjecting... \e[0;36m"

	torrent_trackers=$(echo "$qbt_cookie" | $curl_executable --silent --fail --show-error \
				--cookie - \
				--request GET "${qbt_host}:${qbt_port}/api/v2/torrents/trackers?hash=${1}" | $jq_executable --raw-output '.[] | .url' | tail -n +4)

	remove_trackers $1 "${torrent_trackers//$'\n'/|}"

	if [[ $clean_existing_trackers == true ]]; then
		echo -e " \e[32mBut before a quick cleaning the existing trackers... "
		trackers_list=$(echo "$trackers_list" | sort | uniq)
	else
		trackers_list=$(echo "$trackers_list"$'\n'"$torrent_trackers" | sort | uniq)
	fi

	trackers_list=$(sed '/^$/d' <<< "$trackers_list")

	number_of_trackers_in_list=$(echo "$trackers_list" | wc -l)

	urls=${trackers_list//$'\n'/%0A%0A}

	echo "$qbt_cookie" | $curl_executable --silent --fail --show-error \
		-d "hash=${1}&urls=$urls" \
		--cookie - \
		--request POST "${qbt_host}:${qbt_port}/api/v2/torrents/addTrackers"

	echo -e "\e[32mdone, injected $number_of_trackers_in_list trackers!"
}

get_torrent_list () {
	get_cookie
	torrent_list=$(echo "$qbt_cookie" | $curl_executable --silent --fail --show-error \
		--cookie - \
		--request GET "${qbt_host}:${qbt_port}/api/v2/torrents/info")
}

url_encode() {
  local string="${1}"

  # Check if xxd is available
  if command -v xxd >/dev/null 2>&1; then
    # If xxd is available, use xxd for encoding
    printf '%s' "$string" | xxd -p | sed 's/\(..\)/%\1/g' | tr -d '\n'
  else
    # If jq is available, use jq for encoding
    jq -nr --arg s "$string" '$s|@uri'
  fi
}

get_cookie () {
	encoded_username=$(url_encode "$qbt_username")
	encoded_password=$(url_encode "$qbt_password")

	# If encoding fails, exit the function
	if [ $? -ne 0 ]; then
		echo "Error during URL encoding" >&2
		return 1
	fi

	qbt_cookie=$($curl_executable --silent --fail --show-error \
		--header "Referer: ${qbt_host}:${qbt_port}" \
		--cookie-jar - \
		--data "username=${encoded_username}&password=${encoded_password}" ${qbt_host}:${qbt_port}/api/v2/auth/login)
}

hash_check() {
	case $1 in
		( *[!0-9A-Fa-f]* | "" ) return 1 ;;
		( * )
			case ${#1} in
				( 32 | 40 ) return 0 ;;
				( * )       return 1 ;;
			esac
	esac
}

remove_trackers () {
	hash="$1"
	single_url="$2"
	echo "$qbt_cookie" | $curl_executable --silent --fail --show-error \
		-d "hash=${hash}&urls=${single_url}" \
		--cookie - \
		--request POST "${qbt_host}:${qbt_port}/api/v2/torrents/removeTrackers"
}

wait() {
	w=$1
	echo "I'll wait ${w}s to be sure ..."
	while [ $w -gt 0 ]; do
		echo -ne "$w\033[0K\r"
		sleep 1
		w=$((w-1))
	done
}
########## FUNCTIONS ##########

if [ -t 1 ] || [[ "$PWD" == *qbittorrent* ]] ; then
	if [[ ! $@ =~ ^\-.+ ]]; then
		echo "Arguments must be passed with - in front, like -n foo. Check instructions"
		echo ""
		$0 -h
		exit
	fi

	[ $# -eq 0 ] && $0 -h

	if [ $# -eq 1 ] && [ $1 == "-f" ]; then
		echo "Don't use only -f, you need to specify also the torrent!"
		exit
	fi

	while getopts ":acflhn:s:" opt; do
		case ${opt} in
			a ) # If used inject trackers to all torrent.
				all_torrent=1
				;;
			c ) # If used remove all the existing trackers before injecting the new ones.
				clean_existing_trackers=true
				;;
			f ) # If used force the injection also in private trackers.
				applytheforce=1
				;;
			l ) # Print the list of the torrent where you can inject trackers.
				get_torrent_list
				echo -e "\n\e[0;32;1mCurrent torrents:\e[0;32m"
				echo "$torrent_list" | $jq_executable --raw-output '.[] .name'
				exit
				;;
			n ) # Specify the name of the torrent example -n foo or -n "foo bar", multiple -n can be used.
				tor_arg_names+=("$OPTARG")
				;;
			s ) # Specify the category of the torrent example -s foo or -s "foo bar", multiple -s can be used. If -s is passed without arguments, the "default" categories will be used
				tor_categories+=("$OPTARG")
				;;
			: )
				echo "Invalid option: -${OPTARG} requires an argument" 1>&2
				exit 0
				;;
			\? )
				echo "Unknow option: -${OPTARG}" 1>&2
				exit 1
				;;
			h | * ) # Display help.
				echo "Usage:"
				echo "$0 -a	Inject trackers to all torrent in qBittorrent, this not require any extra information"
				echo "$0 -c	Clean all the existing trackers before the injection, this not require any extra information"
				echo "$0 -f	Force the injection of the trackers inside the private torrent too, this not require any extra information"
				echo "$0 -l	Print the list of the torrent where you can inject trackers, this not require any extra information"
				echo "$0 -n	Specify the torrent name or part of it, for example -n foo or -n 'foo bar'"
				echo "$0 -s	Specify the exact category name, for example -s foo or -s 'foo bar'. If -s is passed empty, \"\", the \"Uncategorized\" category will be used"
				echo "$0 -h	Display this help"
				echo ""
				echo "NOTE:"
				echo "It's possible to specify more than -n in one single command"
				echo "It's possible to specify more than -s in one single command"
				echo "Is also possible use -n foo -s bar to select specific name in specific category"
				echo "Just remember that if you set -a, is useless to add any extra arguments, like -n, but -f can always be used"
				exit 2
				;;
		esac
	done
	shift $((OPTIND -1))
else
	if [[ -n "${sonarr_download_id}" ]] || [[ -n "${radarr_download_id}" ]] || [[ -n "${lidarr_download_id}" ]] || [[ -n "${readarr_download_id}" ]]; then
		#wait 5
		if [[ -n "${sonarr_download_id}" ]]; then
			echo "Sonarr variable found -> $sonarr_download_id"
			hash=$(echo "$sonarr_download_id" | awk '{print tolower($0)}')
		fi

		if [[ -n "${radarr_download_id}" ]]; then
			echo "Radarr variable found -> $radarr_download_id"
			hash=$(echo "$radarr_download_id" | awk '{print tolower($0)}')
		fi

		if [[ -n "${lidarr_download_id}" ]]; then
			echo "Lidarr variable found -> $lidarr_download_id"
			hash=$(echo "$lidarr_download_id" | awk '{print tolower($0)}')
		fi

		if [[ -n "${readarr_download_id}" ]]; then
			echo "Readarr variable found -> $readarr_download_id"
			hash=$(echo "$readarr_download_id" | awk '{print tolower($0)}')
		fi

		hash_check "${hash}"
		if [[ $? -ne 0 ]]; then
			echo "No valid hash found for the torrent, I'll exit"
			exit 3
		fi
		auto_tor_grab=1
	fi

	if [[ $sonarr_eventtype == "Test" ]] || [[ $radarr_eventtype == "Test" ]] || [[ $lidarr_eventtype == "Test" ]] || [[ $readarr_eventtype == "Test" ]]; then
		echo "Test in progress..."
		test_in_progress=1
	fi
fi

for i in "${tor_arg_names[@]}"; do
	if [[ -z "${i// }" ]]; then
		echo "one or more argument for -n not valid, try again"
		exit
	fi
done

if [ $test_in_progress -eq 1 ]; then
	echo "Good-bye!"
elif [ $auto_tor_grab -eq 0 ]; then # manual run
	get_torrent_list

	if [ $all_torrent -eq 1 ]; then
		while IFS= read -r line; do
			torrent_name_array+=("$line")
		done < <(echo $torrent_list | $jq_executable --raw-output '.[] | .name')

		while IFS= read -r line; do
			torrent_hash_array+=("$line")
		done < <(echo $torrent_list | $jq_executable --raw-output '.[] | .hash')
	else
		if [[ ${#tor_arg_names[@]} -gt 0 && ${#tor_categories[@]} -gt 0 ]]; then
			for name in "${tor_arg_names[@]}"; do
				for category in "${tor_categories[@]}"; do
					torrent_name_list=$(echo "$torrent_list" | $jq_executable --arg category "$category" --arg name "$name" --raw-output '.[] | select(.category | ascii_downcase == ($category | ascii_downcase)) | select(.name | ascii_downcase | contains($name | ascii_downcase)) | .name')

					if [ -n "$torrent_name_list" ]; then # not empty
						torrent_name_check=1

						if [[ $category == "" ]]; then
							echo -e "\n\e[0;32;1mFor the name ### $name ### in category ### Uncategorized ###\e[0;32m"
						else
							echo -e "\n\e[0;32;1mFor the name ### $name ### in category ### $category ###\e[0;32m"
						fi

						echo -e "\e[0;32;1mI found the following torrent(s):\e[0;32m"
						echo "$torrent_name_list"
					else
						torrent_name_check=0
					fi

					if [ $torrent_name_check -eq 0 ]; then
						if [[ $category == "" ]]; then
							echo -e "\n\e[0;31;1mI didn't find a torrent with name ### $name ### in category ### Uncategorized ###\e[0m"
						else
							echo -e "\n\e[0;31;1mI didn't find a torrent with name ### $name ### in category ### $category ###\e[0m"
						fi

						shift
						continue
					else
						while read -r single_found; do
							torrent_name_array+=("$single_found")
							hash=$(echo "$torrent_list" | $jq_executable --arg single "$single_found" --raw-output '.[] | select(.name == "\($single)") | .hash')
							torrent_hash_array+=("$hash")
						done <<< "$torrent_name_list"
					fi
				done
			done
		elif [[ ${#tor_arg_names[@]} -gt 0 ]]; then
			for name in "${tor_arg_names[@]}"; do
				torrent_name_list=$(echo "$torrent_list" | $jq_executable --arg name "$name" --raw-output '.[] | select(.name | ascii_downcase | contains($name | ascii_downcase)) | .name') #possible fix for ONIGURUMA regex libary

				if [ -n "$torrent_name_list" ]; then # not empty
					torrent_name_check=1
					echo -e "\n\e[0;32;1mFor the name ### $name ###\e[0;32m"
					echo -e "\e[0;32;1mI found the following torrent(s):\e[0;32m"
					echo "$torrent_name_list"
				else
					torrent_name_check=0
				fi

				if [ $torrent_name_check -eq 0 ]; then
					echo -e "\n\e[0;31;1mI didn't find a torrent with this part of the text: \e[21m$name\e[0m"
					shift
					continue
				else
					while read -r single_found; do
						torrent_name_array+=("$single_found")
						hash=$(echo "$torrent_list" | $jq_executable --arg single "$single_found" --raw-output '.[] | select(.name == "\($single)") | .hash')
						torrent_hash_array+=("$hash")
					done <<< "$torrent_name_list"
				fi
			done
		else
			for category in "${tor_categories[@]}"; do
				torrent_name_list=$(echo "$torrent_list" | $jq_executable --arg category "$category" --raw-output '.[] | select(.category | ascii_downcase == ($category | ascii_downcase)) | .name')

				if [ -n "$torrent_name_list" ]; then # not empty
					torrent_name_check=1

					if [[ $category == "" ]]; then
						echo -e "\n\e[0;32;1mFor category ### Uncategorized ###\e[0;32m"
					else
						echo -e "\n\e[0;32;1mFor category ### $category ###\e[0;32m"
					fi

					echo -e "\e[0;32;1mI found the following torrent(s):\e[0;32m"
					echo "$torrent_name_list"
				else
					torrent_name_check=0
				fi

				if [ $torrent_name_check -eq 0 ]; then
					echo -e "\n\e[0;31;1mI didn't find a torrent in the category: \e[21m$category\e[0m"
					shift
					continue
				else
					while read -r single_found; do
						torrent_name_array+=("$single_found")
						hash=$(echo "$torrent_list" | $jq_executable --arg single "$single_found" --raw-output '.[] | select(.name == "\($single)") | .hash')
						torrent_hash_array+=("$hash")
					done <<< "$torrent_name_list"
				fi
			done
		fi
	fi

	if [ ${#torrent_name_array[@]} -gt 0 ]; then
		echo ""
		for i in "${!torrent_name_array[@]}"; do
			echo -ne "\n\e[0;1;4;32mFor the Torrent: \e[0;4;32m"
			echo "${torrent_name_array[$i]}"

			if [[ $ignore_private == true ]] || [ $applytheforce -eq 1 ]; then # Inject anyway the trackers inside any torrent
				if [ $applytheforce -eq 1 ]; then
					echo -e "\e[0m\e[33mForce mode is active, I'll inject trackers anyway\e[0m"
				else
					echo -e "\e[0m\e[33mignore_private set to true, I'll inject trackers anyway\e[0m"
				fi
				generate_trackers_list
				inject_trackers ${torrent_hash_array[$i]}
			else
				private_check=$(echo "$qbt_cookie" | $curl_executable --silent --fail --show-error --cookie - --request GET "${qbt_host}:${qbt_port}/api/v2/torrents/properties?hash=$(echo "$torrent_list" | $jq_executable --raw-output --arg tosearch "${torrent_name_array[$i]}" '.[] | select(.name == "\($tosearch)") | .hash')" | $jq_executable --raw-output '.is_private')

				if [[ $private_check == true ]]; then
					private_tracker_name=$(echo "$qbt_cookie" | $curl_executable --silent --fail --show-error --cookie - --request GET "${qbt_host}:${qbt_port}/api/v2/torrents/trackers?hash=$(echo "$torrent_list" | $jq_executable --raw-output --arg tosearch "${torrent_name_array[$i]}" '.[] | select(.name == "\($tosearch)") | .hash')" | $jq_executable --raw-output '.[3] | .url' | sed -e 's/[^/]*\/\/\([^@]*@\)\?\([^:/]*\).*/\2/')
					echo -e "\e[31m< Private tracker found \e[0m\e[33m-> $private_tracker_name <- \e[0m\e[31mI'll not add any extra tracker >\e[0m"
				else
					echo -e "\e[0m\e[33mThe torrent is not private, I'll inject trackers on it\e[0m"
					generate_trackers_list
					inject_trackers ${torrent_hash_array[$i]}
				fi
			fi
		done
	else
		echo "No torrents found, exiting"
	fi
else # auto_tor_grab active, so some *Arr
	wait 5
	get_torrent_list

	private_check=$(echo "$qbt_cookie" | $curl_executable --silent --fail --show-error --cookie - --request GET "${qbt_host}:${qbt_port}/api/v2/torrents/properties?hash=$hash" | $jq_executable --raw-output '.is_private')

	if [[ $private_check == true ]]; then
		private_tracker_name=$(echo "$qbt_cookie" | $curl_executable --silent --fail --show-error --cookie - --request GET "${qbt_host}:${qbt_port}/api/v2/torrents/trackers?hash=$hash" | $jq_executable --raw-output '.[3] | .url' | sed -e 's/[^/]*\/\/\([^@]*@\)\?\([^:/]*\).*/\2/')
		echo -e "\e[31m< Private tracker found \e[0m\e[33m-> $private_tracker_name <- \e[0m\e[31mI'll not add any extra tracker >\e[0m"
	else
		echo -e "\e[0m\e[33mThe torrent is not private, I'll inject trackers on it\e[0m"
		generate_trackers_list
		inject_trackers $hash
	fi
fi
