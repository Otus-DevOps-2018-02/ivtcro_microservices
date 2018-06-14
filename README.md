# Содержание
1. [HOMEWORK №13: Docker installation & basic commands](#homework_13)
2. [HOMEWORK №14: Docker machine & docker-hub](#homework_14)
3. [HOMEWORK №15: Dockerfile, image optimisation](#homework_15)
4. [HOMEWORK №16: Docker: сети, docker-compose](#homework_16)
5. [HOMEWORK №17: GitLabCI](#homework_17)
6. [HOMEWORK №18: GitLabCI-2](#homework_18)
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
 - оставить запись и комментарий к записи
 - пересоздать контейнеры
 - открыть в браузере http://IP_адрес_докер_хоста:9292 и убедиться, что ранее созданные записи не удалены

___
# HOMEWORK №16: Docker: сети, docker-compose <a name="homework_16"></a>

## Docker networking
### Что сделано:

- чтобы network namespace docker'а отображались командой netns выполнена команда `sudo ln -s /var/run/docker/netns /var/run/netns`
- cоздан контейнер с типом сети none:  
```
docker run  --network none --rm -d --name net_test joffotron/docker-net-tools -c "sleep 100"
```
команда docker `exec -ti net_test ifconfig` показывает, что внутри контейнера доступен только loopback-интерфейс
также видно, что для контейнера создается отдельный сетевой namespace:
```
ivtcrov@docker-host:~$ sudo ip netns
6e93156a123e
default
ivtcrov@docker-host:~$ sudo ip netns exec 6e93156a123e ifconfig
lo        Link encap:Local Loopback  
          inet addr:127.0.0.1  Mask:255.0.0.0
          UP LOOPBACK RUNNING  MTU:65536  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000
          RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)
```
- создан контейнер с типом сети host.
```
docker run  --network host --rm -d --name net_test joffotron/docker-net-tools -c "sleep 100"
```
в это случае контейнер использует сетевой namespace хоста и для него доступен тот же набор сетевых интерфейсов и тот же сетевой стек, что и для хоста.
поэтому при попытке запустить на одном хосте несоколько контейнеров nginx стартует только один - все они пытаются слушать один и тот же порт.

- удалена сесть созданная в рамках предыдущего ДЗ: `docker network rm reddit`
- создана новая сеть:
```
docker network create reddit --driver bridge
```
- запущены контейнеры с использованием созданной сети:
```
docker run -d --network=reddit mongo:latest
docker run -d --network=reddit ivtcro/post:1.0  
docker run -d --network=reddit ivtcro/comment:1.0
docker run -d --network=reddit -p 9292:9292 ivtcro/ui:1.0
```
- при открытии приложения возникает ошибка _"Can't show blog posts, some problems with the post service. Refresh?"_. Решение проблемы - присвоение контейнерам сетевых алиасов. Для этого сначала останоми созданные контейнеры:
```
docker kill $(docker ps -q)
```
и запустим их указав алиасы
```
docker run -d --network-alias=post_db --network-alias=comment_db --network=reddit mongo:latest
docker run -d --name=post --network=reddit ivtcro/post:1.0  
docker run -d --name=comment --network=reddit ivtcro/comment:1.0
docker run -d --network=reddit -p 9292:9292 ivtcro/ui:1.0
```
- компоненты запущены с интерфейсами в двух сетях таким образом, чтобы компонент ui не имел доступа к mongo. Для этого созданы две сети:
```
docker network create back_net --subnet=10.0.2.0/24
docker network create front_net --subnet=10.0.1.0/24
```
удалены ранее созданные контейнеры
```
docker kill $(docker ps -q)
```
запущены контейнеры с новыми сетями
```
docker run -d --network-alias=post_db --network-alias=comment_db --network=back_net mongo:latest
docker run -d --name=post --network=back_net ivtcro/post:1.0  
docker run -d --name=comment --network=back_net ivtcro/comment:1.0
docker run -d --network=front_net -p 9292:9292 ivtcro/ui:1.0
```
при старте можно подключить контейнер только к одной сети, для подключения запущенных контейнеров к сетям выполнить комманду:
```
docker network connect front_net post
docker network connect front_net comment
```
после чего страница проекта окрывается без ошибок
- изучены настройки сети - bridge, netfilters (таблица NAT) - для созданной сетевой конфигурации микросервисов
```
ivtcrov@docker-host:~$ sudo docker network ls | grep "NETWORK\|_net"
NETWORK ID          NAME                DRIVER              SCOPE
46102dc8e9ba        back_net            bridge              local
7dfc5f746ef0        front_net           bridge              local
```
```
ivtcrov@docker-host:~$ for bridge in $(sudo docker network ls | grep "_net" | awk -p '{print $1}'); do brctl show br-$bridge; done
bridge name     bridge id               STP enabled     interfaces
br-46102dc8e9ba         8000.024203be5392       no              veth229abc0
                                                        veth42a980f
                                                        vethbf85212
bridge name     bridge id               STP enabled     interfaces
br-7dfc5f746ef0         8000.02423067cee5       no              veth5f374a9
```
```
ivtcrov@docker-host:~$ sudo iptables -nL -t nat
Chain PREROUTING (policy ACCEPT)
target     prot opt source               destination         
DOCKER     all  --  0.0.0.0/0            0.0.0.0/0            ADDRTYPE match dst-type LOCAL
Chain INPUT (policy ACCEPT)
target     prot opt source               destination         
Chain OUTPUT (policy ACCEPT)
target     prot opt source               destination         
DOCKER     all  --  0.0.0.0/0           !127.0.0.0/8          ADDRTYPE match dst-type LOCAL
Chain POSTROUTING (policy ACCEPT)
target     prot opt source               destination         
MASQUERADE  all  --  10.0.1.0/24          0.0.0.0/0           
MASQUERADE  all  --  10.0.2.0/24          0.0.0.0/0           
MASQUERADE  all  --  172.18.0.0/16        0.0.0.0/0           
MASQUERADE  all  --  172.17.0.0/16        0.0.0.0/0           
MASQUERADE  tcp  --  10.0.1.2             10.0.1.2             tcp dpt:9292
Chain DOCKER (2 references)
target     prot opt source               destination         
RETURN     all  --  0.0.0.0/0            0.0.0.0/0           
RETURN     all  --  0.0.0.0/0            0.0.0.0/0           
RETURN     all  --  0.0.0.0/0            0.0.0.0/0           
RETURN     all  --  0.0.0.0/0            0.0.0.0/0           
DNAT       tcp  --  0.0.0.0/0            0.0.0.0/0            tcp dpt:9292 to:10.0.1.2:9292
```
```
ivtcrov@docker-host:~$  ps ax | grep docker-proxy
10106 ?        Sl     0:00 /usr/bin/docker-proxy -proto tcp -host-ip 0.0.0.0 -host-port 9292 -container-ip 10.0.1.2 -container-port 9292
11038 pts/0    S+     0:00 grep --color=auto docker-proxy
```

### Как запустить:
- запустить контейнеры командой `docker run` по одному из вариантов опсанному выше(в зависимости от сетевой конфигурации)

### Как проверить:
- открыть в браузере http://IP_адрес_докер_хоста:9292
- оставить запись и комментарий к записи

## Docker compose
### Что сделано:
- создан файл ./src/docker-compose.yml с переченем всех микросервисов
- удалены ранее созданные контейнеры
```
docker kill $(docker ps -q)
export USERNAME=ivtcro
```
- запущены контейнеры командой `docker-compose up -d`:
```
ivtcro@ubuntuHome:~/Otus-DevOps/ivtcro_microservices/src$ docker-compose ps
    Name                  Command             State           Ports         
----------------------------------------------------------------------------
src_comment_1   puma                          Up                            
src_post_1      python3 post_app.py           Up                            
src_post_db_1   docker-entrypoint.sh mongod   Up      27017/tcp             
src_ui_1        puma                          Up      0.0.0.0:9292->9292/tcp
```
- в переменные окружения вынесены следующие параметры для docker-compose:
    - имя пользователя в docker-hub
    - порт публикации сервиса ui
    - версии сервисов
    - путь для volume контейнера с mongodb
- созданы файлы .env и .env.example со значениями/примерами значений переменных
- порт публикации для ui изменен на 9291, добавлено соответсвующе правило в FW, псле чего пересозданы контейнеры:
```
docker kill $(docker ps -q)
docker-compose up -d
```
провеорил, что приложение доступно по адресу <docker_host_external_ip>:9291
- все создаваемые docker-compose сущности имеют одинаковый префикс src. По умолчанию в качестве префикса используется имя рабочей директории. Префикс может быт изменен несколькими способами:
    - с помощью опции командной строки: -p <project_name>
    - c помощью переменной окружени COMPOSE_PROJECT_NAME
- создан файл `docker-compose.override.yml`, в котором:
    - для руби приложений(для сервисов comment и ui) заменена дефолтная команда запуска контейрена на:
    ```
    command: "puma --debug -w 2"
    ```
    для запуска в дебаг режиме с двумя воркерами

    - чтобы можно было не пересобирать образы контейнеров при изменении кода приложений можно монтировать volume с кодом приложения в контейнер. Для этого папки с исходниками приложения скопированы на docker-host
    ```
    docker-machine scp -r ui docker-host:~/app_src/
    docker-machine scp -r post-py docker-host:~/app_src/
    docker-machine scp -r comment docker-host:~/app_src/
    ```
    после выполненных комманд исходники находятся на docker host по пути `/home/docker-user/app_src`
    ```
    docker-user@docker-host:~/app_src$ pwd
    /home/docker-user/app_src
    docker-user@docker-host:~/app_src$ ls -la
    total 20
    drwxrwxr-x 5 docker-user docker-user 4096 May 20 19:01 .
    drwxr-xr-x 5 docker-user docker-user 4096 May 20 19:00 ..
    drwxrwxr-x 2 docker-user docker-user 4096 May 20 19:01 comment
    drwxrwxr-x 2 docker-user docker-user 4096 May 20 19:01 post-py
    drwxrwxr-x 3 docker-user docker-user 4096 May 20 19:01 ui
    ```
    также создана переменная, задающая путь к исходникам придожения на docker host - `APP_PATH`
- контейнеры перезапущены и проверена доступность и работоспособность приложения

```
docker kill $(docker ps -q)
docker-compose up -d
```
при выполнении `docker-compose up -d` из файлов `docker-compose.yml` и `docker-compose.override.yml` создается один файл проекта как при запуске команды `docker-compose -f docker-compose.yml -f docker-compose.override.yml up -d`
- на примере сервиса comment провеорил что применились значения из override-файла:
```
ivtcro@ubuntuHome:~/Otus-DevOps/ivtcro_microservices/src$ docker inspect --format='{{json .Mounts}}' 359
[{"Type":"bind","Source":"/home/docker-user/app_src/comment","Destination":"/app","Mode":"rw","RW":true,"Propagation":"rprivate"}]
ivtcro@ubuntuHome:~/Otus-DevOps/ivtcro_microservices/src$ docker inspect --format='{{json .Path}}{{json .Args}}' 359
"puma"["--debug","-w","2"]
```

### Как запустить:
- выполнить комманду `docker-compose up -d`

### Как проверить:
- открыть в браузере http://IP_адрес_докер_хоста:${UI_EXPOSED_PORT}, где UI_EXPOSED_PORT - переменная задающая порт приложения
- оставить запись и комментарий к записи

___
# HOMEWORK №17: GitLabCI <a name="homework_17"></a>

### Что сделано:
 - Создан сервисный аккаунт GCE для ansible
 - Установлена роль geerlingguy.docker:
 ```
 ansible-galaxy install geerlingguy.docker
 ```
 - созданы playbook'и для заливки VM и подготовки её к запуску GitLabCI
 - создан хост для запуска gitlabCI:
 ```
 ansible-playbook gitlabci-host.yml
 ```
 - подключится к созданному хосту и запуск GitLabCI:
 ```
 sudo docker-compose up -d
 ```
 - для репозитория установенный удаленный репозиторий
 ```
 git remote add gitlab http://<your-vm-ip>/homework/example.git
 ```
 - в дальнейшем при смене IP адреса хоста можно обновить его для удаленного репозитория командой:
```
git remote set-url gitlab git@<new_ip_address>:homework/example.git
```
 - Изменения в репозитоии залиты в удаленный репозиторий GitLabCI
 ```
 git push gitlab gitlab-ci-1
 ```
 - Создано описание pilpline'а, запушено в репозиторий
```
git add .gitlab-ci.yml
git commit -m 'add pipeline definition'
git push gitlab gitlab-ci-1
```
 - создан и  зарегистрирован docker runner
```
sudo docker run -d --name gitlab-runner --restart always \
-v /srv/gitlab-runner/config:/etc/gitlab-runner \
-v /var/run/docker.sock:/var/run/docker.sock \
gitlab/gitlab-runner:latest
```
```
sudo docker exec -it gitlab-runner gitlab-runner register
my-runner
теги - linux,xenial,ubuntu,docker
```
 - в репозиторий добавлено приложение reddit и добавлен файл с тестом `simpletest.rb`:
```
git clone https://github.com/express42/reddit.git && rm -rf ./reddit/.git
git add reddit/
git commit -m "Add reddit app"
git push gitlab gitlab-ci-1
```
 - при смене IP адреса хоста с GitLabCI нужно  выполнить следующую последовательность действий:
1) зайти в контейнер `sudo docker exec -it a31 /bin/bash`
2) Отредактировать файл `/etc/gitlab/gitlab.rb`, `указать параметр external_url "http://<new_ip_address>"`
3) выполнить команду `gitlab-ctl reconfigure`


- для автоскейлинга runner'ов выполнены следующие действия
1) в playbook добавлена установки роли andrewrothstein.docker-machine
2) настроена работа с GCE на VM с GitLab, для пользователя root:
```
gcloud init
gcloud auth application-default login
```
3) Удален docker runner, установлен runner в соответсвии с инструкцией https://docs.gitlab.com/runner/install/linux-manually.html
4) Скорректирован конфиг gitlab runner:
```
 ivtcro@gitlabci-host:~$ sudo cat /etc/gitlab-runner/config.toml
 concurrent = 10
 check_interval = 0

 [[runners]]
   name = "autoscaling"
   url = "http://<url>/"
   token = "0a74bb89b2d8450ac186ee38c237be"
   executor = "docker+machine"
   limit = 10
   [runners.docker]
     tls_verify = false
     image = "alpine:latest"
     privileged = false
     disable_cache = false
     volumes = ["/cache"]
     shm_size = 0
   [runners.cache]
   [runners.machine]
     IdleCount = 0
     IdleTime = 30
     MachineDriver = "google"
     MachineName = "runner-%s"
     MachineOptions = [
         "google-project=docker-ivtcro"
     ]
     OffPeakTimezone = ""
     OffPeakIdleCount = 0
     OffPeakIdleTime = 0
```
- настроена интеграция с Slack

### Как запустить:
 - зайти в web-интерфейс GitLabCI и запустить выполнение pipeline

### Как проверить:
 - проверить, что при работе pipeline не возникло ошибок
 - для выполнения job'ов создаются VM GCE
 - в Slack-канал поступают сообщения о коммитах в репозиторий GitLabCI



 ___
 # HOMEWORK №18: GitLabCI-2 <a name="homework_18"></a>



настройки runner'а изменены для запуска в previleged режиме для возможности запуска docker в docker-runner'е для запуска сборки образа
при попытке переключиться на созданный хост для провижионинга приложения возникала ошибка Error: Unknown shell
пришлось добавить опцию --shell sh
