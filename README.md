# Содержание
1. [HOMEWORK №13: Docker installation & basic commands](#homework_13)
2. [HOMEWORK №14: Docker machine & docker-hub](#homework_14)
3. [HOMEWORK №15: Dockerfile, image optimisation](#homework_15")

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
  в первом случае выводится информация только о процессах запщуенных в контейнере(по факту - один процесс htop) и с ID процессов в контейнере, во втором случае выводится информация о всех процессах хоста c id процессов на хостовой машине
- для создания образа с аппликацией reddit подготовлены файлы: `Dockerfile`, `mongod.conf`, `db_config`, `start.sh`
- образ собран на докер-хосте командой `docker build -t reddit:latest .`
- создан аккаунт на docker-hub
- созданный образ приложения загружен в репозитрий docker-hub:
```
docker tag reddit:latest ivtcrootus/otus-reddit:1.0
docker push ivtcrootus/otus-reddit:1.0
```

- создан шаблон terraform для запуска VM с ubuntu, количество VM задается параметром `vm_qty`, шаблон лежит в `docker-monolith/infra/terraform`
- созданы playbook'и для установки docker и приложения reddit из созданного ранее образа контейнера `ivtcrootus/otus-reddit:1.0` на VM созданные по шаблону terraform'ом - в папке `docker-monolith/infra/ansible/playbooks`
- создано приавло FW для работы packer:
```
gcloud compute firewall-rules create packer-ssh \
--allow tcp:22 \
--target-tags=packer \
--description="Allow ssh connections for packer" \
--direction=INGRESS
```
- создан шаблон packer для создания образа ubuntu с docker - в папке `docker-monolith/infra/packer`

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

### Для проверки запуска приложения на локальной машине:
- открыть новую консоль или в этой же консоли выполнть комманду `eval "$(docker-machine env -u)"`
- запустить контейнер командой `docker run --name reddit -d -p 9292:9292 ivtcrootus/otus-reddit:1.0`

### Для проверки работы шаблонов packer, terraform и playbook'ов :
- сначала в docker-monolith/infra/terraform/state-location, потом в docker-monolith/infra/terraform/ создать файлы `terraform.tfvars` задав значение параметров, и выполнить последовательность комманд:
```
terraform init
terraform apply
```
- в папке `docker-monolith/infra/ansible` выполнить команду `ansible-playbook ./playbooks/site.yml`
- в папке `docker-monolith/infra` выполнить команду `packer build  --var-file=packer/variables.json packer/docker-image.json` создав предварительно файл с значениями переменных `packer/docker-image.json`

## Как проверить:
- открыть в браузере адрес http://IP_адрес_докер_хоста:9292 и  http://127.0.0.1:9292 и убедиться что страница приложения открывается
- выполнить в коммандной строке `gcloud compute instances list` и убедиться, что terraform создал заданное количество VM
- убедится, что на созданных VM работает приложение открыв в браузере http://IP_адрес_ВМ:9292 (IP адреса взять из вывода `gcloud compute instances list`)
- убедится что для в списке образов проекта присутсвует образ ubuntu с docker выполнив команду `gcloud compute images list | grep '^NAME\|docker'`

___
# HOMEWORK №15: Dockerfile, image optimisation <a name="homework_15"></a>

Для работы с docker host в коммандной строке выполнена командама `eval "$(docker-machine env -u)"`, все дальнейшие команды `docker ...` выполняются в этом терминале.

## Что сделано:
 - установлен hadolint и пакет для его интеграции с Atom
 - https://github.com/express42/reddit/archive/microservices.zip распакован в src/
 - для трех компонентов приложения(ui, post, comment) скорретирован Dockerfile в соответсвии с best practice и рекоммендациями hadolint
 - скачана последняя версия образао MongoDB
 ```
docker pull mongo:latest
 ```
 - собраны image'ы контейнеров:
```
docker build -t ivtcro/post:1.0 ./post-py
docker build -t ivtcro/comment:1.0 ./comment
docker build -t ivtcro/ui:1.0 ./ui
```
 - создана сеть для приложения:
 ```
 docker network create reddit
 ```

 - запущены контейнеры:
 ```
docker run -d --network=reddit --network-alias=post_db --network-alias=comment_db mongo:latest
docker run -d --network=reddit --network-alias=post ivtcro/post:1.0
docker run -d --network=reddit --network-alias=comment ivtcro/comment:1.0
docker run -d --network=reddit -p 9292:9292 ivtcro/ui:1.0
```
 - изменены значения переменных окружения с сетевыми алиасами в Dockerfile'ах(тут лучше было бы поднять версию image, но этого сделано не было)
 - запущенные контейнеры удалены командой:
 ```
docker kill $(docker ps -q)
 ```
 - контейнеры запущены из новых образов:
 ```
docker run -d --network=reddit --network-alias=post_db_alias --network-alias=comment_db_alias mongo:latest
docker run -d --network=reddit --network-alias=post_alias --env POST_DATABASE_HOST=post_db_alias ivtcro/post:1.0 env
docker run -d --network=reddit --network-alias=comment_alias --env COMMENT_DATABASE_HOST=comment_db_alias ivtcro/comment:1.0
docker run -d --network=reddit -p 9292:9292 --env POST_SERVICE_HOST=post_alias --env COMMENT_SERVICE_HOST=comment_alias ivtcro/ui:1.0
```
 - Размер получившихся образов:
 ```
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
ivtcro/ui           1.0                 43652804e650        19 hours ago        765MB
ivtcro/comment      1.0                 422c6d89758d        20 hours ago        758MB
ivtcro/post         1.0                 956a0ea41f42        20 hours ago        102MB
 ```
 - Изменен Dockerfile для ui - за базу взят образ Ubuntu 16.04, собрана новая версия образа:
  ```
docker build -t ivtcro/ui:2.0 ./ui
 ```
 - Размер получившихся образов:
 ```
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
ivtcro/ui           1.0                 d461d78de286        About an hour ago   765MB
ivtcro/ui           2.0                 cfda161864e7        2 hours ago         394MB
ivtcro/comment      1.0                 422c6d89758d        21 hours ago        758MB
ivtcro/post         1.0                 956a0ea41f42        21 hours ago        102MB
```
 - Изменен Dockerfile для ui и comment - за базу взят образ Alpine 3.7, собраны новые версии образов:
```
docker build -t ivtcro/ui:3.0 ./ui
docker run -d --network=reddit --network-alias=comment ivtcro/comment:2.0
```
 - Размер получившихся образов:
  ```
REPOSITORY          TAG                 IMAGE ID            CREATED              SIZE
ivtcro/comment      2.0                 88cb096f5501        55 seconds ago       54.8MB
ivtcro/ui           3.0                 9f3c1ccbe2ad        11 minutes ago       58.7MB
ivtcro/ui           1.0                 d461d78de286        4 hours ago          765MB
ivtcro/ui           2.0                 cfda161864e7        4 hours ago          394MB
ivtcro/comment      1.0                 422c6d89758d        23 hours ago         758MB
ivtcro/post         1.0                 956a0ea41f42        23 hours ago         102MB
 ```
 - запущенные контейнеры удалены командой:
```
docker kill $(docker ps -q)
```
 - контейнеры перезапущены:
```
docker run -d --network=reddit --network-alias=post_db_alias --network-alias=comment_db_alias mongo:latest
docker run -d --network=reddit --network-alias=post_alias --env POST_DATABASE_HOST=post_db_alias ivtcro/post:1.0 env
docker run -d --network=reddit --network-alias=comment_alias --env COMMENT_DATABASE_HOST=comment_db_alias ivtcro/comment:2.0
docker run -d --network=reddit -p 9292:9292 --env POST_SERVICE_HOST=post_alias --env COMMENT_SERVICE_HOST=comment_alias ivtcro/ui:3.0
```
 - создан volume для MongoDB:
```
docker volume create reddit_db
```
 - контейнеры перезапущены:
```
docker run -d --network=reddit --network-alias=post_db_alias --network-alias=comment_db_alias -v reddit_db:/data/db mongo:latest
docker run -d --network=reddit --network-alias=post_alias --env POST_DATABASE_HOST=post_db_alias ivtcro/post:1.0 env
docker run -d --network=reddit --network-alias=comment_alias --env COMMENT_DATABASE_HOST=comment_db_alias ivtcro/comment:2.0
docker run -d --network=reddit -p 9292:9292 --env POST_SERVICE_HOST=post_alias --env COMMENT_SERVICE_HOST=comment_alias ivtcro/ui:3.0
```

## Как запустить:
  - Удалить ранее созданные контейнеры:
```
docker kill $(docker ps -q)
```
  - Выполнить следующую последовательность комманд:
```
docker run -d --network=reddit --network-alias=post_db_alias --network-alias=comment_db_alias -v reddit_db:/data/db mongo:latest
docker run -d --network=reddit --network-alias=post_alias --env POST_DATABASE_HOST=post_db_alias ivtcro/post:1.0 env
docker run -d --network=reddit --network-alias=comment_alias --env COMMENT_DATABASE_HOST=comment_db_alias ivtcro/comment:2.0
docker run -d --network=reddit -p 9292:9292 --env POST_SERVICE_HOST=post_alias --env COMMENT_SERVICE_HOST=comment_alias ivtcro/ui:3.0
```

## Как проверить:
 - открыть в браузере http://IP_адрес_докер_хоста:9292
 - оставить запись и комментарий к контарий к контейнер
 - пересоздать контейнеры
 - открыть в браузере http://IP_адрес_докер_хоста:9292 и убедиться, что ранее созданные записи не удалены
