# CLion remote builds

The container is the build target. CLion SSHes in, syncs your source
over SFTP, runs CMake remotely, and streams output back. Local and
remote build directories stay separate -- name remote ones with a
`-remote` suffix so they don't collide.

This walkthrough assumes a CMake project. Makefile-only projects don't
integrate cleanly -- convert to CMake first.

## Add a remote toolchain

**CLion > Settings > Build, Execution, Deployment > Toolchains**

1. Click **+** and pick **Remote Host**.
2. Name it something memorable, e.g. `dev VM`.
3. Next to **Credentials**, click the gear icon and pick **+** to create
   a new SSH configuration:
   - **Host**: `<fqdn>`
   - **Port**: your container's host port (the `<port>:22` in
     `containers/docker-compose.yml`)
   - **Username**: `root`
   - **Authentication type**: `Key pair`
   - **Private key file**: the key you deployed with (`~/.ssh/id_ed25519`
     by default)

   Click **Test Connection**.
4. Back in the toolchain dialog, the lower fields auto-detect once the
   SSH connection is up:
   - **CMake**: `/usr/bin/cmake`
   - **Build Tool**: `/usr/bin/make`
   - **C Compiler / C++ Compiler**: `/usr/bin/gcc`, `/usr/bin/g++`
   - **Debugger**: `/usr/bin/gdb`

   If any shows "Detect failed", check the SSH connection first.
5. Click **Apply**.

## Add a CMake profile

**Settings > Build, Execution, Deployment > CMake**

1. Click **+** to add a new profile.
2. **Name**: `Debug-remote` (or whatever you like).
3. **Build type**: `Debug`.
4. **Toolchain**: the `dev VM` toolchain you just made.
5. **Generator**: default (`Let CMake decide`).
6. **CMake options**: empty -- the project's `CMakeLists.txt` already
   sets what's needed.
7. **Build directory**: `cmake-build-debug-remote`. Anything ending in
   `-remote` works; the suffix keeps remote builds from colliding with
   local ones.
8. Click **OK**.

CLion starts the first remote sync immediately; the status bar shows
progress. Subsequent syncs are incremental.

## Open the project and select the profile

1. **File > Open** and pick the project root.
2. Trust the project when prompted, then wait for the first CMake
   reload to finish.
3. In the top toolbar, the CMake profile dropdown should show
   `Debug-remote`. Switch to it if it shows a different profile.

## Build the project

**Build > Build Project** (or `Cmd-F9` on macOS).

The build runs on the VM, not locally; CLion syncs artifacts back to
your laptop automatically. First build takes a couple minutes.

## Run and debug

1. Top-toolbar **Run/Debug Configurations** dropdown > **Edit
   Configurations**.
2. Each CMake target gets an auto-generated configuration.
3. **Program arguments**: as needed.
4. **Working directory**: default (`$ProjectFileDir$`); the remote
   toolchain remaps it correctly.

Debugging works as usual: set breakpoints in CLion; gdb runs on the VM
and CLion drives it. No extra setup for breakpoints, watches, or
stepping.

## After a redeploy

The FQDN is stable across redeploys, so CLion's toolchain settings
keep working. The host's SSH key changes, though, so clear the stale
fingerprint:

```bash
ssh-keygen -R '[<fqdn>]:<port>'
```
