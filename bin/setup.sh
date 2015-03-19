#!/bin/bash

cf cs logstash14 free logstash-one
cf cs logstash14 free logstash-two

cd fixtures/cf-env

cf push app-one-log-one --no-start
cf bs app-one-log-one logstash-one

cf push app-two-log-one --no-start
cf bs app-two-log-one logstash-one

cf push app-three-log-two --no-start
cf bs app-three-log-two logstash-two

cd ../..

cf s
