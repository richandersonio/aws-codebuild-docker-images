FROM amazonlinux:2 AS core

ENV EPEL_REPO="https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm"

# Install git, SSH, and other utilities
RUN set -ex \
    && yum install -y openssh-clients \
    && mkdir ~/.ssh \
    && touch ~/.ssh/known_hosts \
    && ssh-keyscan -t rsa,dsa -H github.com >> ~/.ssh/known_hosts \
    && ssh-keyscan -t rsa,dsa -H bitbucket.org >> ~/.ssh/known_hosts \
    && chmod 600 ~/.ssh/known_hosts \
    && yum install -y $EPEL_REPO \
    && rpm --import https://download.mono-project.com/repo/xamarin.gpg \
    && curl https://download.mono-project.com/repo/centos7-stable.repo | tee /etc/yum.repos.d/mono-centos7-stable.repo \
    && amazon-linux-extras enable corretto8 \
    && yum groupinstall -y "Development tools" \
    && yum install -y \
           GeoIP-devel ImageMagick asciidoc bzip2-devel bzr bzrtools cvs cvsps \
           docbook-dtds docbook-style-xsl dpkg-dev e2fsprogs expat-devel expect fakeroot \
           glib2-devel groff gzip icu iptables jq krb5-server libargon2-devel \
           libcurl-devel libdb-devel libedit-devel libevent-devel libffi-devel \
           libicu-devel libjpeg-devel libpng-devel libserf libsqlite3x-devel \
           libtidy-devel libunwind libwebp-devel libxml2-devel libxslt libxslt-devel \
           libyaml-devel libzip-devel mariadb-devel mercurial mlocate mono-devel \
           ncurses-devel oniguruma-devel openssl openssl-devel perl-DBD-SQLite \
           perl-DBI perl-HTTP-Date perl-IO-Pty-Easy perl-TimeDate perl-YAML-LibYAML \
           postgresql-devel procps-ng python-configobj readline-devel rsync sgml-common \
           subversion-perl tar tcl tk vim wget which xfsprogs xmlto xorg-x11-server-Xvfb xz-devel 

RUN useradd codebuild-user

#=======================End of layer: core  =================

FROM core AS tools

# Install Git
RUN set -ex \
   && GIT_VERSION=2.24.1 \
   && GIT_TAR_FILE=git-$GIT_VERSION.tar.gz \
   && GIT_SRC=https://github.com/git/git/archive/v${GIT_VERSION}.tar.gz  \
   && curl -L -o $GIT_TAR_FILE $GIT_SRC \
   && tar zxvf $GIT_TAR_FILE \
   && cd git-$GIT_VERSION \
   && make -j4 prefix=/usr \
   && make install prefix=/usr \
   && cd .. ; rm -rf git-$GIT_VERSION \
   && rm -rf $GIT_TAR_FILE /tmp/*

# Install GitVersion
ENV GITVERSION_VERSION="5.1.2"
ENV LIBGIT2_PKG="https://rpmfind.net/linux/centos/7/extras/x86_64/Packages/libgit2-0.26.6-1.el7.x86_64.rpm"
RUN set -ex \
    && yum install -y $LIBGIT2_PKG \
    && wget -nv https://github.com/GitTools/GitVersion/archive/${GITVERSION_VERSION}.zip -O /tmp/GitVersion_${GITVERSION_VERSION}.zip \
    && mkdir -p /usr/local/GitVersion_${GITVERSION_VERSION} \
    && unzip /tmp/GitVersion_${GITVERSION_VERSION}.zip -d /usr/local/GitVersion_${GITVERSION_VERSION} \
    && rm /tmp/GitVersion_${GITVERSION_VERSION}.zip \
    && ln -s /usr/lib64/libgit2.so.0.26.6 /usr/lib64/libgit2-15e1193.so \
    && echo "dotnet /usr/local/GitVersion_${GITVERSION_VERSION}/GitVersion.dll \$@" >> /usr/local/bin/gitversion \
    && chmod +x /usr/local/bin/gitversion \
    && rm -rf  /tmp/*

# Install stunnel
RUN set -ex \
   && STUNNEL_VERSION=5.56 \
   && STUNNEL_TAR=stunnel-$STUNNEL_VERSION.tar.gz \
   && STUNNEL_SHA256="7384bfb356b9a89ddfee70b5ca494d187605bb516b4fff597e167f97e2236b22" \
   && curl -o $STUNNEL_TAR https://www.usenix.org.uk/mirrors/stunnel/archive/5.x/$STUNNEL_TAR \
   && echo "$STUNNEL_SHA256 $STUNNEL_TAR" | sha256sum -c - \
   && tar xvfz $STUNNEL_TAR \
   && cd stunnel-$STUNNEL_VERSION \
   && ./configure \
   && make -j4 \
   && make install \
   && openssl genrsa -out key.pem 2048 \
   && openssl req -new -x509 -key key.pem -out cert.pem -days 1095 -subj "/C=US/ST=Washington/L=Seattle/O=Amazon/OU=Codebuild/CN=codebuild.amazon.com" \
   && cat key.pem cert.pem >> /usr/local/etc/stunnel/stunnel.pem \
   && cd .. ; rm -rf stunnel-${STUNNEL_VERSION}*

# AWS Tools
# https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ECS_CLI_installation.html
RUN curl -sS -o /usr/local/bin/aws-iam-authenticator https://amazon-eks.s3-us-west-2.amazonaws.com/1.14.6/2019-08-22/bin/linux/amd64/aws-iam-authenticator \
    && curl -sS -o /usr/local/bin/kubectl https://amazon-eks.s3-us-west-2.amazonaws.com/1.14.6/2019-08-22/bin/linux/amd64/kubectl \
    && curl -sS -o /usr/local/bin/ecs-cli https://amazon-ecs-cli.s3.amazonaws.com/ecs-cli-linux-amd64-latest \
    && chmod +x /usr/local/bin/kubectl /usr/local/bin/aws-iam-authenticator /usr/local/bin/ecs-cli

# Configure SSM
RUN set -ex \
    && yum install -y https://ec2-downloads-windows.s3.amazonaws.com/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm




##go
RUN git clone https://github.com/syndbg/goenv.git $HOME/.goenv
ENV PATH="/root/.goenv/shims:/root/.goenv/bin:/go/bin:$PATH"
ENV GOENV_DISABLE_GOPATH=1
ENV GOPATH="/go"

#=======================End of layer: tools  =================

FROM tools AS runtimes_1

#****************     GOLANG     ****************************************************
ENV GOLANG_13_VERSION="1.13.8" \
    GOLANG_12_VERSION="1.12.17"

ENV GOENV_DISABLE_GOPATH=1
ENV GOPATH="/go"

RUN goenv install $GOLANG_12_VERSION; rm -rf /tmp/*

RUN goenv install $GOLANG_13_VERSION; rm -rf /tmp/*; \
    goenv global  $GOLANG_13_VERSION

RUN go get -u github.com/golang/dep/cmd/dep
RUN go get -u github.com/go-sql-driver/mysql
RUN go get -u github.com/go-redis/redis
RUN go get -u github.com/alicebob/miniredis/...
RUN go get -u github.com/google/uuid
RUN go get -u github.com/aws/aws-sdk-go/...

#****************      END GOLANG     ****************************************************

#=======================End of layer: runtimes_1  =================
FROM runtimes_1 AS runtimes_2

#=======================End of layer: runtimes_2  =================
FROM runtimes_2 AS runtimes_3


#Golang 14
ENV GOLANG_14_VERSION="1.14.0"
RUN goenv install $GOLANG_14_VERSION; rm -rf /tmp/*; \
    goenv global  $GOLANG_14_VERSION


#===================END of runtimes_3 ==============
FROM runtimes_3 AS al2_v3


# Configure SSH
COPY ssh_config /root/.ssh/config
COPY runtimes.yml /codebuild/image/config/runtimes.yml
COPY dockerd-entrypoint.sh /usr/local/bin/
COPY amazon-ssm-agent.json          /etc/amazon/ssm/

ENTRYPOINT ["dockerd-entrypoint.sh"]

#=======================End of layer: al2_v3  =================

