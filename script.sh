#!/bin/bash

# This is a script to merge all html files to a index.html one full page.

#
# SETUP
#

TITLE="Documentation"
AUTHOR="Author Name"
SUBTITLE="A HTML page for documentation"

# Description in HTML
DESCRIPTION="$(cat <<HTML
<!-- DOCUMENTATION DESCRIPTION -->
<p>This is the Documentatation description.</p>
<!-- END OF DESCRIPTION -->
HTML
)"


#
# VARIABLES
#

if [[ ! -d html ]]; then
    echo "Folder html/ do not exist, create it."
    exit
fi


SOURCE_FILES_LIST=$(sed "s/\s*#.*//g; /^$/d" files-order.txt)


#
# TABLE OF CONTENTS
#

while IFS="" read -r LINE; do
    FILE="source/$LINE"

    EACH_FILE=$(for i in {2..6}; do cat "$FILE" | grep -P "<h${i}" | sed -e 's/^[ \t]*//'; done)

    while IFS="" read -r HEADING; do
        if [[ $HEADING == *"id="* ]]; then
            TOC_LEVEL="${HEADING:2:1}"
            HEADING_TITLE="${HEADING#*>}"
            HEADING_TITLE="${HEADING_TITLE%<*}"
            ID=$(echo "$HEADING" | grep -Po 'id="\K[^"]+')
            echo "$TOC_LEVEL;$HEADING;$ID;$HEADING_TITLE" >> toc_tmp.txt
        fi
    done <<< $EACH_FILE
done <<< $SOURCE_FILES_LIST


while IFS=";" read -r TOC_LEVEL HEADING HEADING_ID HEADING_TITLE; do
    echo "<li class='toc-level-$TOC_LEVEL'><a href='#$HEADING_ID'>$HEADING_TITLE</a></li>" >> toc_final.txt
done < toc_tmp.txt


#
# FILE CONTENTS
#

rm -rf full_html.txt

while IFS="" read -r LINE; do
    echo "<div class='section'>" >> full_html.txt
    cat "source/$LINE" >> full_html.txt
    echo "</div>" >> full_html.txt
done <<< $SOURCE_FILES_LIST


rm -rf final_html.txt

while IFS="" read -r LINE; do
    if [[ $LINE =~ "<h"+[0-9] ]]; then

        HEADING_NUMBER=$(echo "$LINE" | grep -o -E '[0-9]+' | head -1 | sed -e 's/^0\+//')

        if [[ $LINE == *"id="* ]]; then
            ID=$(echo "$LINE" | grep -Po 'id="\K[^"]+')
            echo "<a href='#$ID'>" >> final_html.txt
            echo "$LINE" >> final_html.txt
            echo "</a>" >> final_html.txt
        else
            echo "$LINE" >> final_html.txt
        fi
    else
        echo $LINE >> final_html.txt
    fi

done < full_html.txt

#
# MAKING THE DOCUMENTATION FILE
#

HTML="$(cat <<-HTML
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<meta name="author" content="$AUTHOR">
<meta name="description" content="$SUBTITLE">
<link type="text/css" rel="stylesheet" href="style.css">
<title>$TITLE</title>
</head>
<body>

<header>
<h1>$TITLE</h1>

$DESCRIPTION
</header>

<p id="modification-date">Last modification date: $(date "+%Y-%m-%d %T")</p>

<!-- TABLE OF CONTENTS -->
<div id="table-of-contents">
<h2>Table of Contents</h2>
<ul>
$(cat toc_final.txt)
</ul>
</div>

<main>
<!-- DOCUMENTATION CONTENT START -->
$(cat final_html.txt)
<!-- DOCUMENTATION CONTENT END -->
</main>

<a id="toc-button" href="#table-of-contents">TOC</a>
</body>
</html>
HTML
)"

echo "$HTML" > html/index.html

#
# REMOVE TEMPORARY FILES
#

rm -rf toc_tmp.txt toc_final.txt full_html.txt final_html.txt

echo ">> DONE << :)"
