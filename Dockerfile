FROM ubuntu:18.04

RUN apt update && \
apt-get install -y curl jq wget diffutils && \
mkdir /Hearthstone
COPY packs_tracker.sh /Hearthstone/
