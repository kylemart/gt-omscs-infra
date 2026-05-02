# CLion remote builds

The container is the build target. CLion will SSH to it on port 2222 as
`root`, sync the source over SFTP, run CMake there, and stream the output
back. The local `cmake-build-*` directories on your laptop stay separate
from the remote build artifacts under the container's `/tmp/`.

The walkthrough below uses `pr4/` as the project. Substitute the path for
your other course projects.

## Add a remote toolchain

**CLion > Settings > Build, Execution, Deployment > Toolchains**

1. Click **+** and pick **Remote Host**.
2. Name it something memorable, e.g. `gios-env (test VM)`.
3. Next to **Credentials**, click the gear icon > **+** to create a new SSH
   configuration:
   - **Host**: the VM's public IP (printed by `deploy.sh`, e.g. `20.62.97.41`)
   - **Port**: `2222`
   - **Username**: `root`
   - **Authentication type**: `Key pair`
   - **Private key file**: `~/.ssh/id_ed25519` (or whichever key you
     deployed with)
   - Click **Test Connection** — should succeed in under a second.
4. Back in the toolchain dialog, the lower fields auto-detect once the SSH
   connection is up:
   - **CMake**: `/usr/bin/cmake` (3.22.x)
   - **Build Tool**: `/usr/bin/make`
   - **C Compiler / C++ Compiler**: `/usr/bin/gcc`, `/usr/bin/g++`
   - **Debugger**: `/usr/bin/gdb`

   If any field shows "Detect failed", double-check the SSH connection
   first — almost always a key or host issue, not a missing tool.
5. Click **Apply**.

## Add a CMake profile

**Settings > Build, Execution, Deployment > CMake**

1. Click **+** to add a new profile.
2. **Name**: `Debug-remote` (or whatever you like).
3. **Build type**: `Debug`.
4. **Toolchain**: select the `gios-env (test VM)` toolchain you just made.
5. **Generator**: leave at default (`Let CMake decide`).
6. Leave **CMake options** empty unless you have a reason — the project's
   `CMakeLists.txt` already sets the flags.
7. **Build directory**: `cmake-build-debug-remote` (anything ending in
   `-remote` so it doesn't collide with local builds).
8. Click **OK**.

CLion will start the first remote sync immediately. Watch the status bar —
it'll say "Uploading…" then "CMake project reload…". On a fresh VM the
first sync uploads the whole project tree (a minute or two for `pr4/`,
mostly the proto-generated files). Subsequent syncs are incremental.

## Open the project and select the profile

1. **File > Open** and pick the project root.
2. Trust the project when prompted.
3. Wait for CLion to detect the CMake project and finish the first reload.
4. In the top toolbar, the CMake profile dropdown should show
   `Debug-remote`. If it shows a different profile, switch to the remote
   one.

## Build

**Build > Build Project** (or `⌘F9` on macOS).

The build runs on the VM, not locally. Output binaries land in
`pr4/bin/` on the remote side; CLion syncs them back automatically. First
build takes a couple minutes (gRPC and protobuf compilation).

If the build fails with a CMake error about missing `protoc` or
`grpc_cpp_plugin`, the toolchain isn't pointing at the container —
it's most likely connected to the host (port 22) instead of the container
(port 2222). Check the SSH configuration's port.

## Run and debug

The pr4 project produces four binaries:
`dfs-server-p1`, `dfs-client-p1`, `dfs-server-p2`, `dfs-client-p2`.

1. Top-toolbar **Run/Debug Configurations** dropdown > **Edit
   Configurations**.
2. Each binary should already have an auto-generated configuration. If
   not, click **+** > **CMake Application** and pick the target.
3. Set **Program arguments** as needed (e.g. `--mount /tmp/server-mount`
   for the server).
4. **Working directory**: leave at the default (`$ProjectFileDir$`) — the
   remote toolchain remaps it correctly.
5. Run server first (typically), then client.

Debugging works the same way — set breakpoints in CLion as usual; gdb runs
on the VM under the hood and CLion drives it locally. No extra setup
needed for breakpoints, watches, or stepping.

## When the VM IP changes

The public IP is allocated as `Static`, so it stays constant for as long
as the VM exists. If you tear down and redeploy, you'll get a new IP. Two
things to update:

1. **CLion**: Settings > Build > Toolchains > your toolchain >
   Credentials > edit Host. CLion picks up the change without rebuilding
   anything.
2. **Local SSH known_hosts**: `ssh-keygen -R '[old-ip]:2222'` and
   `ssh-keygen -R old-ip` to drop stale fingerprints.
