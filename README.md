# Содержание
1. [HOMEWORK №13: Docker installation & basic commands](#homework_13)
2. [HOMEWORK №14: Docker machine & docker-hub](#homework_14)

___
# HOMEWORK №13: Docker installation & basic commands <a name="homework_13"></a>

## Что сделано:
 - Установлен Docker версии 18.03.1-ce в соответствии с интрукцией  https://docs.docker.com/install/linux/docker-ce/ubuntu/#uninstall-old-versions
- познакомился с командами run, ps, images, start, attach, stop, kill, create, exec, commit, inspect, system df, rm, rmi
- создан образ на основе запущенного контейнера из образа ubuntu с дополнительно созданным файлом `/tmp/file` и `/bin/bash` в качестве init-процесса
- проведено сравнение описаний образа и контейнера

## Как проверить:
 - созданный образ присутсвует в выводе `docker images` - сохранен в файл `docker-1.log`
 - в этом же файле сравнение описаний образа и контейнера


___
# HOMEWORK №14: Docker machine & docker-hub <a name="homework_14"></a>

## Что сделано:
- Установлена docker-machine в соответсвии с интрукцией https://docs.docker.com/machine/install-machine/ для linux
- создан новый проект GCP с именем docker
- конфгурация GCloud SDK скорректирована для работы с созданным проектом: `gcloud config set core/project docker-<id>`
- для работы docker-machine с созданным проектом установлена переменная окружения GOOGLE_PROJECT=docker-<id>
- создан докер хост коммандой:
```
docker-machine create --driver google \
--google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts \
--google-machine-type n1-standard-1 \
--google-zone europe-west1-b \
docker-host
```
- переключение на работу с созданным докер-хостом выполнено командой `eval $(docker-machine env docker-host)`
- повторены эксперименты из демо(из лекции) по работе с PID, network и user namespace
- проведено сравнение вывода комманд
```
docker run --rm -ti tehbilly/htop
```
и
```
docker run --rm --pid host --userns=host -it tehbilly/htop
```
  в первом случае выводится информация только о процессах запщуенных в контейнере(по факту - один процесс htop) и с ID процессов в контейнере, во втором случае выводится информация о всех процессах хоста id процессов на хостовой машине
- для создания образа с аппликацией reddit подготовлены файлы: `Dockerfile`, `mongod.conf`, `db_config`, `start.sh`
- образ собран на докер-хосте командой `docker build -t reddit:latest .`
- создан аккаунт на docker-hub
- созданный образ загружен в репозитрий docker-hub:
```
docker tag reddit:latest ivtcrootus/otus-reddit:1.0
docker push ivtcrootus/otus-reddit:1.0
```


## Как запустить:
### Для проверки запуска приложения на докер-хосте:
- в той же консоли, где запускалась сборка приложения, выполнть команду `docker run --name reddit -d --network=host reddit:latest`
- создать правило FW коммандой
```
gcloud compute firewall-rules create reddit-app \
--allow tcp:9292 \
--target-tags=docker-machine \
--description="Allow PUMA connections" \
--direction=INGRESS
```
- посмотреть IP адрес докер-хоста выполнив комманду `echo $DOCKER_HOST`
- открыть в браузере адрес http://IP_адрес_докер_хоста:9292

### Для проверки запуска приложения на докер-хосте:
- открыть новую консоль или в этой же консоли выполнть комманду `eval "$(docker-machine env -u)"`
- запустить контейнер командой `docker run --name reddit -d -p 9292:9292 ivtcrootus/otus-reddit:1.0`


## Как проверить:
- открыть в браузере адрес http://IP_адрес_докер_хоста:9292 и  http://127.0.0.1:9292 и убедиться что страница приложения открывается
