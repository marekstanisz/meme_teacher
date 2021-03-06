wait_for_update() {
  STACK_NAME="$1"
  MESSAGE="$2"

  while true; do
    STATUS=`aws cloudformation describe-stacks --stack-name $STACK_NAME | jq --raw-output .Stacks[0].StackStatus`
    echo "`date` $MESSAGE $STATUS"

    case "$STATUS" in
      UPDATE_COMPLETE)
        break
        ;;
      UPDATE_IN_PROGRESS)
        ;;
      UPDATE_COMPLETE_CLEANUP_IN_PROGRESS)
        ;;
      *)
        exit 1
    esac

    sleep 4
  done
}

instances_in_pool() {
  POOL="$1"
  aws ec2 describe-instances \
    --filters \
      "Name=tag:pool,Values=$POOL" \
      "Name=instance-state-name,Values=pending,running" \
  | \
  jq \
    --raw-output \
    '.Reservations[].Instances[].InstanceId' \
  | \
  sort
}

pool_desired_capacity() {
  POOL="$1"
  aws autoscaling describe-auto-scaling-groups \
  | \
  jq \
    --raw-output \
    ".AutoScalingGroups[] | \
      select(.Tags[] | \
        select(.Key == \"pool\" and .Value == \"$POOL\")) | \
      .DesiredCapacity"
}

elb_healthy_instances() {
  aws elb describe-instance-health \
    --load-balancer-name memecaptain \
  | \
  jq \
    --raw-output \
    '.InstanceStates | map(select(.State == "InService"))[].InstanceId' \
  | \
  sort
}

wait_for_pool_healthy() {
  POOL="$1"

  DESIRED_CAPACITY=$(pool_desired_capacity "$POOL")
  echo "`date` $POOL pool desired capacity = $DESIRED_CAPACITY"
  if [ "$DESIRED_CAPACITY" -eq 0 ]; then return; fi

  START=$SECONDS

  TEMP=$(mktemp -d -t pool_health)
  pushd $TEMP

  while true; do
    echo `date` waiting for all instances in $POOL to be healthy

    instances_in_pool "$POOL" > pool
    if [ -s pool ]; then
      elb_healthy_instances > healthy
      sort pool healthy | uniq -d > healthy_in_pool
      set +e
      git diff pool healthy_in_pool
      RESULT=$?
      set -e
      if [ $RESULT -eq 0 ]; then break; fi
    fi
    sleep 4
  done

  echo `date` $POOL pool healthy after $((SECONDS - START)) seconds

  popd
  rm -rf $TEMP
}

wait_for_all_healthy() {
  wait_for_pool_healthy canary
  wait_for_pool_healthy ondemand
  wait_for_pool_healthy spot
}

make_env() {
  rm -rf env/*
  ./make_env.rb
}

diff_env() {
  mkdir -p env.current
  aws s3 sync --delete s3://memecaptain-secrets/env env.current
  set +e
  echo "Environment changes:"
  diff -r env.current env
  set -e
  rm -rf env.current
}

deploy_start() {
  if [ -n "$STATS_SECRET" ]; then
    curl https://memecaptain.com/stats \
      --data key=deploy.start \
      --data-urlencode "secret=$STATS_SECRET"
  fi
}

deploy_end() {
  if [ -n "$STATS_SECRET" ]; then
    curl https://memecaptain.com/stats \
      --data key=deploy.end \
      --data-urlencode "secret=$STATS_SECRET"
  fi
}
