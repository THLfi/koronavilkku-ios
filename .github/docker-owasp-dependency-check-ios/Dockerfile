FROM openjdk:11

ENV OWASP_DEPENDENCY_CHECK_ZIP_URL https://dl.bintray.com/jeremy-long/owasp/dependency-check-5.3.2-release.zip

RUN wget --quiet --output-document=dependency-check.zip $OWASP_DEPENDENCY_CHECK_ZIP_URL
RUN unzip -qq dependency-check.zip -d /github/workspace/owasp

ENV PATH "$PATH:/github/workspace/owasp/dependency-check/bin/"

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
