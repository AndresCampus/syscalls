# Syscalls en Linux - Diferentes Métodos para Llamar al Sistema

Este repositorio contiene ejemplos de cómo realizar llamadas al sistema en Linux utilizando diferentes métodos en distintas arquitecturas. Permite comparar el uso de `printf()`, `write()`, `syscall()`, `int 0x80`, `syscall` y `svc` en ARM.

## Contenido

- **`poker_llamadas.c`**: Programa en C que muestra cuatro formas de invocar llamadas al sistema para escribir en la salida estándar.

  - `printf()` de la biblioteca estándar de C.
  - `write()` de `unistd.h`.
  - `syscall(SYS_write, ...)`.
  - Llamadas directas en ensamblador:
    - `int 0x80` en **x86 (32 bits)**.
    - `syscall` en **x86_64 (64 bits)**.
    - `svc 0` en **ARM**.

- **`E_S_fichero.c`**: Programa en C que demuestra las diferencias en el **buffering** entre llamadas al sistema (`read()`, `write()`) y llamadas a funciones de la biblioteca estándar (`fwrite()`, `fread()`).

  - Escribe datos en un archivo usando `fwrite()`.
  - Lee datos usando `fread()` y luego usa `read()` de `unistd.h`.
  - Permite analizar cómo el buffering en espacio del usuarioafecta el número de llamadas al sistema usando `strace`.

## Compilación y Ejecución

### **Compilar en x86 de 32 bits** (para `int 0x80` y `sysenter`)
Si estás en un sistema x86_64, debes compilar en modo 32 bits:

```sh
gcc -m32 poker_llamadas.c -o poker_llamadas_x86
./poker_llamadas_x86
```

Si el sistema no tiene soporte para binarios de 32 bits, instala las bibliotecas necesarias (ubuntu/debian):

```sh
sudo apt update
sudo apt install gcc-multilib libc6-dev-i386
gcc -m32 poker_llamadas.c -o poker_llamadas_x86
./poker_llamadas_x86
```

### **Compilar en x86_64** (para `syscall` en 64 bits)

```sh
gcc poker_llamadas.c -o poker_llamadas_x86_64
./poker_llamadas_x86_64
```

Comprueba la salida del programa, deberían verse 4 mensajes que usan la escritura en fichero (salida estándar), pero con diferentes métodos:
  - `printf()` de la biblioteca estándar de C.
  - `write()` de `unistd.h`, un envoltorio de la librería de C para la llamada al sistema write().
  - `syscall(SYS_write, ...)`. La forma genérica de invocar a cualquier llamada al sistema.
  - Por último llamadas directas en ensamblador, con la versión adecuada para la arquitectura en uso:
    - `int 0x80` en **x86 (32 bits)**.
    - `syscall` en **x86_64 (64 bits)**.
    - `svc 0` en **ARM**.

### **Compilar y ejecutar `E_S_fichero.c`**

```sh
gcc E_S_fichero.c -o E_S_fichero
```

## Ejecución y análisis con `strace`

Para ver las llamadas al sistema en tiempo real, puedes ejecutar el programa con `strace`, analiza las diferencias en el uso del buffering con `E_S_fichero.c`:

```sh
strace ./E_S_fichero
```

Esto mostrará cada syscall ejecutada y permitirá comparar las diferencias entre los métodos. Las llamadas al sistema que nos interesan están en la última docena de líneas, después de la última llamada a brk(). Ahí es donde empieza la ejecución de mai(). Antes de eso hay llamadas al sistema previas que preparan y configuran la ejecución del programa añadiendo las librerías dinámicas necesarias.

## Explicación de los Métodos

### **1. `printf()` (Librería estándar de C)**

Utiliza buffering y optimizaciones internas de la glibc antes de llamar a `write()`.

### **2. `write()` (Envoltorio de `unistd.h`)**

Llama directamente a la syscall `write()` mediante la función de la glibc.

### **3. `syscall(SYS_write, ...)` (Llamada manual a `write`)**

Usa `syscall()` para hacer una llamada explícita sin depender de la glibc.

### **4. Ensamblador (Llamadas manuales al kernel)**

- **x86_64**: Usa `syscall`, el método más eficiente en sistemas modernos de 64 bits.
- **x86 (32 bits)**: Usa `int 0x80`, el método clásico para syscalls en Linux de 32 bits.
- **ARM**: Usa `svc 0`, la instrucción equivalente para syscalls en arquitecturas ARM.

### **5. Buffering en `E_S_fichero.c`**

- `fwrite()` usa buffering interno y puede retrasar la escritura hasta que el buffer esté lleno.
- `read()` y `write()` de `unistd.h` son llamadas directas sin buffering adicional.
- Usar `setvbuf()` permite modificar el comportamiento del buffer en `fwrite()`.
- `strace` permite ver la diferencia en la cantidad de syscalls generadas.

## Licencia

Este código es de uso educativo y libre bajo la licencia MIT.

