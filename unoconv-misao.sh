#!/bin/sh
# unoconv-misao - REST API wrapper for unoconv
# Compatible with Moodle LMS and standard unoconv interface
# 

# Адрес поменять чтобы работало у вас
SERVER_URL="https://unoconv.misaoinst.ru"

# Парсинг аргументов в стиле unoconv
FORMAT=""
OUTPUT_FILE=""
INPUT_FILE=""

while [ $# -gt 0 ]; do
    case $1 in
        --version)
            echo "unoconv 0.9"
            exit 0
            ;;
	--show)
            echo "The following list of document formats are currently available:" >&2
            echo "" >&2
            echo "pdf - Portable Document Format [.pdf]" >&2
            echo "doc - Microsoft Word 97/2000/XP [.doc]" >&2
            echo "docx - Microsoft Office Open XML Text [.docx]" >&2
            echo "odt - OpenDocument Text [.odt]" >&2
            echo "rtf - Rich Text Format [.rtf]" >&2
            echo "txt - Text [.txt]" >&2
            echo "html - HTML Document [.html]" >&2
            echo "xls - Microsoft Excel 97/2000/XP [.xls]" >&2
            echo "xlsx - Microsoft Office Open XML Spreadsheet [.xlsx]" >&2
            echo "ods - OpenDocument Spreadsheet [.ods]" >&2
            echo "ppt - Microsoft PowerPoint 97/2000/XP [.ppt]" >&2
            echo "pptx - Microsoft Office Open XML Presentation [.pptx]" >&2
            echo "odp - OpenDocument Presentation [.odp]" >&2
            exit 0
            ;;
        -f|--format)
            FORMAT="$2"
            shift 2
            ;;
        --format=*)
            FORMAT="${1#*=}"
            shift
            ;;
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        --output=*)
            OUTPUT_FILE="${1#*=}"
            shift
            ;;
        -*)
            # Игнорируем остальные опции unoconv для совместимости
            shift
            ;;
        *)
            INPUT_FILE="$1"
            shift
            ;;
    esac
done

# Проверка обязательных параметров
if [ -z "$INPUT_FILE" ]; then
    echo "unoconv: error: you have to provide an input file" >&2
    exit 1
fi

if [ ! -f "$INPUT_FILE" ]; then
    echo "unoconv: error: file does not exist: $INPUT_FILE" >&2
    exit 1
fi

# Определение формата по умолчанию (PDF)
if [ -z "$FORMAT" ]; then
    FORMAT="pdf"
fi

# Определение выходного файла
if [ -z "$OUTPUT_FILE" ]; then
    BASENAME=$(basename "$INPUT_FILE" | sed 's/\.[^.]*$//')
    DIRNAME=$(dirname "$INPUT_FILE")
    OUTPUT_FILE="$DIRNAME/$BASENAME.$FORMAT"
fi

# Конвертация через REST API
HTTP_CODE=$(curl -w "%{http_code}" -s \
    -X POST \
    -F "file=@$INPUT_FILE" \
    -F "convert-to=$FORMAT" \
    "$SERVER_URL/request" \
    -o "$OUTPUT_FILE" 2>/dev/null)

# Проверка результата
if [ "$HTTP_CODE" = "200" ] && [ -f "$OUTPUT_FILE" ] && [ -s "$OUTPUT_FILE" ]; then
    exit 0
else
    echo "unoconv: error: conversion failed" >&2
    [ -f "$OUTPUT_FILE" ] && rm -f "$OUTPUT_FILE"
    exit 1
fi
