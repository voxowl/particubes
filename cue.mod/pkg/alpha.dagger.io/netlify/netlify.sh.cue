package netlify

#Site: ctr: command: #"""
	export NETLIFY_AUTH_TOKEN="$(cat /run/secrets/token)"

	create_site() {
	    url="https://api.netlify.com/api/v1/${NETLIFY_ACCOUNT:-}/sites"

	    response=$(curl -s -S --fail-with-body -H "Authorization: Bearer $NETLIFY_AUTH_TOKEN" \
	                -X POST -H "Content-Type: application/json" \
	                $url \
	                -d "{\"name\": \"${NETLIFY_SITE_NAME}\", \"custom_domain\": \"${NETLIFY_DOMAIN}\"}" -o body
	            )
	    if [ $? -ne 0 ]; then
		cat body >&2
	        exit 1
	    fi

	    cat body | jq -r '.site_id' 
	}

	site_id=$(curl -s -S -f -H "Authorization: Bearer $NETLIFY_AUTH_TOKEN" \
	            https://api.netlify.com/api/v1/sites\?filter\=all | \
	            jq -r ".[] | select(.name==\"$NETLIFY_SITE_NAME\") | .id" \
	        )
	if [ -z "$site_id" ] ; then
	    if [ "${NETLIFY_SITE_CREATE:-}" != 1 ]; then
	        echo "Site $NETLIFY_SITE_NAME does not exist"
	        exit 1
	    fi
	    site_id=$(create_site)
	    if [ -z "$site_id" ]; then
	        echo "create site failed"
	        exit 1
	    fi
	fi

	netlify link --id "$site_id"
	netlify build

	netlify deploy \
	    --dir="$(pwd)" \
	    --site="$site_id" \
	    --prod \
	| tee /tmp/stdout

	url="$(cat /tmp/stdout | grep Website | grep -Eo 'https://[^ >]+' | head -1)"
	deployUrl="$(cat /tmp/stdout | grep Unique | grep -Eo 'https://[^ >]+' | head -1)"
	logsUrl="$(cat /tmp/stdout | grep Logs | grep -Eo 'https://[^ >]+' | head -1)"

	# Write output files
	mkdir -p /netlify
	printf "$url" > /netlify/url
	printf "$deployUrl" > /netlify/deployUrl
	printf "$logsUrl" > /netlify/logsUrl
	"""#
