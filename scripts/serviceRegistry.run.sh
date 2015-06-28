

export pidFile=tmp/redex.${testName}.pid

testName=serviceRegistry

c0assert() {
  which 'nodejs' || exit 1
  if ! which 'bunyan'
  then
    echo "Please install: npm install -g bunyan"
    exit 1
  fi
  if ! pwd | grep -q '/redex$'
  then
    echo "Please run from redex directory"
    exit 1
  fi
}

c0clear() {
  for key in `redis-cli keys 'redex:test:*'`
  do
    echo "redis-cli del '$key'"
    redis-cli del "$key"
  done
}

c0client() {
  ns='redex:test:service:http'
  id=123
  ttl=10
  time=`redis-cli time | head -1`
  deadline=`echo "$time + $ttl" | bc`
  echo "time $time, ttl $ttl, deadline $deadline"
  message="{ id: $id, deadline: $deadline }"
  message=`echo "$message" | sed 's/ \(\w*\): / "\1": /g'`
  echo "message $message"
  echo "redis-cli lpush $ns:in '$message'"
  redis-cli lpush $ns:in "$message"
  sleep 1
  echo "redis-cli keys $ns:*"
  redis-cli keys '$ns:*'
  echo "redis-cli smembers $ns:ids"
  redis-cli smembers $ns:ids
  echo "redis-cli hgetall $ns:$id"
  redis-cli hgetall "$ns:$id"
  echo "message $message"
  sleep 2
  echo "redis-cli srem $ns:ids $id"
  redis-cli srem $ns:ids "$id"
  echo "redis-cli smembers $ns:ids"
  redis-cli smembers $ns:ids
}

c0server() {
  nodejs index.js test/cases/serviceRegistry/registrant.yaml | bunyan -o short
}

  c0assert
  c0clear
  c0client & c0server
