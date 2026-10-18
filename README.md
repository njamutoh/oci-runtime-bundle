

```markdown
# OCI Runtime Bundle

Creating a runtime-ready OCI bundle from Arch Linux primitives in order to understand what happens underneath when a container runtime runs a container.

## Project Goal

The aim of this project is to get a deeper understanding of what happens under the hood when containers are run.

Before going deeper into container orchestration with Kubernetes, I wanted to understand what is actually being orchestrated.

Instead of starting with higher-level container engines such as Docker or Podman, this project works closer to the Linux and OCI layers.

The goal is simple:

> Use `runc` to start a minimal container that runs a Python application and prints `hello world` to the terminal.

## Environment and Tools

My setup is:

- Arch Linux
- `runc` — the low-level OCI container runtime
- `pacstrap` — used to build a minimal Arch root filesystem
- Python
- Git

Docker and Podman are deliberately avoided here because they provide many higher-level conveniences that would hide the pieces I am trying to understand.

## OCI Runtime Bundle

At a high level, an OCI runtime bundle has two main parts:

```text
bundle/
├── config.json
└── rootfs/
```

### `rootfs`

The `rootfs` is the filesystem that the containerized process will see as `/`.

It contains things such as:

- the application
- application binaries
- shared libraries
- configuration files
- normal Linux directories such as:
  - `/etc`
  - `/usr`
  - `/bin`
  - `/var`
  - `/tmp`

In this project, the Python application eventually exists inside the root filesystem as:

```text
/app/app.py
```

### `config.json`

`config.json` contains the runtime configuration that tells `runc` how the container should be created and executed.

It can define things such as:

- the command or process to run
- environment variables
- working directory
- hostname
- UID and GID
- mounts
- Linux namespaces
- resource controls and cgroup settings
- capabilities
- other Linux runtime settings

The initial `config.json` is generated using:

```bash
runc spec
```

This generates a generic OCI-compliant configuration.

It then has to be adjusted for the application being run.

For example, instead of starting a shell, the process arguments can be changed so that `runc` starts:

```text
/usr/bin/python /app/app.py
```

## Mental Model

```text
Arch Linux Host
      |
      | pacstrap
      v
bundle/rootfs/
      |
      | contains
      v
Linux userspace + Python + app.py

bundle/config.json
      |
      | describes how the process should run
      v
runc
      |
      | uses Linux kernel primitives
      v
namespaces + cgroups + mounts + capabilities
      |
      v
python /app/app.py
      |
      v
hello world
```

The key idea is:

> `rootfs` defines what exists inside the container, while `config.json` defines how the container should run.

## Project Structure

```text
oci-runtime-bundle/
├── app.py
├── build-rootfs.sh
├── .gitignore
├── README.md
└── bundle/
    ├── config.json
    └── rootfs/
        └── app/
            └── app.py
```

The generated `rootfs` is excluded from Git.

The repository should instead contain the instructions and scripts required to recreate it.

## Procedure

### 1. Install the required tools

On Arch Linux, install or verify the required tools:

```bash
sudo pacman -S runc arch-install-scripts python git
```

`pacstrap` is provided by the `arch-install-scripts` package.

### 2. Create the project directory

```bash
mkdir -p ~/PROJECTS/oci-runtime-bundle
cd ~/PROJECTS/oci-runtime-bundle
```

### 3. Create the application

Create the file:

```bash
vim app.py
```

Add:

```python
print("hello world")
```

Test it on the host:

```bash
python app.py
```

Expected output:

```text
hello world
```

### 4. Create the OCI bundle structure

```bash
mkdir -p bundle/rootfs
```

The root filesystem directory should be owned by root before installing the Arch userspace:

```bash
sudo chown root:root bundle/rootfs
```

### 5. Build the root filesystem

Use `pacstrap` to install a minimal Arch userspace and Python into the root filesystem:

```bash
sudo pacstrap -c bundle/rootfs base python
```

This does not copy the host filesystem.

It installs a fresh Arch userspace into:

```text
bundle/rootfs/
```

### 6. Copy the application into the rootfs

Create an application directory:

```bash
sudo mkdir -p bundle/rootfs/app
```

Copy the Python application:

```bash
sudo cp app.py bundle/rootfs/app/
```

The host sees:

```text
bundle/rootfs/app/app.py
```

Inside the container, this appears as:

```text
/app/app.py
```

### 7. Generate the OCI runtime configuration

Move into the bundle:

```bash
cd bundle
```

Generate the default OCI configuration:

```bash
runc spec
```

This creates:

```text
config.json
```

### 8. Configure the process

Edit `config.json` so that the process arguments run:

```text
/usr/bin/python /app/app.py
```

For example:

```json
"args": [
  "/usr/bin/python",
  "/app/app.py"
]
```

### 9. Run the container

From inside the bundle directory:

```bash
sudo runc run bundle
```

Expected output:

```text
hello world
```

At this point, `runc` has read the OCI bundle, configured the containerized process using Linux kernel mechanisms, and executed the Python application from inside the root filesystem.

## Reproducibility

The generated `bundle/rootfs/` should not be committed to Git.

The `.gitignore` file contains:

```text
bundle/rootfs/
```

A `build-rootfs.sh` script is used to recreate the root filesystem when needed.

Example:

```bash
#!/usr/bin/env bash
set -e

mkdir -p bundle/rootfs
sudo chown root:root bundle/rootfs

sudo pacstrap -c bundle/rootfs base python

sudo mkdir -p bundle/rootfs/app
sudo cp app.py bundle/rootfs/app/
```

Make the script executable:

```bash
chmod +x build-rootfs.sh
```

Then it can be used later to recreate the generated filesystem.

## End-to-End Flow

```text
app.py
  |
  | copied into
  v
rootfs
  |
  | combined with
  v
config.json
  |
  | forms
  v
OCI runtime bundle
  |
  | consumed by
  v
runc
  |
  | asks the Linux kernel to configure
  v
namespaces + cgroups + mounts + capabilities
  |
  v
containerized Python process
  |
  v
hello world
```

## What I Learned

This project helped make one important idea much clearer:

A container is not one single Linux feature.

It is a process running with a filesystem and a set of Linux isolation and resource-control mechanisms around it, while still sharing the host Linux kernel.

Working directly with `rootfs`, `config.json`, and `runc` made it much easier to see what higher-level tools such as Docker and Kubernetes are abstracting away.
```

One small note before you paste it: if your actual command was `sudo runc run bundle` and that worked from inside the `bundle/` directory, keep it exactly as written. If you were in the parent directory when you ran it, then we should adjust that line before you publish.
