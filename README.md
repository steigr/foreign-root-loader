Foreign-Root-Loader
===================

Purpose
-------

Some special applications are not easily containerizeable, escpecially when they are maintained by some third-party,
rely on full init systems (systemd, upstart) an so forth.

Docker can run these kind of virtual-machine-containers by making them privileged and or pass some special volumes and
with all root-folders from some chroot mapped as volumes.

SwarmKit related issues
-----------------------

SwarmKit is a new feature within docker for distributed cluster orchestration.
Because of that (and new features in docker are never able to replace their designated predecessor when they are in "production"),
I built this image.

Goal
----

Any existing quirky container should be made runnable within swarmkit stack and be part on the application network!

Technology
----------

Swarmkit launches this image and provides access to the docker socket.
The container itself is annoated with container-labels.
It inspects itself, and launches the real container, with
- its network-namespace interited
- all volumes mapped
- with extra capabilities
- with fake TTY to allow creation of /dev/console (systemd-output)
- port forwarding on the host (no virtual-ip mode, allow to see real peer address for e.g. mailservers with blacklists)

Labels
======

- foreign-root.capabilities: list of capabilities, e.g. SYS_ADMIN or NET_ADMIN
- foreign-root.folder: where is the chroot
- foreign-root.lxcfs: if lxcfs is used (cpuinfo and meminfo backwards compatibility)
- foreign-root.volumes: list of other volumes
- foreign-root.publish: list of ports to DNAT into the container
- foreign-root.entrypoint: name of the entrypoint binary (if not /sbin/init)
- foreign-root.environment: environment variables
- foreign-root.stop-signal: stop-signal of the container
- foreign-root.args: list of extra docker arguments without leading '--'
- foreign-root.cpuset-cpus: list of allowed cpu cores
- foreign-root.memory: memory constraint
- foreign-root.memory-swap: memory+swap constraint
- foreign-root.hostname: hostname to set

Examples
========

Mailcow
-------

1. Install mailcow (debian-jessie + systemd-215 + full-stack-mailserver) to some chroot (e.g. /srv/mailcow).
2. LXCFS is mounted under /var/lib/lxcfs
3. Create the docker swarm-service:
```
docker service create \
--constraint=node.hostname==server-with-chroot \
--name=mailcow \
--mount=type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
--network=special-overlay-network \
--limit-cpu=1024 \
--limit-memory=32M \
--log-driver=journald \
--mode=replicated \
--reserve-memory=0M \
--restart-condition=any \
--restart-delay=10s \
--stop-grace-period=180s \
--update-delay=60s \
--update-parallelism=1 \
--endpoint-mode=vip \
--replicas=1 \
--container-label=foreign-root.capabilities=SYS_ADMIN \
--container-label=foreign-root.folder=/srv/mailcow \
--container-label=foreign-root.lxcfs=/var/lib/lxcfs \
--container-label=foreign-root.volumes=/root,/run,/run/lock,/sys/fs/cgroup:/sys/fs/cgroup:ro \
--container-label=foreign-root.publish=25,80,110,143,443,465,587,993,995 \
--container-label=foreign-root.entrypoint=/lib/systemd/systemd \
--container-label=foreign-root.environment=container=docker,TERM=xterm \
--container-label=foreign-root.stop-signal=rtmin+3 \
--container-label=foreign-root.args=privileged=true,tty=true \
--container-label=foreign-root.cpuset-cpus=0,1 \
--container-label=foreign-root.memory=768M \
--container-label=foreign-root.memory-swap=2048M \
--container-label=foreign-root.hostname=mailcow.exampl.com \
steigr/foreign-root-loader
```
