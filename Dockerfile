FROM golang:alpine as kdt-build
# Download kdt binary.
RUN go install github.com/kondukto-io/kdt@latest

FROM alpine as tools-build
# Download snyk binary
RUN  apk --no-cache add curl
RUN curl --compressed https://static.snyk.io/cli/latest/snyk-alpine -o snyk \
    && chmod +x ./snyk \
    && mv ./snyk /usr/local/bin/
# Download trivy binary
RUN curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin latest
# Download trufflehog binary
RUN curl -sSfL https://raw.githubusercontent.com/trufflesecurity/trufflehog/main/scripts/install.sh | sh -s -- -b /usr/local/bin


FROM python:alpine
# Create a group and user
RUN apk --no-cache add ca-certificates docker && addgroup -S appgroup && adduser -S appuser -G appgroup

# Tell docker that all future commands should run as the appuser user
USER appuser

# Start Docker

# Copy kdt from kdt-build stage.
COPY --from=kdt-build /go/bin/kdt /usr/local/bin/kdt
# Copy snyk and trivy from tools-build stage.
COPY --from=tools-build /usr/local/bin/snyk /usr/local/bin/snyk
COPY --from=tools-build /usr/local/bin/trivy /usr/local/bin/trivy
COPY --from=tools-build /usr/local/bin/trufflehog /usr/local/bin/trufflehog

# Semgrep is annoying, so we need this whole python env.
RUN python3 -m venv /tmp/venv \
    && . /tmp/venv/bin/activate \
    && pip install semgrep

ENV PATH="$PATH:/tmp/venv/bin/"

# Command to run the executable
CMD ["/bin/sh"]