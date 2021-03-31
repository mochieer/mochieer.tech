#! /bin/sh

read -p "year: " YEAR
read -p "month: " MONTH
read -p "day: " DAY
read -p "title (Japanese): " TITLE_JA
read -p "title (English) for URL: " TITLE_EN

while true; do
    read -p 'Okey? [Y/n] ' yn
    case $yn in
        [Y] )  break;;
        [Nn] ) exit;;
        * )    ;;
    esac
done

mkdir -p content/posts/$YEAR/$MONTH/$DAY/$TITLE_EN

touch content/posts/$YEAR/_index.md
touch content/posts/$YEAR/$MONTH/_index.md
touch content/posts/$YEAR/$MONTH/$DAY/_index.md
echo "---
title: \"${TITLE_JA}\"
date: \"${YEAR}-${MONTH}-${DAY}T00:00:00+09:00\"
tags:
  - foo
  - bar
---
" > content/posts/$YEAR/$MONTH/$DAY/$TITLE_EN/index.md
