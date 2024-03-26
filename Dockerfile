FROM golang:alpine as kdt-build
# Download kdt binary.
RUN go install github.com/kondukto-io/kdt@latest

FROM alpine as snyk-build
# Download snyk binary
RUN  apk --no-cache add curl
RUN curl --compressed https://static.snyk.io/cli/latest/snyk-alpine -o snyk \
    && chmod +x ./snyk \
    && mv ./snyk /usr/local/bin/
RUN curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin latest


FROM python:alpine
# Create a group and user
RUN apk --no-cache add ca-certificates && addgroup -S appgroup && adduser -S appuser -G appgroup

# Tell docker that all future commands should run as the appuser user
USER appuser

# Copy kdt from kdt-build stage.
COPY --from=kdt-build /go/bin/kdt /usr/local/bin/kdt
# Copy snyk from snyk-build stage.
COPY --from=snyk-build /usr/local/bin/snyk /usr/local/bin/snyk
COPY --from=snyk-build /usr/local/bin/trivy /usr/local/bin/trivy


RUN python3 -m venv /tmp/.venv \
    && . /tmp/.venv/bin/activate \
    && pip install semgrep

# Command to run the executable
CMD ["/bin/sh"]