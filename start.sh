#!/bin/bash
bundle install &&\
  bundle exec ruby listen_callback.rb\
    -d ~/dev/clustertruck/api\
    -u https://api.dev.clustertruck.com/api/file_change\
    -i .git\
    -i tmp\
    -i log\
    -i .vagrant\
    -i spec
