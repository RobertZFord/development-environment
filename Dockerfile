# build with `podman build . -t dev-env`
# create with `toolbox create --image dev-env dev-box`
# enter it with `toolbox enter dev-box`
# run things from it with `toolbox run --container dev-box code`

ARG RUST_VERSION=1.77.1

# download the rust installer
FROM registry.fedoraproject.org/fedora-toolbox:39 AS temp
ARG RUST_VERSION
RUN curl https://static.rust-lang.org/dist/rust-${RUST_VERSION}-x86_64-unknown-linux-gnu.tar.gz | zcat | tar --extract --strip-components=1 --directory=/tmp

# start from the default fedora toolbox
FROM registry.fedoraproject.org/fedora-toolbox:39

## Visual Studio Code + .NET
# as per https://code.visualstudio.com/docs/setup/linux
RUN rpm --import https://packages.microsoft.com/keys/microsoft.asc
RUN sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
# --assumeyes prevents the build process from dying when dnf reads from STDIN
RUN dnf --assumeyes install code dotnet-sdk-6.0 dotnet-sdk-8.0
# `code` from inside the container should now launch VSC
# `dotnet` should also be accessible

## Rust
# install rust from the standalone installer
RUN --mount=type=bind,from=temp,source=/tmp,target=/rust-install /rust-install/install.sh
# `rustc` and `cargo` et al should be accessible
RUN dnf --assumeyes install gcc
# `cc` is now available for `cargo build`

## Typescript
RUN dnf --assumeyes install nodejs

# the usual uid:gid
ARG USER="1000:1000"
# this will *not* override existing environment variables
ENV PNPM_HOME=/usr/local/lib/pnpm

RUN npm install --global pnpm
# this writes to /root/.bashrc, which doesn't fire when the user logs in
# however, if we put:
#
#   case ":$PATH:" in
#     *":$PNPM_HOME:"*) ;;
#     *) export PATH="$PNPM_HOME:$PATH" ;;
#   esac
#
# at the end of the user's .bashrc, it adds the above environment variable to
# the path on toolbox startup
# (this is basically what `pnpm setup` adds to the bashrc file)

RUN SHELL=sh ENV=$HOME/.bashrc pnpm setup
RUN PATH=$PNPM_HOME:$PATH pnpm add --global typescript vite esbuild
RUN chown -R $USER $PNPM_HOME
