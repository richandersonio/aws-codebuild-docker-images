docker build -t richanderson-io .
docker tag richanderson-io:latest 518822224191.dkr.ecr.us-east-1.amazonaws.com/richanderson-io:latest
docker push 518822224191.dkr.ecr.us-east-1.amazonaws.com/richanderson-io:latest