# NFVIS Test Harness

The NFVIS Test Harness is an NFVIS host (e.g. Cisco ENCS 5400, UCS, etc) and a set of tools used to test NFVIS on 3rd party hardware.  It can:

* Create a PXE environment to install NFVIS on the test
* Create packages and install them onto the NFVIS host
* Deploy test architectures on the the NFVIS host being tested
* Test those architectures with packet flows
* Clean up the architectures

## Overview

The NFVIS Harness host is used as an environment in which to deploy a PXE server, control node, test nodes, and other
hosts for testing (e.g. source/sync hosts, viptela control plane, etc.)

## Build 3rd Party Hardware ISO

### Requirements for building ISO:

* Place ISO for NFVIS >= 3.12.0 into `images` directory

### Build ISO

```bash
./build-iso.sh
```

> **Extra Vars**
>
> * `image_dir`: The directory that contains the ISO images (default: `./images`)
> * `tmp_dir`: The temp directory in which the ISO is created (default: `/tmp`)
> * `old_iso`: The original ISO
> * `new_iso`: The new ISO (default: `nfvis_3phw.iso`)
> * `nfvis_3phw`: The name of the 3rd party hardware JSON file (default: `nfvis_3phw.json`) 
> * `volume_id`: (default: `NFVIS3PHW`)
> ```bash
> ./build-iso.sh -e old_iso=Cisco_NFVIS_BRANCH-3.12.0-257-20190707_165719.iso -e volume_id=NFVIS3PHW_3.12.0
> ```

## Provisioning the Harness

### Setting IP Address of the Harness Hosts

In order to interact with the harness, IP information must be set in harness/harness.yml for the following devices:

* `harness`: Set the values for `ansible_host` and `interfaces.mgmt.ip`. Generally, these values will be the same (with prefix added to the latter) if you want to manage the device via the mgmt interface.
* `dut`: Set the values for `ansible_host` and `interfaces.mgmt.ip`. Generally, these values will be the same (with prefix added to the latter) if you want to manage the device via the mgmt interface.

### Building Packages

```bash
ansible-playbook packages.yml -i harness/harness.yml
```

## Provision the NFVIS hosts

```bash
ansible-playbook provision.yml -i harness/harness.yml
```

### Building the Harness VNFs

* Deploy VNFs on harness

```bash
ansible-playbook build.yml -i harness/harness.yml
```

### Prepare the Harness VNFs

* Wait for VMs to boot
* Install required packages

```bash
ansible-playbook prep-harness.yml -i harness/harness.yml
```

### Cleaning the Harness VNFs

* Clean VNFs on harness

```bash
ansible-playbook clean.yml -i harness/harness.yml
```

## Architecture Testing

The NFVIS Validation Harness is written so that it can deploy different test scenarios.  For example, the scenario above
depicts a service chain deployment of an ISRv and an ASAv.  It can also deploy a simple ISRv router or a more complex SD-WAN
scenario.

![test_harness](isrv_asav_test.png)

The scenarios are created through Ansible inventory files that include the associated NFVIS hosts, the network configuration,
and the VNFs.  The VNFs are seeded with a template-driven boot-up configuration so that they come up with the required
configuration for the architecture.  They can also be automated post deployment for more complex deployment scenarios (e.g. setting up the SD-WAN).

### Prepare the DUT

* Copies VNF images to DUT

```bash
./play.sh prep-dut.yml -i harness/harness.yml
```

### Build Architecture

```bash
./play.sh build.yml -i harness/isr_asa1.yml 
```

### Test Architecture

* Runs iperf test from test host to control host

```bash
./play.sh iperf-test.yml -i harness/harness.yml -e time=30 -e test_name=asr-isr
```
>Note: The harness inventory is specificed because the test us run between harness VNFs

>Note: iperf testing is limited by the license limit of the VNFs.

### Clean Architecture

```bash
ansible-playbook clean.yml -i harness/isr_asa1.yml -l dut,vnf
```
>Note: must limit, otherwise you will get failures when trying to delete networks from the harness

## Load Testing

The Load Test consists of a series of daisy chaned ISRvs (i.e. snake).  The number of ISRvs
depends on the cores available on the DUT (i.e. 1 ISRv per core, but configurable).  The tooling below performs the following:

* Creates the bridges and networks to stitch the VNFs together on the DUT
* Instantiates the VNFs with 0-day configurations for the interface, routes, and OSPF peering.
* Waits for the VNF to become active
* Registers the VNF to the specified smart account and waits for it to be authorized
* Runs a bandwith test from the test node on the harness through the snake to the control node on the harness
* De-registers the VNF from the smart account
* Cleans up the VNFs, bridges, and networks from the DUT
* Cleans up the DUT's ssh host keys

![test_harness](snake_test.png)

### Prepare the DUT

>Note: this is not necessary if you already prepared it for the ISR/ASR test
```bash
./play.sh prep-dut.yml -i harness/harness.yml
```
### Build the Snake

* Finds available cores
* Creates VNFs, bridges, & networks

```bash
./play.sh -i harness/harness build_snake.yml
```

> **Extra Vars**
>
> * `max_vnf`: The maximum number of VNF to spin up on the DUT
> 
> ```bash
> ansible-playbook build-snake.yml -e max_vnf=5
> ```

### Prepare the Snake

* Get list of snake VNFs from DUT
* Waits for the VNF to boot
* Sets Smart Licensing parameters
* Registers VNF to Smart Licensing
* Waits for successful registration

```bash
ansible-playbook prep-snake.yml
```

### Test the Snake

* Runs iperf test from test host to control host

```bash
./play.sh iperf-test.yml -i harness/harness.yml -e test_name=snake
```

> **Extra Vars**
>
> * `time`: The duration of the iperf test (default: 60)
>```bash
>./play.sh iperf-test.yml -i harness/harness.yml -e time=30 -e test_name=snake
>```

### Clean the Snake

* Get list of snake VNFs from DUT
* Deregisters VNF from Smart Licensing
* Deletes VNFs, bridges, & networks
* Removes DUT's ssh key from known hosts

```bash
ansible-playbook clean-snake.yml
```

## Provisioning an NFVIS DUT using PXE

When deploying the test harness, a Linux control node is deployed on the harness host.  This host is used to provide NAT for the test VNFs, as well as the VNFs on the DUT (needed for Smart Licensin).  We have also provided scripts to enable the control node to act as a PXE server to the DUT.  If you build the NFVIS ISO as outlined above, you can provision the control host as a PXE server like this:

```bash
./play.sh  -i harness/harness.yml configure-pxe.yml
```

For this to function correctly, you must have the following variables defined for your DUT:
```yaml
netmask: 24
pxe_mac: "00:aa:bb:cc:dd:ee"
pxe_ip: "{{ test_lan_cidr | ipaddr('net') | ipaddr('5') | ipaddr('address') }}
```

Once everything is setup, set your DUT to PXE boot from its WAN interface and NFVIS should install onto the first hard drive.