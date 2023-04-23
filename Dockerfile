FROM ubuntu:22.04

RUN apt update && apt upgrade -y

RUN apt install ruby-full build-essential zlib1g-dev -y

RUN echo '# Install Ruby Gems to ~/gems' >> ~/.bashrc && \
    echo 'export GEM_HOME="$HOME/gems"' >> ~/.bashrc && \
    echo 'export PATH="$HOME/gems/bin:$PATH"' >> ~/.bashrc

RUN gem install jekyll bundler

RUN apt install git vim -y

WORKDIR /root

RUN git clone https://github.com/nglee/nglee.github.io.git

RUN cd nglee.github.io && \
    bundle install
