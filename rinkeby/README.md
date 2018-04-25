# Contract deployment scripts for [Rinkeby](https://www.rinkeby.io/) network

## Rinkeby node setup

```
sudo apt-get install -y ethereum
wget -q https://www.rinkeby.io/rinkeby.json
geth init rinkeby.json
nohup geth --rinkeby > geth.log 2>&1 &
```

It will start Rinkeby full node in background with all logs written
to the ``geth.log`` file.

## Attach to the running Rinkeby node

```
geth attach ~/.ethereum/rinkeby/geth.ipc
```

## Deploy EnvisionX contracts to the network

Prerequisites:

* Your Rinkeby node must be in sync with rest of the network before
your deploy.
* Examine and edit ``deploy.conf`` configuration file. There are
a lot of mandatory settings.
* When done, type:

```
make
```
