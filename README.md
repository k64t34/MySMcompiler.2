# MySMcompiler.2

Помощник для компиляции SourceMod плагинов.

SourceMod compiler helper.

##VER

-0.4

1.Use hard datetime format in datetime.inc to prevent locale isses  like "Map_Elections" (╨Я╤В, 15.╨░╨┐╤А.2016 16:00:14) by KOM64T.

Установлен жесткий формат даты и времени для избежания проблем с форматом локализации.

2.Add parameter MapReload. If MapReload=true, then server will _restart after plugin copy to server. 

В ini добавлен параметр MapReload. Если MapReload установить в true, то сервер будет перезагржен после копирования плагина на сервер. 

3.Add show plugin info after restart plugin in server.

*0.3 1st Realese

##Plans
->TEST->|Show errors and warn too.
-->not work->If not exits plugins, then make it folder
[ ]-->need test  Наладить распознование абсолютных и относительных путей 
--> Отображать как абсольные так и относительные пути
-->Получать лог с сервера для слежения за плагинами 
-->Добавить консоль сервера
--> При отсутствии действий в окне - закрыть через таймаут
https://help.github.com/articles/basic-writing-and-formatting-syntax/