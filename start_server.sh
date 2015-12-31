#!/bin/bash -ex

bundle exec unicorn -c ./config/unicorn.rb
