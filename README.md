
Welcome, this is iglunix-autobuild.
Thu GNU General Public License v3 licensed (mostly) automatic build system for Iglunix.
Iglunix for the uninitiated is a linux distribution designed to not use _GNU_, sadly this is quite hard. GNU make is still available inside this environment.



# Usage

run `./autobuild.sh` to compile packages. Then run `./chroot.sh` to create a chroot.
To try Iglunix in a chroot run `./enter_chroot.sh`. If you want to create an installation image
run `./img.sh`.

# Dependencies

Please make certain that the following packages are available on the host.
`nasm, lld, samurai, bmake`

This script only works on Ubuntu 20.04!

# Alternative method

There is a different method to create the img. The needed files are also in this repo, to learn more about it look at the source of the readme file. It is hidden because it is currently unsupported. But it works via docker.

<!--
## Phase 1: Docker
This will create an llvm/musl toolchain.
I've heard that you guys don't like waiting for code to be compiled.
A docker swarm to the rescue, completely over engineered.

Make your main pc/laptop the manager of the swarm using:
`docker swarm init --advertise-addr [The IP-address of your device you want to use local/global]`

It will return a command that allows your other pcs to join, use it.

On the main node run: `docker network create -d overlay my_docker_overlay_net`

The problem is that we can't chain commands when starting a docker service create, so we'll have to modify the base abyssos/abyss:dev docker container. We'll need to download packages for the installation, we'll add these to the our modified package.
This method might also reduce internet usage.

To initialize run ```docker_init_clean```, this will create iglunix_abyss.tar, this will have to be manually moved to all docker nodes and then loaded using: ``` docker load -i iglunix_abyss.tar```

To start the distributed compiler `docker_start_farm` can be used. Prior to execution modify `docker_start_farm` to suit the number of jobs you need to run.

Run ```docker ps -a``` to find the container id of your work nodes
and execute a shell on a node of your choosing using. This can be done as follows:
`docker exec -it [container id] /bin/sh`

Modify DISTCC_HOSTS in `compile` in one container to point to all the docker distcc volunteers. Afterwards run `compile`.
When your compiles are finished, `docker_rm_farm` can be used to remove the compile farm.
It could be useful to leave the compile farm around for the compilation indide the chroot. This is not yet supported.

## Phase 2: Chroot

WARNING: This part makes use of loopback devices, if the kernel was updated but the system not rebooted, reboot.

This part is significantly less over engineered (luckily).
There are 4 new commands the user should be aware of, they are written in chronological order.

* chroot_prepare_iglunix

  This creates the chroot and cleans the most important locations (/lib, /bin, /sbin, /usr, /iglunix, /etc).
  It will also copy the network and keyboard configuration from the host. This will be put into the `*.img`by a script hosted in iglunix/iglunix.

* chroot_fetch

  This command will fetch the sources needed to get curl working inside the chroot. And some files for to be used inside the chroot environment. This command will automatically be executed by `chroot_prepare_iglunix`. It is __NOT NEEDED__ to be manually executed. But it can be for development purposes.
* chroot_iglunix

  This will chroot into the Iglunix environment. Once inside run `source /etc/profile` this helps debugging.
* inside_chroot

  This is the script that has to be executed inside the chroot to compile all the required packages in the correct order.
  This will also generate `iglunix.img` in `/iglunix/`

## Phase 3: Boot

Use virt-manager or qemu to boot the `iglunix.img`.

Execute QEMU directly with the following command:

```
qemu-system-x86_64 path/to/disk -enable-kvm -m 4096
```

NOTE: Qemu is broken if you don't pass `-m`
-->

## Trivia

Everything in trivia is not important.

* The name `Iglunix`
This comes from the following reasoning, by yours truly aheirman.
```
∄GNU      --> iglu
iglu-unix --> iglunix
```


* The location to place the git repository of `iglunix` in the filesystem is controversial. These are the contenders: 

```
  /iglunix
  /root/iglunix
  /usr/src/iglunix
```

The `iglunix` repo tries to be agnostic to the install dir. This repo choses (because it must choose) for `/root/iglunix`.


Further reading:
*	https://www.youtube.com/watch?v=nGSNULpHHZc
*	https://docs.docker.com/network/overlay/
*	https://docs.docker.com/registry/

