# syntax = docker/dockerfile:1.4

#imagine per fare la build della gemma
FROM ruby:2.7 as building

RUN mkdir /builder
WORKDIR /builder
COPY . .
RUN gem build swarm_cluster_cli_ope.gemspec -o swarm_cluster_cli_ope.gem


FROM ruby:2.7
LABEL authors="Marino Bonetti"


RUN adduser --disabled-password --gecos "" dev_user
#ENV HOME="/home/dev_user"
ENV USER=dev_user

RUN apt update && apt install -y ca-certificates curl gnupg rsync

RUN curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh && \
    usermod -aG docker $USER

RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

RUN wget https://github.com/digitalocean/doctl/releases/download/v1.94.0/doctl-1.94.0-linux-amd64.tar.gz && \
    tar xf doctl-1.94.0-linux-amd64.tar.gz && \
    mv doctl /usr/local/bin

#COPY --from=building /builder/swarm_cluster_cli_ope.gem .
#RUN gem install --user-install ./swarm_cluster_cli_ope.gem # swarm_cluster_cli_ope
#RUN mkdir /builder && cd /builder
#COPY . .
#RUN bundle install && bundle exec rake install

RUN gem install swarm_cluster_cli_ope -v 0.8.2
RUN chmod -R ugo+rwt /usr/local/bundle


# qua andremo a montare la $PWD
WORKDIR /application

#ENTRYPOINT ["swarm_cli_ope"]