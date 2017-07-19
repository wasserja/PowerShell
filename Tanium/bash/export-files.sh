#! /bin/bash

unescape() {
    # decode everything between 0x20-0x7E except:
    #0 1 2 3 4 5 6 7 8 9 (0x30-0x39)
    #A B C D E F G H I J K L M N O P Q R S T U V W X Y Z (0x41-0x5A)
    #a b c d e f g h i j k l m n o p q r s t u v w x y z (0x61-0x7A)
    echo "$1" | sed -e 's/%20/ /g' \
    -e 's/%21/!/g' \
    -e 's/%22/"/g' \
    -e 's/%23/#/g' \
    -e 's/%24/$/g' \
    -e 's/%25/%/g' \
    -e 's/%26/\&/g' \
    -e "s/%27/'/g" \
    -e 's/%28/(/g' \
    -e 's/%29/)/g' \
    -e 's/%2[aA]/*/g' \
    -e 's/%2[bB]/+/g' \
    -e 's/%2[cC]/,/g' \
    -e 's/%2[dD]/-/g' \
    -e 's/%2[eE]/./g' \
    -e 's#%2[fF]#/#g' \
    -e 's/%3[aA]/:/g' \
    -e 's/%3[bB]/;/g' \
    -e 's/%3[cC]/</g' \
    -e 's/%3[dD]/=/g' \
    -e 's/%3[eE]/>/g' \
    -e 's/%3[fF]/?/g' \
    -e 's/%40/@/g' \
    -e 's/%5[bB]/[/g' \
    -e 's/%5[cC]/\\/g' \
    -e 's/%5[dD]/]/g' \
    -e 's/%5[eE]/^/g' \
    -e 's/%5[fF]/_/g' \
    -e 's/%60/`/g' \
    -e 's/%7[bB]/{/g' \
    -e 's/%7[cC]/|/g' \
    -e 's/%7[dD]/}/g' \
    -e 's/%7[eE]/~/g'
}

FOLDER=`unescape "||folder||"`

FILELISTLOG=/tmp/filelist.log

find $FOLDER -type f > $FILELISTLOG