Este espacio comparte lo que creemos nos va ayudar en la automatizacion basica para un windows server o windows 11, de momento estamos haciendo las pruebas necesarias en maquinas virtuales, desplegadas en kvm en linux que se ha convertido en nuestro ambiente de pruebas para las pruebas de estas maquinas virtuales.

Ahora pongamos en la mesa los requisitos previos para el funcionamiento de este script.

## Instalacion de windows server 2025

Esta parte no es tan dificil asi que intentaremos documentarlo


## Instalar OpenSSH-server para windows

Una vez ya hayas encendido el server lo primero es irse al terminal de windows y ejecuta el siguiente comando 

```
winget upgrade --all
```

Luego vamos a tratar de ejecutar un script de powershell que nos automatice una instalacion basica, la mas basica de herramientas , luego haremos mas scripts para correr esto.
