#!/bin/bash

urlencode() {
 [ $# -lt 1 ] && { return; }

 encodedurl="$1";

 # make sure hexdump exists, if not, just give back the url
 [ ! -x "/usr/bin/hexdump" ] && { return; }

   echo $encodedurl | hexdump -v -e '1/1 "%02x\t"' -e '1/1 "%_c\n"' |
   LANG=C awk '
     $1 == "20"                    { printf("%s",   "+"); next } # space becomes plus
     $1 ~  /0[adAD]/               {                      next } # strip newlines
     $2 ~  /^[a-zA-Z0-9.*()-]$/  { printf("%s",   $2);  next } # pass through what we can
                                   { printf("%%%s", $1)        } # take hex value of everything else
   '
}
