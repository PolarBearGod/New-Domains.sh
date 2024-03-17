#!/bin/bash -
#Get TODAY's date and subtract 1 days. This is due to delays in file release.
#Set the format of the date to be YYYY-MM-DD
YESTERDAY=$(date --date="-1 day" +"%Y-%m-%d")
#Create a variable to store YYYYMMDD format. This will prevent clobbering.
DIRARCHIVE=$(date --date="-1 day" +"%Y%m%d")
#Add the zip extension to the date to get our complete filename
FILENAME="$YESTERDAY".zip
#Base64 encode the filename so we can place in the URL below.
FNENCODE=$(echo ${FILENAME} | base64)
#Trim the last character in the encoded filename. Not sure why this needs to be done?
FNENCODE=${FNENCODE::-1}
#Set the working directories and variables below.
DESTDIR="/opt/newdomains/${DIRARCHIVE}"
TEMPFILE="/tmp/wget_${DIRARCHIVE}.zip"
LOGFILE="/tmp/wget_${DIRARCHIVE}.log"
CSVFILE="/opt/splunk/etc/apps/search/lookups/${DIRARCHIVE}-newdomains.csv"
URL="https://www.whoisds.com//whois-database/newly-registered-domains/${FNENCODE}=/nrd"
#Set the wget user agent - using Win10 Chrome Version 74
USERAGENT='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.169 Safari/537.36'
#Making the magic happen here. Check if the destination directory exists
[[ -d "${DESTDIR}" ]] || mkdir -p "${DESTDIR}"
# Ensure that the file does not exist already. If yes, nuke it.
[[ -r "${DESTDIR}/domain-names.txt" ]] && rm -f "${DESTDIR}/domain-names.txt"
wget -o ${LOGFILE} -O ${TEMPFILE} --user-agent="$USERAGENT" $URL --content-on-error
sleep 2s
if [[ ! -f "${TEMPFILE}" ]]; then
                echo "[ERROR] Could not fetch $URL"
                cat ${LOGFILE}
        else
                unzip ${TEMPFILE} -d ${DESTDIR} > ${LOGFILE} 2>&1
                        if [[ ! -f "${DESTDIR}/domain-names.txt" ]]; then
                        echo "[ERROR] Looks like we did not unzip the ${TEMPFILE}. Did we get the actual download?"
                        ls -laf "/tmp/"
                        cat ${LOGFILE}
                else
                        mv "${DESTDIR}/domain-names.txt" "${CSVFILE}"
                        sed -i '1idomainname' "${CSVFILE}"
                fi
fi
#Clean Up Phase
rm -f ${TEMPFILE}
rm -rf ${DESTDIR}
rm -f ${LOGFILE}
