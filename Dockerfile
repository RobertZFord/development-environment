# build with `podman build . -t dev-env`
# create with `toolbox create --image dev-env dev-box`
# enter it with `toolbox enter dev-box`
# run things from it with `toolbox run --container dev-box code`

# download the rust installer
FROM registry.fedoraproject.org/fedora-toolbox:39 AS temp
RUN curl https://static.rust-lang.org/dist/rust-1.77.1-x86_64-unknown-linux-gnu.tar.gz | zcat | tar --extract --directory=/tmp

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
RUN --mount=type=bind,from=temp,source=/tmp,target=/rust-install /rust-install/rust-1.77.1-x86_64-unknown-linux-gnu/install.sh
# `rustc` and `cargo` et al should be accessible
RUN dnf --assumeyes install gcc
# `cc` is now available for `cargo build`

#ENV PNPM_HOME=/usr/local/share/pnpm
## Typescript
RUN dnf --assumeyes install nodejs
#RUN npm install --global typescript
#RUN npm install --global pnpm
#RUN npm install --global vite
RUN npm install --global typescript pnpm vite esbuild
## `tsc` and `node` should be accessible

#RUN npm install -g pnpm
#RUN SHELL=sh ENV=$HOME/.bashrc pnpm setup
#RUN PATH=$PNPM_HOME:$PATH      pnpm add -g typescript
#RUN PATH=$PNPM_HOME:$PATH      pnpm add -g vite
