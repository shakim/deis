# Provision a Deis Cluster on Amazon EC2

## Install the [AWS Command Line Interface][aws-cli]:
```console
$ pip install awscli
Downloading/unpacking awscli
  Downloading awscli-1.3.6.tar.gz (173kB): 173kB downloaded
  ...
```

## Configure aws-cli
Run `aws configure` to set your AWS credentials:
```console
$ aws configure
AWS Access Key ID [None]: ***************
AWS Secret Access Key [None]: ************************
Default region name [None]: us-west-1
Default output format [None]:
```

## Upload keys
Generate and upload a new keypair to AWS, ensuring that the name of the keypair is set to "deis".
```console
$ ssh-keygen -q -t rsa -f ~/.ssh/deis -N '' -C deis
$ aws ec2 import-key-pair --key-name deis --public-key-material file://~/.ssh/deis.pub
```

## Choose number of instances
By default, the script will provision 3 servers. You can override this by setting `DEIS_NUM_INSTANCES`:
```console
$ export DEIS_NUM_INSTANCES=5
```

Note that for scheduling to work properly, clusters must consist of at least 3 nodes and always have an odd number of members.
For more information, see [optimal etcd cluster size](https://github.com/coreos/etcd/blob/master/Documentation/optimal-cluster-size.md).

Deis clusters of less than 3 nodes are unsupported.

## Choose number of routers
By default, the Makefile will provision 1 router. You can override this by setting `DEIS_NUM_ROUTERS`:
```console
$ export DEIS_NUM_ROUTERS=2
```

## Customize user-data
Edit [user-data](../coreos/user-data) and add a new discovery URL.
You can get a new one by sending a request to http://discovery.etcd.io/new.

## Customize cloudformation.json
By default, this script spins up m3.large instances. You can override this
by adding a new entry to [cloudformation.json](cloudformation.json) like so:

```
    {
        "ParameterKey":     "InstanceType",
        "ParameterValue":   "m3.xlarge"
    }
```

The only entry in cloudformation.json required to launch your cluster is `KeyPair`,
which is already filled out. The defaults will be applied for the other settings.

## Choose whether to launch into a VPC

The provision script supports launching into Amazon VPC. You'll need to have already created and
configured your VPC with at least one subnet and an internet gateway for the nodes.

To launch your cluster into a VPC, export three additional environment variables: ```VPC_ID```,
```VPC_SUBNETS```, ```VPC_ZONES```. ```VPC_ZONES``` must list the availability zones of the
subnets in order.

For example, if your VPC has ID ```vpc-a26218bf``` and consists of the subnets ```subnet-04d7f942```
(which is in ```us-east-1b```) and ```subnet-2b03ab7f``` (which is in ```us-east-1c```) you would
export:

```
export VPC_ID=vpc-a26218bf
export VPC_SUBNETS=subnet-04d7f942,subnet-2b03ab7f
export VPC_ZONES=us-east-1b,us-east-1c
```

## Run the provision script
Run the [cloudformation provision script][pro-script] to spawn a new CoreOS cluster:
```console
$ cd contrib/ec2
$ ./provision-ec2-cluster.sh
{
    "StackId": "arn:aws:cloudformation:us-west-1:413516094235:stack/deis/9699ec20-c257-11e3-99eb-50fa01cd4496"
}
Your Deis cluster has successfully deployed.
Please wait for all instances to come up as "running" before continuing.
```

## Initialize the cluster
Once the cluster is up, get the hostname of any of the machines from EC2, set
FLEETCTL_TUNNEL, and issue a `make run` from the project root:
```console
$ ssh-add ~/.ssh/deis
$ export FLEETCTL_TUNNEL=ec2-12-345-678-90.us-west-1.compute.amazonaws.com
$ cd ../.. && make run
```
The script will deploy Deis and make sure the services start properly.

## Configure DNS
While you can reference the controller and hosted applications with public hostnames provided by EC2, it is recommended for ease-of-use that
you configure your own DNS records using a domain you own. See [Configuring DNS](http://docs.deis.io/en/latest/installing_deis/configure-dns/) for details.

## Use Deis!
After that, register with Deis!
```console
$ deis register http://deis.example.org
username: deis
password:
password (confirm):
email: info@opdemand.com
```

## Hack on Deis
If you'd like to use this deployment to build Deis, you'll need to set `DEIS_HOSTS` to an array of your cluster hosts:
```console
$ DEIS_HOSTS="1.2.3.4 2.3.4.5 3.4.5.6" make build
```

This variable is used in the `make build` command.

[aws-cli]: https://github.com/aws/aws-cli
[template]: https://s3.amazonaws.com/coreos.com/dist/aws/coreos-alpha.template
[pro-script]: provision-ec2-cluster.sh
