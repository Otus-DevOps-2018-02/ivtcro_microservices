# Содержание
1. [HOMEWORK №13: Docker installation & basic commands](#homework_13)

___
# HOMEWORK №13: Docker installation & basic commands <a name="homework_13"></a>

## Что сделано:
 - Установлен Docker версии 18.03.1-ceв соответсвии с интрукцией Установлен Docker в соответсвии с интрукцией https://docs.docker.com/install/linux/docker-ce/ubuntu/#uninstall-old-versions
- познакомился с командами run, ps, images, start, attach, stop, kill, create, exec, commit, inspect, system df, rm, rmi
- создан образ на основе запущенного контейнера из образа ubuntu с дополнительно созданным файлом `/tmp/file` и `/bin/bash` в качестве init-процесса
- проведено сравнение описаний образа и контейнера

## Как провеорить:
 - созданный образ присутсвует в выводе `docker images` - сохранен в файл `docker-1.log`
 - в этом же файле сравнение описаний образа и контейнера
