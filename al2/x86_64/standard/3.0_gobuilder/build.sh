docker build -t gobuilder .
docker tag gobuilder:latest 518822224191.dkr.ecr.us-east-1.amazonaws.com/richanderson-io:gobuilder
docker push 518822224191.dkr.ecr.us-east-1.amazonaws.com/richanderson-io:gobuilder