FROM openjdk:11

ENV OWASP_DEPENDENCY_CHECK_ZIP_URL https://github.com/jeremylong/DependencyCheck/releases/download/v6.1.0/dependency-check-6.1.0-release.zip

RUN wget --quiet --output-document=dependency-check.zip $OWASP_DEPENDENCY_CHECK_ZIP_URL
RUN unzip -qq dependency-check.zip -d /owasp

ENV PATH "$PATH:/owasp/dependency-check/bin/"

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
