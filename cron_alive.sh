A=`pgrep -f cronned_task.rb | wc -w`

if [ "$A" -eq 0 ]; then
    echo "Starting Mutx Cron process"
    export DISPLAY=:0;
    ruby ./cronned_task.rb;
else
  echo "Mutx Cron is already running"
fi