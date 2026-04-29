
### proyecto_final_service image

login

```
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 526832762947.dkr.ecr.us-east-1.amazonaws.com
```


open nginx folder

```
cd nginx
```

build

```
docker build -t proyecto_final_service-nginx-ambassador -f Dockerfile .
```

tag

```
docker tag proyecto_final_service-nginx-ambassador:latest 526832762947.dkr.ecr.us-east-1.amazonaws.com/proyecto_final_service:nginx-ambassador-latest

docker tag projecto-final-ambassador-nginx:latest 526832762947.dkr.ecr.us-east-1.amazonaws.com/proyecto_final_service:nginx-ambassador-grupo2-latest
```

push

```
docker push 526832762947.dkr.ecr.us-east-1.amazonaws.com/proyecto_final_service:nginx-ambassador-grupo2-latest
```