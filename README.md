———————————————

Hello there.

As part of the ongoing work on the ElitistGroup addon, the ZOMGBuffs addon (hereinafter ZOMG) has been updated.

This update addresses the communication module with the PallyPower addon (hereinafter PP). While the addon's original author had partially implemented this functionality, it stopped working at some point. As a result, recent versions of ZOMG were unable to connect with PP and couldn't synchronize blessings, auras, talent information, or reagent counts.

Here's a breakdown of what done:
1) fully restored the communication bridge between ZOMG and PP. This includes the ability to:

    sharing information about class assignments;
    sharing information about single buff assignments for specific players;
    sharing information about auras;
    sharing information about reagent counts;
    sharing information about learned blessing and aura ranks;
    sharing information about talents that improve blessings and auras;
    manual changes to all assignments in both directions between ZOMG and PP;
    synchronize all assignments and information; 


2) implemented a function that allows you to clear paladin assignments in ZOMG using the "Clear" button in PP;
3) added a "Free Assignment" option and functionality in ZOMG, similar to the one in PP (this is disabled by default).

This update is based on the last ZOMG version for 3.3.5a, which is r156. Tested the communication with PP versions 3.2.20 (the last for 3.3.5a) and 3.2.10, and no issues have been found so far.

If you happen to find any bugs, please let us know.

———————————————

¡Hola!

Como parte de los preparativos para la actualización del complemento ElitistGroup, hemos modernizado el complemento ZOMGBuffs (en adelante, ZOMG).

La modernización se centró en el módulo de comunicación con el complemento PallyPower (en adelante, PP). Este módulo fue implementado parcialmente por el autor del complemento original, pero dejó de funcionar en algún momento. Como resultado, las últimas versiones de ZOMG no se podían conectar con PP y no podían sincronizar bendiciones, auras, información de talentos o el recuento de componentes.

Esto es lo que hemos hecho:
1) restauramos completamente el puente de comunicación entre ZOMG y PP. Esto incluye la transferencia de:

    información sobre las asignaciones de clase;
    información sobre asignaciones de mejoras individuales a jugadores específicos;
    información sobre auras;
    información sobre el recuento de componentes;
    información sobre las filas de bendiciones y auras aprendidas;
    información sobre los talentos que mejoran las bendiciones y auras;
    capacidad de cambiar manualmente todas las asignaciones en ambas direcciones;
    sincronización de todas las asignaciones e información; 


2) hemos implementado una función que te permite limpiar las asignaciones de paladín en ZOMG usando el botón "Borrar" en PP;
3) hemos añadido una opción y funcionalidad de "Asignación libre" en ZOMG, similar a la que tiene PP (esta opción está desactivada por defecto).

Esta actualización se basa en la última versión de ZOMG para 3.3.5a, r156. La comunicación con PP se probó con las versiones 3.2.20 (la última para 3.3.5a) y 3.2.10 y, hasta ahora, no se han encontrado problemas.

Por favor, avísanos si encuentras algún error.

———————————————

Доброго времени суток.

В рамках подготовки к доработке аддона ElitistGroup, был модернизирован аддон ZOMGBuffs (далее ZOMG).

Модернизация затронула модуль коммуникации с аддоном PallyPower (далее PP), который был частично реализован автором аддона, но с определённого момента перестал работать и последние версии ZOMG не связывались с PP и не синхронизировали благословения, ауры, информацию о талантах, количестве реагентов.

Что именно сделано:
1) восстановлен мост между ZOMG ↔ PP в полном объёме:

    передача информации о классовых назначениях;
    передача информации о назначениях одиночных баффов на конкретных игроков;
    передача информации об аурах;
    передача информации о количестве реагентов;
    передача информации об изученных рангах благословений и аур;
    передача информации о талантах усиливающих благословения и ауры;
    ручное изменение в обе стороны всех назначений;
    синхронизация всех назначений и информации; 


2) реализована очистка назначений паладина в ZOMG командой-кнопкой "Очистить" в PP;
3) реализована опция и функционал "Свободное назначение" в ZOMG, аналогично опции в PP (по умолчанию отключена).

За основу ZOMG была взята последняя версия для 3.3.5a, а именно r156. Тестирование коммуникации с PP проводилось с версиями 3.2.20 (последняя для 3.3.5a) и 3.2.10 — проблем пока не обнаружено.

Прошу сообщать о любых багах, если такие будут найдены.
