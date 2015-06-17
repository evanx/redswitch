
  cd ~/redixrouter || exit 1

  testName=httpFileServer.default

  export configFile=config/configurator.${testName}.yaml
  export pidFile=tmp/redix.${testName}.pid

  c0run() {
    nodejs index.js | bunyan -o short
  }

  c0client() {
    sleep 1
    curl -s http://localhost:8880/test.txt 
    echo
    curl -s http://localhost:8880/private
    echo
    sleep 1
    curl -s http://localhost:8880/test.html
    echo
    sleep 4
    echo "curl -s localhost:8880/test.txt"
    curl -I -s localhost:8880/test.txt
    echo
    curl -s http://localhost:8880/test.txt && (echo; echo "$testName OK")
    sleep 1
    rm -f $pidFile
  }

  c0client & c0run

