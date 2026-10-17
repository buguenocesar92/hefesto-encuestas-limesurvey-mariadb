FROM martialblog/limesurvey:7.5.1-261007-apache@sha256:7a35ba0aafd8f24732a3b301cc123a7948da9650f0e7d40dbd3237b4b90ed2b6
COPY --chmod=755 ops/start.sh /usr/local/bin/hefesto-start
COPY ops/configure.php /opt/hefesto-configure.php
COPY ops/php.ini /usr/local/etc/php/conf.d/99-hefesto.ini
ENTRYPOINT ["/usr/local/bin/hefesto-start"]
CMD ["apache2-foreground"]
