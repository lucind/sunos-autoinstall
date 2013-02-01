function svcck {
echo $f
  true
  while [ $? = 0 ]; do
    if [ $f ]; then break; fi
    echo "Waiting a second for services to online.  To force, include -f arg."
    sleep 1
    svcs -xv|ggrep -E --color  "(.*)|$"
  done
}

