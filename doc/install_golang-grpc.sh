#!/bin/sh
echo "About to install golang grpc"
go get -u google.golang.org/grpc
echo "About to  install golang protobuf protoc-gen-go"
go get -u github.com/golang/protobuf/protoc-gen-go
