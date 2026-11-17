./Morhpisms
while true
  n=$(ps -[pidof Morhpisms] -o rss | grep '[0-9]')
  if [ $n -gt 1000 ]; then  kill -9 <pid>; fi
