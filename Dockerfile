FROM centos:latest

RUN yum install -y jq wget diffutils git && \
mkdir /Hearthstone && \
git clone https://github.com/Akinaux/HS-packs_tracker.git /Hearthstone
