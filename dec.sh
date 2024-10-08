PROG_VER='1.1'
PROG_AUTH='eraselk @ github'

if [ -z "$1" ]; then
    echo "ERROR: no input file(s) or option provided"
    exit 1
fi

case "$1" in

"--update")
    if ! ping -c1 8.8.8.8 >/dev/null 2>&1; then
        echo "No internet connection"
        exit 1
    fi
    echo "Updating script..."
    rm -f dec.sh
    curl -s https://raw.githubusercontent.com/eraselk/Ri-Crypt-decryptor/main/dec.sh -o dec.sh && echo "Done" || {
        echo "Failed"
        exit 1
    }
    chmod +x dec.sh
    exit 0
    ;;
*)
    echo "RCD (Ri-Crypt Decryptor) v$PROG_VER"
    echo "by $PROG_AUTH"
    echo
    echo "WARNING: make sure the binary encrypted with Ri-Crypt"

    for file in $@; do

        if ! [ -f "$file" ]; then
            echo "file '$file' not found"
            exit 1
        fi

        name=$(basename $file)
        if echo "$file" | grep -q -e '/sdcard' -e '/storage/emulated/0' || [ ! -f "$name" ]; then
            cp -f $file .
            external=1
        fi
        chmod 777 $name

        if ! strings $name | grep -qE 'sh-c|.rs'; then
            echo "FATAL: $file is not an Ri-Crypt encrypted script"
            exit 1
        fi

        echo
        echo "Decrypting $file » output/$name.dec.sh..."

        start_decryptor() {
            (
                ./$name >/dev/null 2>&1 &
                a=$!
                ps -Ao ppid,cmd | grep $a | grep -v "grep $a" | cut -d ' ' -f2- | sed -e 's/^[0-9]*//g' -e 's/sh -c //g' -e 's/ | sh//g' -e 's/ | bash//g'
                kill -STOP $a
                kill -TERM $a
            ) >temp.sh 2>/dev/null
        }

        start_decryptor

        if ! cat temp.sh | grep -q 'base64 -d'; then
            until cat temp.sh | grep -q 'base64 -d'; do
                start_decryptor
            done
        fi

        chmod +x temp.sh
        ./temp.sh >./output/$name.dec.sh
        rm -f temp.sh

        if [ "$external" = "1" ]; then
            rm -f $name
        fi

        echo "Done"

    done
    ;;
esac
