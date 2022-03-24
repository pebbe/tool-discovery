#Harvester + Store run in the same container as the store is merely a thin layer on top of the former
FROM proycon/codemeta-harvester

LABEL org.opencontainers.image.authors="Maarten van Gompel <proycon@anaproy.nl>"
LABEL description="CLARIAH Tool Store & Harvester"

ARG BASEURL="https://tools.clariah.nl/"
ENV BASEURL=$BASEURL

ARG CRON_HARVEST_INTERVAL="3 * * * *"
ENV CRON_HARVEST_INTERVAL=$CRON_HARVEST_INTERVAL

#You will want to pass this at run time:
#ENV GITHUB_TOKEN

ENV GIT_TERMINAL_PROMPT=0

ENV SOURCE_REGISTRY_REPO="https://github.com/CLARIAH/tool-discovery.git"
#Path within the above repository where the registry is located
ENV SOURCE_REGISTRY_ROOT="source-registry"

#Install webserver and build dependencies
RUN apk add nginx ca-certificates runit cronie rsync py3-dotenv gcc libc-dev make python3-dev

#Install rdflib-endpoint, also pulls in uvicorn (for which we need the build dependencies)
RUN pip install rdflib-endpoint
COPY toolstoreapi /usr/src/
RUN cd /usr/src/ && ls && pip install .

#remove build dependencies
RUN apk del gcc libc-dev make python3-dev
RUN rm -Rf /root/.cache /usr/src

ADD etc /etc
ADD bin /usr/bin/

#File that will hold the full knowledge graph, used by the Tool Store API providing a SPARQL endpoint
ENV TOOLSTORE_DATA="/tool-store-data/all.json"

RUN echo "$CRON_HARVEST_INTERVAL /usr/bin/harvest.sh $BASEURL $SOURCE_REGISTRY_REPO $SOURCE_REGISTRY_ROOT > /dev/stdout 2> /dev/stderr" > /tmp/crontab && crontab /tmp/crontab

VOLUME ["/tool-store-data"]
EXPOSE 80
WORKDIR /

ENTRYPOINT ["runsvdir","-P","/etc/service"]
