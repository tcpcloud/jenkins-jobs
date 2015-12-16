#!/bin/bash -xe

export USER=$(whoami)

if [ "${WIPE_WORKSPACE}" == 'true' ]; then
 rm -rf ${WORKSPACE}/*
fi

# Github account is needed to fetch repositories, ensure ssh agent is running
pgrep -l -u $USER -f | grep -e ssh-agent\$ >/dev/null || ssh-agent|grep -v "Agent pid" > ~/.ssh/ssh-agent.sh
. ~/.ssh/ssh-agent.sh
ssh-add ${SSH_KEY:-"$HOME/.ssh/id_rsa"}
grep github ~/.ssh/known_hosts || ssh-keyscan github.com >> ~/.ssh/known_hosts

if [ ! -d bin ]; then
    mkdir bin; cd bin
    wget -O repo https://storage.googleapis.com/git-repo-downloads/repo
    echo "1d54ba82869e5c2285e9858ae7020315 repo" >> md5sum
    md5sum -c --status md5sum
    chmod +x repo
    cd ..
fi

PATH="$WORKSPACE/bin:$PATH"

[ ! -d build ] && mkdir build
cd build

# Cleanup
[ -d build ] && rm -rf build

if [[ "$CONTRAIL_BRANCH" == "default" ]]; then
    repo init -u $CONTRAIL_VNC_REPO
else
    repo init -u $CONTRAIL_VNC_REPO -b $CONTRAIL_BRANCH
fi

# Needed for commands bellow
git config --global user.email "autobuild@example.com"
git config --global user.name "Autobuild"

# Discard local changes
repo forall -p -c 'git checkout -f'
repo forall -p -c 'git clean -xfd'

repo sync

cd third_party
python fetch_packages.py
cd ..

# XXX: get missing sources
# see https://github.com/Juniper/contrail-vnc/pull/21
if [ ! -d openstack/contrail-heat ]; then
    # No contrail-heat, checkout on our own
    git clone https://github.com/Juniper/contrail-heat openstack/contrail-heat -b $CONTRAIL_BRANCH
fi

if [ ! -d openstack/ceilometer_plugin ]; then
    # No ceilometer plugin, checkout on our own
    git clone https://github.com/Juniper/contrail-ceilometer-plugin.git openstack/ceilometer_plugin
fi

chmod u+w packages.make; rm -f packages.make
ln -s tools/packages/packages.make

# Sign with our key
export KEYID="FIXME"

# Custom versioning (include build number)
cat << 'EOF' > versions_cloudlab.mk
BASE_VERSION := $(shell xmllint --xpath '//manifest/default/@revision' .repo/manifest.xml | grep -Eo '"R[0-9\.x]*"' | grep -Eo '[0-9a-z\.]*' | sed s,\.x,,g)
TIMESTAMP := $(shell date +%s)
EPOCH = 0

ifdef BUILD_NUMBER
    BUILD_NUMBER := $(BUILD_NUMBER)
else
    BUILD_NUMBER := 1
endif


CONTROLLER_REF := $(shell (cd controller; git log --oneline -1) | awk '/[0-9a-f]+/ { print $$1; }')
CONTRAIL_VERSION = $(BASE_VERSION)+$(EPOCH)~$(TIMESTAMP).$(BUILD_NUMBER)~1.$(CONTROLLER_REF)
NEUTRON_REF := $(shell (cd openstack/neutron_plugin; git log --oneline -1) | awk '/[0-9a-f]+/ { print $$1; }')
NEUTRON_VERSION = $(BASE_VERSION)+$(EPOCH)~$(TIMESTAMP).$(BUILD_NUMBER)~1.$(NEUTRON_REF)
WEBUI_CORE_REF := $(shell (cd contrail-web-core; git log --oneline -1) | awk '/[0-9a-f]+/ { print $$1; }')
WEBUI_CORE_VERSION = $(BASE_VERSION)+$(EPOCH)~$(TIMESTAMP).$(BUILD_NUMBER)~1.$(WEBUI_CORE_REF)
WEBUI_CONTROLLER_REF := $(shell (cd contrail-web-controller; git log --oneline -1) | awk '/[0-9a-f]+/ { print $$1; }')
WEBUI_CONTROLLER_VERSION = $(BASE_VERSION)+$(EPOCH)~$(TIMESTAMP).$(BUILD_NUMBER)~1.$(WEBUI_CONTROLLER_REF)

ifneq ($(wildcard openstack/ceilometer_plugin/.*),)
    CEILOMETER_REF := $(shell (cd openstack/ceilometer_plugin; git log --oneline -1) | awk '/[0-9a-f]+/ { print $$1; }')
    CEILOMETER_VERSION = $(BASE_VERSION)+$(EPOCH)~$(TIMESTAMP).$(BUILD_NUMBER)~1.$(CEILOMETER_REF)
endif
ifneq ($(wildcard openstack/contrail-heat/.*),)
    CONTRAIL_HEAT_REF := $(shell (cd openstack/contrail-heat; git log --oneline -1) | awk '/[0-9a-f]+/ { print $$1; }')
    CONTRAIL_HEAT_VERSION = $(BASE_VERSION)+$(EPOCH)~$(TIMESTAMP).$(BUILD_NUMBER)~1.$(CONTRAIL_HEAT_REF)
endif
EOF
sed -i s,tools/packages/versions.mk,versions_cloudlab.mk,g packages.make

if [[ $TARGETS == *all* ]]; then
    TARGETS="source-all"
else
    TARGETS=$(echo $TARGETS | sed -e 's/,/\ source-package-/g' -e 's/^/source-package-/g')
fi

make -f packages.make $TARGETS
