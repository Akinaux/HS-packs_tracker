FROM ubuntu:18.04

RUN apt update && \
apt-get install -y jq wget diffutils git && \
mkdir /Hearthstone && \
git clone https://github.com/Akinaux/HS-packs_tracker.git /Hearthstone
