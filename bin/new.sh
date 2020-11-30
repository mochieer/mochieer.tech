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

DATE=$YEAR-$MONTH-$DAY
DIR=content/posts/$YEAR$MONTH$DAY-$TITLE_EN

mkdir $DIR

echo "---
title: \"${TITLE_JA}\"
date: \"${DATE}T00:00:00+09:00\"
tags:
  - foo
  - bar
---
" > $DIR/index.md
