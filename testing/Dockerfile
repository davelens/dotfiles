FROM archlinux:base

# Install minimal dependencies needed for dotfiles installation
RUN pacman -Syu --noconfirm git python sudo openssh curl

# Create a non-root test user with passwordless sudo
RUN useradd -m -s /bin/bash testuser && \
    echo "testuser ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
USER testuser
WORKDIR /home/testuser/dotfiles

# Set required environment variable
ENV DOTFILES_REPO_HOME=/home/testuser/dotfiles

# Copy dotfiles
COPY --chown=testuser:testuser . .

# Initialize git repo and submodules (needed because COPY doesn't preserve git state)
RUN git config --global --add safe.directory /home/testuser/dotfiles && \
    git init && git submodule update --init --recursive

# Remove default bash files so dotbot can link ours
RUN rm -f ~/.bash_profile ~/.bashrc

CMD ["/bin/bash", "--login"]
