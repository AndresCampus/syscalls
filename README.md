# Llamadas al Sistema en Linux

Este repositorio contiene ejemplos de cómo realizar llamadas al sistema en Linux utilizando diferentes métodos en distintas arquitecturas. Permite comparar el uso desde C de `printf()`, `write()`, `syscall()` y ensamblador en C con las instrucciones `int 0x80`, `syscall` para x86 y `svc` para ARM.

## Contenido

- **`poker_llamadas.c`**: Programa en C que muestra cuatro formas de invocar llamadas al sistema para escribir en la salida estándar.

  - `printf()` de la biblioteca estándar de C.
  - `write()` de `unistd.h`, el envoltorio de la syscall desde C.
  - `syscall(SYS_write, ...)` es la forma genérica de llamar a una syscall desde C, hay que añadir el número de syscall que queremnos usar.
  - Llamadas directas en ensamblador:
    - `int 0x80` en **x86 (32 bits)**.
    - `syscall` en **x86_64 (64 bits)**.
    - `svc 0` en **ARM**.

- **`E_S_fichero.c`**: Programa en C que demuestra las diferencias en el **buffering** entre llamadas al sistema (`read()`, `write()`) y llamadas a funciones de la biblioteca estándar de C (`fwrite()`, `fread()`).

  - Escribe datos en un archivo usando `fwrite()`.
  - Lee datos usando `fread()` y luego usa `read()` de `unistd.h`.
  - Permite analizar cómo el buffering en espacio del usuario afecta el número de llamadas al sistema usando `strace`.

## Compilación

### **Compilar con make**
Es posible compilar los dos fuentes usando la herramienta make y el fichero Makefile proporcionado.
El fichero Makefile establece reglas para generar los ejecutables que tienen en cuenta las dependencias necesarias.

```sh
make
```
Si lo prefieres puedes compilar cada programa manualmente con gcc, ver sección al final del documento.

## Ejecución y análisis de poker_llamadas y poker_llamadas_32

Comprueba la salida de ambos programas (si no tienes x86_64 puede que sólo tengas un ejecutable), deberían verse 4 mensajes que usan la escritura en fichero (salida estándar), pero con diferentes métodos:
  - `printf()` de la biblioteca estándar de C.
  - `write()` de `unistd.h`, un envoltorio de la librería de C para la llamada al sistema write().
  - `syscall(SYS_write, ...)`. La forma genérica de invocar a cualquier llamada al sistema, se puese usar cuando no hay un envoltorio C para la llamada concreta al sistema.
  - Por último llamadas directas en ensamblador, con la versión adecuada para la arquitectura en uso:
    - `int 0x80` en **x86 (32 bits)**.
    - `syscall` en **x86_64 (64 bits)**.
    - `svc 0` en **ARM** , probado en Rpi 2.
    - con otra arquitectura (apple silicon) no hay implementación preparada

Comprueba si se ejectutan correctamente las cuatro opciones, revisa el código fuente para comprobar que llamadas se realizaron en casa caso.
Ejecuta los programas ahora con `strace` para comprobar si se llama a la llamada al sistema `write()` con las cuatro opciones (revisa la sección sobre strace al final del documento). Para ver mejor la salida de strace se puede ejecutar enviando la salida estándar a un fichero y así que no se mezclen en la consola:
```sh
strace ./poker_llamadas
strace ./poker_llamadas 1> salida.txt
```
¿Por qué podría haber alguna diferencia entre la salida que da ./poker_llamadas por consola y la que se obtiene si se redirige esta salida a un fichero?

### Funciones utilizadas

#### **1. `printf()` (Librería estándar de C)**

Utiliza buffering y optimizaciones internas de la glibc antes de llamar a `write()`. Escribe en el fichero 1 (stdout) que se corresponde con la salida estándar, conectado con la consola por defecto.

#### **2. `write()` (Envoltorio de `unistd.h`)**

Llama directamente a la syscall `write()` mediante la función envoltorio de la glibc.

#### **3. `syscall(SYS_write, ...)` (Llamada manual a `write`)**

Usa `syscall()` para hacer una llamada explícita sin depender de la glibc.

#### **4. Ensamblador (Llamadas manuales al kernel)**

- **x86_64**: Usa `syscall`, el método más eficiente en sistemas modernos de 64 bits.
- **x86 (32 bits)**: Usa `int 0x80`, el método clásico para syscalls en Linux de 32 bits.
- **ARM**: Usa `svc 0`, supervisor call: una interrupción, la instrucción equivalente para syscalls en arquitecturas ARM.

## Ejecución y análisis de `E_S_fichero`

Para ver las llamadas al sistema en tiempo real, puedes ejecutar el programa con `strace`, esto nos permite analizar las diferencias en el uso del buffering con `E_S_fichero.c`:

```sh
strace ./E_S_fichero
```

Esto mostrará cada llamada al sistema ejecutada y permitirá comparar las diferencias entre:
- usar las funciones de librería de C en espacio de usuario que incorpora optimizaciones que permiten reducir el número de llamadas al sistema.
- usar directamente llamadas al sistema sin ninguna librería de alto nivel.

### Buffering en `E_S_fichero.c`

- `fwrite()` usa buffering interno en espacio de usuario y puede retrasar la escritura (llamada a la system call) hasta que el buffer esté lleno.
- `read()` y `write()` de `unistd.h` son llamadas directas al kernel sin buffering adicional en espacio de usuario.
- Usar `setvbuf()` permite modificar el comportamiento del buffer en `fwrite()` y `fread()`.
- `strace` permite ver la diferencia en la cantidad de syscalls generadas y los tamaños de buffer de memoria que se están usando.

## Interpretar salida de `strace`
strace es una herramienta que nos permite visualizar las llamadas al sistema que se realizan al ejecutar un programa. Las llamadas al sistema que nos interesan están en las últimas líneas de salida, después de la última llamada a brk(). Ahí es donde empieza la ejecución de main(). Antes de eso hay llamadas al sistema previas que preparan y configuran la ejecución del programa, por ejemplo, añadiendo las librerías dinámicas necesarias. Un par de ejemplos:

- `write(1, "Salida write con syscall desde a"..., 35) = 35` indica que se ha llamado a la syscall write, para escribir en el fichero 1 (salida estándar) 35 bytes del buffer indicando. La respuesta de la llamada es 35, que indica que se pudieron escribir efectivamente 35 bytes. Se puede consultar el uso de write con `man 2 write`.
- `read(3, "Hola ", 1024) = 5` indica que se ha llamado a la syscall read, para leer el fichero 3 que debe haberse abierto previamente con open(). En este ejemplo se ha intentado leer 1024 bytes, pero sólo se leyeron 5. Eso puede ser debido a que se encontró el final de fichero (EOF) y ya no se pueden leer más datos. Se puede consultar el uso de read con `man 2 read`.
  
## Compilación manual
### **Compilar `E_S_fichero.c`**

```sh
gcc E_S_fichero.c -o E_S_fichero
```

### **Compilar en x86_64** (para probar el método `syscall` para llamar al sistema en 64 bits)

```sh
gcc poker_llamadas.c -o poker_llamadas
```

### **Compilar en x86 de 32 bits** (para probar `int 0x80` o `sysenter` como método de hacer una syscall)
Si estás en un sistema x86_64, debes compilar en modo 32 bits:

```sh
gcc -m32 poker_llamadas.c -o poker_llamadas_32
```

Si el sistema no tiene soporte para binarios de 32 bits, instala las bibliotecas necesarias (ubuntu/debian):

```sh
sudo apt update
sudo apt install gcc-multilib libc6-dev-i386
gcc -m32 poker_llamadas.c -o poker_llamadas_32
```
## Licencia

Este código es de uso educativo y libre bajo la licencia MIT.

