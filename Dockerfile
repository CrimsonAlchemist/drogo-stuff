FROM debian:jessie
# remove several traces of debian python
RUN apt-get purge -y python.*
RUN set -ex && \
    echo 'deb http://deb.debian.org/debian jessie-backports main' \
      > /etc/apt/sources.list.d/jessie-backports.list \ 
    && apt update -y \
    && apt-get install -y curl \
    && apt install -t \
       jessie-backports \
       openjdk-8-jre-headless \
       ca-certificates-java -y
      
ENV JYTHON_VERSION="2.7.1" \
    JYTHON_SHASUM="392119a4c89fa1b234225d83775e38dbd149989f"
RUN curl -fSL -o jython_installer.jar "http://search.maven.org/remotecontent?filepath=org/python/jython-installer/${JYTHON_VERSION}/jython-installer-${JYTHON_VERSION}.jar" \
 && echo "$JYTHON_SHASUM *jython_installer.jar" | sha1sum -c - \
 && java -jar jython_installer.jar -s -d /usr/local/jython \
 && rm jython_installer.jar \
 && ln -s /usr/local/jython/bin/jython /usr/local/jython/bin/python \
 && ln -s /usr/local/jython/bin/jython /usr/local/jython/bin/python2
ENV PATH="/usr/local/jython/bin:$PATH"
RUN apt-get install -y apache2 \
    libapache2-mod-wsgi \
    build-essential \
    vim \
 && apt-get clean \
 && apt-get autoremove \
 && rm -rf /var/lib/apt/lists/*
# Copy over and install the requirements
COPY ./app/requirements.txt /var/www/drogo-flask/app/requirements.txt
RUN pip install -r /var/www/drogo-flask/app/requirements.txt
# Copy over the apache configuration file and enable the site
COPY ./drogo-flask.conf /etc/apache2/sites-available/drogo-flask.conf
RUN a2ensite drogo-flask
RUN a2enmod headers
# Copy over the wsgi file
COPY ./drogo-flask.wsgi /var/www/drogo-flask/drogo-flask.wsgi
COPY ./run.py /var/www/drogo-flask/run.py
COPY ./app /var/www/drogo-flask/app/
RUN a2dissite 000-default.conf
RUN a2ensite  drogo-flask.conf
EXPOSE 80
WORKDIR /var/www/drogo-flask
# CMD ["/bin/bash"]
CMD  /usr/sbin/apache2ctl -D FOREGROUND

