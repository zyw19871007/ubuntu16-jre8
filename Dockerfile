############################################
# version : huadong/base/ubuntu/16.04/ssh-supervisor
# desc : 当前版本安装的ssh,wget,curl,supervisor,git等
############################################
# 设置继承自ubuntu官方镜像
ARG OS_VERSION=16.04
FROM ubuntu:${OS_VERSION}
#重新声明OS_VERSION使得后续内容能够使用该变量
ARG OS_VERSION

# 下面是一些创建者的基本信息(已经不推荐使用)
MAINTAINER zhangyaowen <zhangyw@huadong.net>

#disappear some error info在apt-get 前声明,避免容器使用时不显示信息
#ENV DEBIAN_FRONTEND noninteractive




#更新apt镜像源
RUN cp /etc/apt/sources.list /etc/apt/sources.list.bak
COPY sources.list /etc/apt/sources.list
# 一次性安装vim，wget，curl，ssh server等必备软件
# 清空ubuntu更新包
RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y --no-install-recommends \
		ca-certificates \
		git \
		wget \
        curl \
        vim \		
		openssh-server \
		supervisor \
		sudo \
		tzdata \
		net-tools \
		&& rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/run/sshd

# 将sshd的UsePAM参数设置成no
RUN sed -ri 's/UsePAM yes/UsePAM no/g' /etc/ssh/sshd_config

# 安装supervisor工具
#RUN mkdir -p /var/log/supervisor

# 添加 supervisord 的配置文件，并复制配置文件到对应目录下面。（supervisord.conf文件和Dockerfile文件在同一路径）
COPY supervisord-ssh.conf /etc/supervisor/conf.d/supervisord-ssh.conf

# 注意这里要更改系统的时区设置，因为在 web 应用中经常会用到时区这个系统变量，默认的 ubuntu 会让你的应用程序发生不可思议的效果哦
RUN echo "Asia/Shanghai" > /etc/timezone && ln -sf /usr/share/zoneinfo/Asia/Shanghai  /etc/localtime


#暂时以root用户运行
#USER huadong
#WORKDIR /home/huadong

RUN echo 'root:huadong' |chpasswd
# 添加测试用户huadong，密码huadong，并且将此用户添加到sudoers里
RUN useradd -ms /bin/bash huadong
RUN echo "huadong:huadong" | chpasswd
RUN echo "huadong   ALL=(ALL)       ALL" >> /etc/sudoers





#JAVA版本信息 压缩文件名
ARG JAVA_VERSION=jre1.8.0_144
ARG JAVA_TAR_NAME=jre-8u144-linux-x64.tar.gz

# 下面是一些创建者的基本信息
MAINTAINER zhangyaowen <zhangyw@huadong.net>

#把本地的jdk加到镜像系统中
RUN mkdir -p /usr/java
ADD ${JAVA_TAR_NAME}  /usr/java/
#配置jdk环境变量
RUN echo "export JAVA_HOME=/usr/java/${JAVA_VERSION}">> /etc/profile && \
 echo "export PATH=$PATH:/usr/java/${JAVA_VERSION}/bin">> /etc/profile && \
 echo "export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar">> /etc/profile && \
 echo "export JAVA_HOME  PATH CLASSPATH" >> /etc/profile

#使环境变量生效
RUN /bin/bash -c  "source /etc/profile"

RUN ln -s  /usr/java/${JAVA_VERSION}/bin/java /usr/bin/java


# 容器需要开放SSH 22端口
EXPOSE 22
EXPOSE 80
EXPOSE 8080
EXPOSE 8090

# 执行supervisord来同时执行多个命令，使用 supervisord 的可执行路径启动服务。
CMD ["/usr/bin/supervisord"]

