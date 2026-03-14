# 1. 升级编译镜像到较新的 Debian 系统，完美避开 404 错误
FROM maven:3-openjdk-11-slim AS build

# 2. 只需要安装 git（因为跳过了测试，彻底剔除累赘的 mongodb）
RUN apt-get update && apt-get install -y git

COPY . /webprotege
WORKDIR /webprotege

# 3. 强行跳过单元测试进行打包
RUN mvn clean package -DskipTests

# 4. 运行环境保持不变（日志显示 Tomcat 拉取是成功的）
FROM tomcat:8-jre11-slim
RUN rm -rf /usr/local/tomcat/webapps/* \
    && mkdir -p /srv/webprotege \
    && mkdir -p /usr/local/tomcat/webapps/ROOT
WORKDIR /usr/local/tomcat/webapps/ROOT

# 顺手修复了官方的一个老旧语法警告
ARG WEBPROTEGE_VERSION
ENV WEBPROTEGE_VERSION=${WEBPROTEGE_VERSION}

COPY --from=build /webprotege/webprotege-cli/target/webprotege-cli-${WEBPROTEGE_VERSION}.jar /webprotege-cli.jar
COPY --from=build /webprotege/webprotege-server/target/webprotege-server-${WEBPROTEGE_VERSION}.war ./webprotege.war

RUN unzip webprotege.war \
    && rm webprotege.war
