/* diferencias en el buffering entre las llamadas al sistema y las llamdas a funciones de librería
   usar strace para comprobar las llamadas que se hacen realmente  */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <fcntl.h>

int main()
{

FILE * f;
int i, fd;
char *datos;

datos=strdup("Hola ");
/* abrimos el fichero */
f=fopen("prueba.out","w+");

/* Para modificar el tamaño del buffer del fichero 
i= setvbuf(f,malloc(10000),_IOFBF,10000);
if(i) perror("SETVBUF:");
*/

/*escribimos en este fichero 1000 veces 5 chars, en total 5000 bytes */
for(i=0; i<1000; i++)
  fwrite(datos, sizeof(char), 5, f);

/*vamos al principio, rebobinamos*/
fseek(f,0,0);

/*leemos de este fichero 3 veces 5 chars, en total 15 bytes */
fread(datos,sizeof(char),5,f);
fread(datos,sizeof(char),5,f);
fread(datos,sizeof(char),5,f);

fclose(f);

/*
 * leemos otra vez pero con la llamada al sistema en vez de usar la libreria de c */
fd=open("prueba.out",O_RDONLY);

read(fd, datos, 5);
read(fd, datos, 5);
read(fd, datos, 5);

close(fd);

free(datos);
exit(0);

}
