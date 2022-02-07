# LoRaWAN 2.4GHz Packet Forwarder Protocol for Docker

This project deploys UDP Packet Forwarder protocol for LoRa 2.4GHz Gateways using Docker. It runs on any amd64/x86_64 PC, or a SBC like a Raspberry Pi 3/4, Compute Module 3/4 or balenaFin.

## Introduction

Deploy a UDP Packet Forwarder protocol using a 2.4GHz Gateway in a docker container in your computer, Raspberry Pi or compatible SBC.

Main features:

* Support for AMD64 (x86_64), ARMv8, ARMv7 and ARMv6 architectures.
* Support for LoRa 2.4GHz concentrators.
* Compatible with The Things Stack (Comunity Edition / TTNv3) or Chirpstack LNS amongst others.
* Almost one click deploy and at the same time highly configurable.

More about [LoRa 2.4GHz Gateway](https://www.semtech.com/products/wireless-rf/lora-24ghz).

This project is based on [2.GHz Gateway HAL](https://github.com/Lora-net/gateway_2g4_hal) code by Semtech.

This project is available on Docker Hub (https://hub.docker.com/r/xoseperez/2g4-packet-forwarder) and GitHub (https://github.com/xoseperez/2g4-packet-forwarder).

This project has been tested with The Things Stack Community Edition (TTSCE or TTNv3).


## Requirements


### Hardware

As long as the host can run docker containers, the 2.4GHz Gateway UDP Packet Forwarder service can run on:

* AMD64: most PCs out there
* ARMv8: Raspberry Pi 3/4, 400, Compute Module 3/4, Zero 2 W,...
* ARMv7: Raspberry Pi 2
* ARMv6: Raspberry Pi Zero, Zero W

> **NOTE**: you will need an OS in the host machine, for some SBC like a Raspberry Pi that means and SD card with an OS (like Rasperry Pi OS) flashed on it.


#### LoRa Concentrators

Tested with:

* [Semtech SX1280ZXXXXGW1](https://www.semtech.com/products/wireless-rf/lora-24ghz/sx1280zxxxxgw1)


> **NOTE**: USB concentrators in MiniPCIe form factor will require a USB adapter to connect them to a USB2/3 socket on your PC or SBC. Other form factors might also require an adaptor for the target host.


### Software

You will need docker and docker-compose (optional but recommended) on the machine (see below for instal·lation instructions). You will also need a an account at a LoRaWAN Network Server, for instance a [The Things Stack V3 account](https://console.cloud.thethings.network/).

> You can also deploy this using balenaCloud, check the `Deploy with balena` section below.


## Installing docker & docker-compose on the OS

If you don't have docker running on the machine you will need to install docker on the OS first. This is pretty straight forward, just follow these instructions:

```
sudo apt-get update && sudo apt-get upgrade -y
curl -sSL https://get.docker.com | sh
sudo usermod -aG docker ${USER}
newgrp docker
sudo apt install -y python3 python3-dev python3-pip libffi-dev libssl-dev
sudo pip3 install docker-compose
sudo systemctl enable docker
```

Once done, you should be able to check the instalation is alright by testing:

```
docker --version
docker-compose --version
```


## Deploy the code

### Via docker-compose

You can use the `docker-compose.yml` file below to configure and run your instance of UDP Packet Forwarder:

```
version: '2.0'

services:

  2g4-packet-forwarder:
    image: xoseperez/2g4-packet-forwarder:latest
    container_name: 2g4-packet-forwarder
    restart: unless-stopped
    privileged: true
    network_mode: host
```

You can add environment variables to match your setup (see the `Service Variables` section below). You will need to know the Gateway EUI to register it in your LoraWAN Network Server. Check the `Get the EUI of the LoRa Gateway` section below to know how. Otherwise, check the logs messages when the service starts to know the Gateway EUI to use.

### Build the image (not required)

In case you can not pull the already built image from Docker Hub or if you want to customize the cose, you can easily build the image by using the [buildx extension](https://docs.docker.com/buildx/working-with-buildx/) of docker and push it to your local repository by doing:

```
docker buildx bake --load aarch64
```

Once built (it will take some minutes) you can bring it up by using `xoseperez/2g4-packet-forwarder:aarch64` as the image name in your `docker-compose.yml` file. If you are not in an ARMv8 64 bits machine (like a Raspberry Pi 4) you can change the `aarch64` with `arm` (ARMv6 and ARMv7) or `amd64`.


### Deploy with balena

[![balena deploy button](https://www.balena.io/deploy.svg)](https://dashboard.balena-cloud.com/deploy?repoUrl=https://github.com/xoseperez/2g4-packet-forwarder/)

You need to set the variables upon deployment. See the `Service Variables` section below.

## Configure the Gateway

### Service Variables

These variables you can set them under the `environment` tag in the `docker-compose.yml` file or using an environment file (with the `env_file` tag). 

Variable Name | Value | Description | Default
------------ | ------------- | ------------- | -------------
**`DEVICE`** | `STRING` | Where the concentrator is connected to. | `/dev/ttyACM0`
**`GATEWAY_EUI_NIC`** | `STRING` | Interface to use when generating the EUI | `eth0`
**`GATEWAY_EUI`** | `STRING` | Gateway EUI to use | Autogenerated from `GATEWAY_EUI_NIC` if defined, otherwise in order from: `eth0`, `wlan0`, `usb0`
**`TTN_REGION`** | `STRING` | If using a TTN server, region of the TTN server to use | `eu1`
**`SERVER_HOST`** | `STRING` | URL of the server | If `TTN_REGION` is defined it will build the right address for the TTN server
**`SERVER_PORT`** | `INT` | Port the server is listening to | 1700
**`GPS_LATITUDE`** | `DOUBLE` | Report this latitude for the gateway | 
**`GPS_LONGITUDE`** | `DOUBLE` | Report this longitude for the gateway | 
**`GPS_ALTITUDE`** | `DOUBLE` | Report this altitude for the gateway | 

Notes: 

> The service will generate a Gateway EUI based on an existing interface. It will try to find `eth0`, `wlan0` or `usb0`. If neither of these is available it will try to identify the most used existing interface. But this approach is not recommended, instead define a specific and unique custom `GATEWAY_EUI` or identify the interface you want the service to use to generate it by setting `GATEWAY_EUI_NIC`.

> `SERVER_HOST` and `SERVER_PORT` values default to The Things Stack Community Edition european server (`udp://eu1.cloud.thethings.network:1700`). If your region is not EU you can change it using ```TTN_REGION```. At the moment only these regions are available: `eu1`, `nam1` and `au1`.


### Get the EUI of the LoRa Gateway

LoRa gateways are manufactured with a unique 64 bits (8 bytes) identifier, called EUI, which can be used to register the gateway on the LoRaWAN Network Server. You can check the gateway EUI (and other data) by inspecting the service logs or running the command below while the container is up:

```
docker exec -it 2g4-packet-forwarder ./get_eui.sh
```

### Use a custom radio configuration

In some special cases you might want to specify the radio configuration in detail (frequencies, power, ...). You can do that by providing a custom `global_conf.json` file. You can start by copying the default one based on your current configuration from a running instance of the service:

```
docker cp 2g4-packet-forwarder:/app/global_conf.json global_conf.json
```

Now you can modify it to match your needs. And finally define it as a mounted file in your `docker-compose.yml` file. When you do a `docker-compose up -d` it will use your custom file instead of a generated one.

```
version: '2'

services:

  2g4-packet-forwarder:
    image: xoseperez/2g4-packet-forwarder:latest
    container_name: 2g4-packet-forwarder
    restart: unless-stopped
    privileged: true
    network_mode: host
    volumes:
      - ./global_conf.json:/app/global_conf.json:ro
```

Please note that a `local_conf.json` file will still be generated and will overwrite some of the settings in the `global_conf.json`, but only in the `gateway_conf` section.

### Register your gateway to The Things Stack

1. Sign up at [The Things Stack console](https://console.cloud.thethings.network/).
2. Click `Go to Gateways` icon.
3. Click the `Add gateway` button.
4. Introduce the data for the gateway (at least an ID, the EUI and the frequency plan).
6. Click `Create gateway`.


## Troubleshoothing

Feel free to introduce issues on this repo and contribute with solutions.

## License

The contents of this repository (not of those repositories linked or used by this one) are under BSD 3-Clause License.

Copyright (c) 2022 Xose Pérez <xose.perez@gmail.com>
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice,
   this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.
3. Neither the name of this project nor the names of its
   contributors may be used to endorse or promote products derived from
   this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.
