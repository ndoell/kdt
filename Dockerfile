FROM golang:alpine as build

RUN go install github.com/kondukto-io/kdt@latest
#    && cp /go/bin/* /tmp/

FROM alpine:latest
# Create a group and user
RUN apk --no-cache add ca-certificates && addgroup -S appgroup && adduser -S appuser -G appgroup

# Tell docker that all future commands should run as the appuser user
USER appuser

COPY --from=build /go/bin/kdt /usr/bin/kdt

# Command to run the executable
CMD ["/bin/sh"]

# Final stage
#FROM scratch

#COPY --from=build /go/bin/kdt /

#CMD ["/kdt"]